import 'package:flutter/material.dart';
import 'package:greennest/services/api_service.dart';
import 'package:greennest/models/plant_card.dart';
import 'package:greennest/models/health_log.dart';
import 'package:greennest/widgets/custom_button.dart';
import 'package:greennest/screens/diagnosis_screen.dart';

class PlantCardDetailScreen extends StatefulWidget {
  final PlantCard plantCard;
  const PlantCardDetailScreen({Key? key, required this.plantCard}) : super(key: key);

  @override
  State<PlantCardDetailScreen> createState() => _PlantCardDetailScreenState();
}

class _PlantCardDetailScreenState extends State<PlantCardDetailScreen> {
  final ApiService _apiService = ApiService();
  late PlantCard _card;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _card = widget.plantCard;
  }

  Future<void> _refreshCard() async {
    try {
      final card = await _apiService.fetchPlantCardDetails(_card.plantCardId);
      setState(() {
        _card = card;
      });
    } catch (e) {
      // Slient fail
    }
  }

  Future<void> _logAction(String type, String message) async {
    setState(() => _isLoading = true);
    try {
      await _apiService.addHealthLog(_card.plantCardId, {
        'entry_type': type,
        'diagnosis': message,
      });
      await _refreshCard();
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully logged $type!')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log action: $e')),
      );
    }
  }

  Future<void> _deleteCard() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Plant'),
        content: Text('Are you sure you want to remove ${_card.nickname} from your garden?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.deletePlantCard(_card.plantCardId);
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF0F5132);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2D3748)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: _deleteCard,
          )
        ],
      ),
      extendBodyBehindAppBar: true,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner Photo
                  Stack(
                    children: [
                      Image.network(
                        _card.photoUrl ?? 'https://images.unsplash.com/photo-1596547609652-9cf5d8d76921',
                        height: 320,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        height: 320,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.3),
                              Colors.transparent,
                              Colors.white,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _card.nickname,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                        ),
                        Text(
                          _card.species,
                          style: TextStyle(fontSize: 14, color: Colors.grey[600], fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 20),

                        // Care Reminders Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInfoTile(Icons.water_drop, 'Watering Due', _card.waterFrequency ?? 'Every 7 days', Colors.blue),
                            _buildInfoTile(Icons.vaccines, 'Fertilizing', _card.fertilizeFrequency ?? 'Monthly', Colors.purple),
                            _buildInfoTile(Icons.location_on, 'Location', _card.location ?? 'Living Room', Colors.orange),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Action logger buttons
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                text: 'Log Water',
                                icon: Icons.water_drop_outlined,
                                onTap: () => _logAction('Watering', 'Watered plant'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: CustomButton(
                                text: 'Log Feed',
                                icon: Icons.vaccines_outlined,
                                isPrimary: false,
                                onTap: () => _logAction('Fertilizing', 'Fertilized plant with liquid fertilizer'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            text: 'Diagnose Plant Health',
                            icon: Icons.camera_alt_outlined,
                            isPrimary: false,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const DiagnosisScreen()),
                              );
                              _refreshCard();
                            },
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Health logs timeline
                        const Text(
                          'Care & Health Logs Timeline',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                        ),
                        const SizedBox(height: 16),
                        _card.healthLogs.isEmpty
                            ? const Text('No history logged yet.')
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _card.healthLogs.length,
                                itemBuilder: (context, index) {
                                  // Reverse logs to show newest first
                                  final log = _card.healthLogs[_card.healthLogs.length - 1 - index];
                                  return _buildTimelineItem(log, primaryColor);
                                },
                              ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String val, Color col) {
    return Container(
      width: 105,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: col, size: 22),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(HealthLog log, Color primaryColor) {
    IconData icon;
    Color iconColor;

    switch (log.entryType) {
      case 'Watering':
        icon = Icons.water_drop;
        iconColor = Colors.blue;
        break;
      case 'Fertilizing':
        icon = Icons.vaccines;
        iconColor = Colors.purple;
        break;
      case 'Diagnosis':
        icon = Icons.medical_services;
        iconColor = Colors.red;
        break;
      default:
        icon = Icons.spa;
        iconColor = primaryColor;
    }

    final dateStr = "${log.createdAt.day}/${log.createdAt.month}/${log.createdAt.year}";

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.entryType,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  log.diagnosis ?? '',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                if (log.confidence != null && log.confidence! < 100)
                  Text('Confidence: ${log.confidence!.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11, color: Colors.red)),
              ],
            ),
          ),
          Text(
            dateStr,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
