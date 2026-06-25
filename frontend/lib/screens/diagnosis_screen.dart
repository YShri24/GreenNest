import 'package:flutter/material.dart';
import 'package:greennest/services/api_service.dart';
import 'package:greennest/models/plant_card.dart';
import 'package:greennest/widgets/custom_button.dart';
import 'package:greennest/screens/plant_cards_screen.dart';
import 'package:image_picker/image_picker.dart';

class DiagnosisScreen extends StatefulWidget {
  const DiagnosisScreen({Key? key}) : super(key: key);

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  final ApiService _apiService = ApiService();
  int _currentStep = 0; // 0: Select Saved or Unsaved, 1: Select PlantCard (Saved Flow), 2: Optional Context (New Flow), 3: Choose Symptoms & Photo, 4: Results
  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  String? _uploadedPhotoUrl;

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() => _isUploadingPhoto = true);
        final bytes = await image.readAsBytes();
        final url = await _apiService.uploadImage(bytes, image.name);
        setState(() {
          _uploadedPhotoUrl = url;
          _photoAttached = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo uploaded successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload photo: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  // Options variables
  bool _isSavedPlant = false;
  List<PlantCard> _userCards = [];
  PlantCard? _selectedCard;

  // Context variables for Unsaved Plant
  String? _location;
  String? _light;
  String? _waterFrequency;

  // Symptoms Selection variables
  final List<String> _symptomsList = [
    'yellow leaves', 'soft stem', 'mushy soil', 'dry crispy leaves', 
    'drooping', 'leggy growth', 'pale new leaves', 'spots on leaves'
  ];
  final List<String> _selectedSymptoms = [];
  bool _photoAttached = false;

  // Results variables
  Map<String, dynamic>? _diagnosisResult;

  @override
  void initState() {
    super.initState();
    _loadUserPlantCards();
  }

  Future<void> _loadUserPlantCards() async {
    try {
      final cards = await _apiService.fetchUserPlantCards(1);
      setState(() {
        _userCards = cards;
      });
    } catch (e) {
      // Slient fail or mock
    }
  }

  Future<void> _runDiagnosis() async {
    if (_selectedSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one plant symptom.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _apiService.diagnosePlant(
        symptoms: _selectedSymptoms,
        location: _isSavedPlant ? null : _location,
        light: _isSavedPlant ? null : _light,
        waterFrequency: _isSavedPlant ? null : _waterFrequency,
        plantCardId: _isSavedPlant ? _selectedCard?.plantCardId : null,
      );

      setState(() {
        _diagnosisResult = result;
        _isLoading = false;
        _currentStep = 4; // Display results
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete diagnosis: $e')),
      );
    }
  }

  void _reset() {
    setState(() {
      _currentStep = 0;
      _isSavedPlant = false;
      _selectedCard = null;
      _location = null;
      _light = null;
      _waterFrequency = null;
      _selectedSymptoms.clear();
      _photoAttached = false;
      _diagnosisResult = null;
    });
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
          'Plant Health Assistant',
          style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(child: _buildDiagnosticContent(primaryColor)),
            ),
    );
  }

  Widget _buildDiagnosticContent(Color primaryColor) {
    // --- Step 0: Choose Flow ---
    if (_currentStep == 0) {
      return Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.monitor_heart, color: primaryColor, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Is this plant already saved in your GreenNest PlantCard list?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Yes, select from my plants',
                  onTap: () {
                    if (_userCards.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('You have no saved plants. Let\'s treat this as a new plant instead.')),
                      );
                      setState(() {
                        _isSavedPlant = false;
                        _currentStep = 2; // skip to unsaved context
                      });
                    } else {
                      setState(() {
                        _isSavedPlant = true;
                        _currentStep = 1;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'No, this is a new/unsaved plant',
                  isPrimary: false,
                  onTap: () {
                    setState(() {
                      _isSavedPlant = false;
                      _currentStep = 2;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    // --- Step 1: Select PlantCard (Saved Flow) ---
    if (_currentStep == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select the plant you want to diagnose:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _userCards.length,
            itemBuilder: (context, index) {
              final card = _userCards[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      card.photoUrl ?? 'https://images.unsplash.com/photo-1596547609652-9cf5d8d76921',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(card.nickname, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(card.species),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    setState(() {
                      _selectedCard = card;
                      _currentStep = 3; // jump to symptoms & photo
                    });
                  },
                ),
              );
            },
          ),
        ],
      );
    }

    // --- Step 2: Unsaved Plant Context (Optional) ---
    if (_currentStep == 2) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Help us understand where you keep this plant (Optional context)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Where is it kept?'),
              items: ['Bedroom', 'Living Room', 'Balcony', 'Office Desk', 'Kitchen', 'Terrace']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => _location = val,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'How much light does it get?'),
              items: ['Low', 'Medium', 'Bright Indirect', 'Direct Sunlight']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => _light = val,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'How often do you water it?'),
              items: ['Daily', 'Every few days', 'Weekly', 'Rarely', 'Not sure']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => _waterFrequency = val,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Next: Select Symptoms',
                onTap: () => setState(() => _currentStep = 3),
              ),
            ),
          ],
        ),
      );
    }

    // --- Step 3: Choose Symptoms & Photo ---
    if (_currentStep == 3) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select visible symptoms:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _symptomsList.map((sym) {
                final isSelected = _selectedSymptoms.contains(sym);
                return FilterChip(
                  label: Text(sym),
                  selected: isSelected,
                  selectedColor: primaryColor.withOpacity(0.2),
                  checkmarkColor: primaryColor,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedSymptoms.add(sym);
                      } else {
                        _selectedSymptoms.remove(sym);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              'Upload photo of symptoms:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: _isUploadingPhoto
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F5132))),
                          SizedBox(height: 12),
                          Text('Uploading photo to GreenNest...', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      )
                    : _photoAttached && _uploadedPhotoUrl != null
                        ? Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    _uploadedPhotoUrl!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Container(
                                color: Colors.black.withOpacity(0.3),
                                child: const Icon(Icons.check_circle, color: Colors.white, size: 40),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _photoAttached = false;
                                      _uploadedPhotoUrl = null;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add_a_photo, color: Colors.grey, size: 36),
                              SizedBox(height: 8),
                              Text('Tap to select plant image from your device', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Analyze Health Now',
                onTap: _runDiagnosis,
              ),
            ),
          ],
        ),
      );
    }

    // --- Step 4: Results Display ---
    final primaryDiag = _diagnosisResult?['primary'];
    final List<dynamic> alternates = _diagnosisResult?['alternates'] ?? [];
    final double confidence = primaryDiag?['confidence'] ?? 60.0;
    final List<dynamic> steps = primaryDiag?['steps'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Diagnosis Results',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    primaryDiag?['cause'] ?? 'General Stress',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: primaryColor),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${confidence.toStringAsFixed(0)}% Confidence',
                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Recommended Treatment Steps:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3748)),
              ),
              const SizedBox(height: 8),
              ...steps.map((step) => Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.arrow_right, color: Colors.green, size: 20),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            step.toString(),
                            style: const TextStyle(color: Color(0xFF4A5568), fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (alternates.isNotEmpty) ...[
          const Text(
            'Could it be something else?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
          ),
          const SizedBox(height: 8),
          ...alternates.map((alt) => Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(alt['cause'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Text('${(alt['confidence'] as num).toStringAsFixed(0)}%'),
                ),
              )),
          const SizedBox(height: 20),
        ],
        
        // Post-Diagnosis actions
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            text: 'Save to PlantCard',
            onTap: () async {
              if (_isSavedPlant && _selectedCard != null) {
                // Add log to existing card
                try {
                  await _apiService.addHealthLog(_selectedCard!.plantCardId, {
                    'entry_type': 'Diagnosis',
                    'diagnosis': primaryDiag?['cause'] ?? 'General Stress',
                    'confidence': confidence,
                    'photo_url': _uploadedPhotoUrl,
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Diagnosis successfully logged to PlantCard timeline!')),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to save log: $e')),
                    );
                  }
                }
              } else {
                // Prompt to create a new PlantCard
                _showCreateCardDialog(context, primaryDiag?['cause'] ?? 'General Stress', _uploadedPhotoUrl);
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Resolve',
                isPrimary: false,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Marked as resolved!')),
                  );
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: 'Retake',
                isPrimary: false,
                onTap: _reset,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showCreateCardDialog(BuildContext context, String currentDiagnosis, String? photoUrl) {
    final nicknameController = TextEditingController();
    final speciesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Save as new PlantCard'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nicknameController,
                decoration: const InputDecoration(labelText: 'Nickname (e.g. My Monstera)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: speciesController,
                decoration: const InputDecoration(labelText: 'Species (e.g. Monstera deliciosa)'),
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
                  final card = await _apiService.createPlantCard(1, {
                    'nickname': nicknameController.text,
                    'species': speciesController.text,
                    'location': _location,
                    'light_exposure': _light,
                    'water_frequency': _waterFrequency ?? 'Weekly',
                    'fertilize_frequency': 'Monthly',
                    'photo_url': photoUrl,
                  });
                  
                  // Log current diagnosis to it
                  await _apiService.addHealthLog(card.plantCardId, {
                    'entry_type': 'Diagnosis',
                    'diagnosis': currentDiagnosis,
                    'confidence': 70.0,
                    'photo_url': photoUrl,
                  });

                  if (context.mounted) {
                    Navigator.pop(context); // close dialog
                    this._reset();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PlantCardsScreen()),
                    );
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Successfully created PlantCard and saved diagnosis!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to save PlantCard: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            )
          ],
        );
      },
    );
  }
}
