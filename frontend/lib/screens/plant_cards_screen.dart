import 'package:flutter/material.dart';
import 'package:greennest/services/api_service.dart';
import 'package:greennest/models/plant_card.dart';
import 'package:greennest/screens/plant_card_detail_screen.dart';
import 'package:greennest/widgets/custom_button.dart';

class PlantCardsScreen extends StatefulWidget {
  const PlantCardsScreen({Key? key}) : super(key: key);

  @override
  State<PlantCardsScreen> createState() => _PlantCardsScreenState();
}

class _PlantCardsScreenState extends State<PlantCardsScreen> {
  final ApiService _apiService = ApiService();
  List<PlantCard> _cards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlantCards();
  }

  Future<void> _loadPlantCards() async {
    setState(() => _isLoading = true);
    try {
      final cards = await _apiService.fetchUserPlantCards(1);
      setState(() {
        _cards = cards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load your garden: $e')),
      );
    }
  }

  void _showAddCardDialog() {
    final nicknameController = TextEditingController();
    final speciesController = TextEditingController();
    String? location = 'Living Room';
    String? light = 'Medium';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Plant to Garden'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nicknameController,
                decoration: const InputDecoration(labelText: 'Nickname (e.g. Sunny)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: speciesController,
                decoration: const InputDecoration(labelText: 'Species (e.g. Snake Plant)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (nicknameController.text.isEmpty || speciesController.text.isEmpty) return;
                try {
                  await _apiService.createPlantCard(1, {
                    'nickname': nicknameController.text,
                    'species': speciesController.text,
                    'location': location,
                    'light_exposure': light,
                    'water_frequency': 'Every 7 days',
                    'fertilize_frequency': 'Monthly',
                  });
                  Navigator.pop(context);
                  _loadPlantCards();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add plant: $e')),
                  );
                }
              },
              child: const Text('Add'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF0F5132);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF2D3748)),
        title: const Text(
          'My Digital Garden',
          style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF0F5132)),
            onPressed: _showAddCardDialog,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cards.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.eco_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text(
                          'Your garden is empty',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A5568)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add your physical house plants to keep track of watering, fertilizing, and health logs!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 24),
                        CustomButton(
                          text: 'Add First Plant',
                          onTap: _showAddCardDialog,
                        )
                      ],
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.78,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    final card = _cards[index];
                    return GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlantCardDetailScreen(plantCard: card),
                          ),
                        );
                        _loadPlantCards(); // Refresh on pop back
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                                child: Image.network(
                                  card.photoUrl ?? 'https://images.unsplash.com/photo-1596547609652-9cf5d8d76921',
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    card.nickname,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF2D3748),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    card.species,
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.water_drop, color: Colors.blue, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        card.waterFrequency ?? 'Weekly',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
