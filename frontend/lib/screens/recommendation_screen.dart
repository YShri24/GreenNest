import 'package:flutter/material.dart';
import 'package:greennest/services/api_service.dart';
import 'package:greennest/models/plant.dart';
import 'package:greennest/screens/details_screen.dart';
import 'package:greennest/widgets/custom_button.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({Key? key}) : super(key: key);

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  final ApiService _apiService = ApiService();
  int _currentStep = 0;
  bool _isLoading = false;

  // Answers Map
  String? _flowType; // "Personal" or "Gift"
  String? _purpose;
  String? _location;
  String? _light;
  String? _season;
  String? _maintenance;
  String? _giftFor;
  String? _occasion;

  List<Map<String, dynamic>> _recommendations = [];

  // Options
  final List<String> _purposes = ['Air Purification', 'Decoration', 'Good Luck', 'Stress Relief', 'Medicinal Use', 'Balcony Beautification'];
  final List<String> _locations = ['Bedroom', 'Living Room', 'Balcony', 'Office Desk', 'Garden', 'Kitchen', 'Terrace'];
  final List<String> _lights = ['Low', 'Medium', 'Bright Indirect', 'Direct Sunlight'];
  final List<String> _seasons = ['Summer', 'Monsoon', 'Winter', 'All Season'];
  final List<String> _maintenances = ['Low', 'Medium', 'High'];
  
  final List<String> _giftRelations = ['Friend', 'Mother', 'Father', 'Sister', 'Brother', 'Spouse', 'Colleague', 'Teacher', 'Other'];
  final List<String> _occasions = ['Birthday', 'Anniversary', 'Housewarming', 'Wedding', 'Graduation', 'Festival', 'Thank You', 'Get Well Soon', 'Just Because'];

  Future<void> _fetchRecommendations() async {
    setState(() {
      _isLoading = true;
      _currentStep = 99; // Results step
    });

    try {
      final query = {
        'flow_type': _flowType ?? 'Personal',
        'purpose': _purpose,
        'location': _location,
        'light': _light,
        'season': _season,
        'maintenance': _maintenance,
        'gift_for': _giftFor,
        'occasion': _occasion,
      };

      final results = await _apiService.getRecommendations(query);
      setState(() {
        _recommendations = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _currentStep = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch recommendations: $e')),
      );
    }
  }

  void _reset() {
    setState(() {
      _currentStep = 0;
      _flowType = null;
      _purpose = null;
      _location = null;
      _light = null;
      _season = null;
      _maintenance = null;
      _giftFor = null;
      _occasion = null;
      _recommendations = [];
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
          'Plant Matcher Assistant',
          style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: _buildStepContent(primaryColor),
            ),
    );
  }

  Widget _buildStepContent(Color primaryColor) {
    if (_currentStep == 0) {
      // Step 1: Flow Type
      return _buildQuestionCard(
        title: 'Who is this plant for?',
        options: ['Buy for Myself', 'Gift to Someone'],
        onSelect: (val) {
          setState(() {
            _flowType = (val == 'Buy for Myself') ? 'Personal' : 'Gift';
            _currentStep = 1;
          });
        },
      );
    }

    // --- Personal Flow Steps ---
    if (_flowType == 'Personal') {
      if (_currentStep == 1) {
        return _buildQuestionCard(
          title: 'Why do you want a plant? (Purpose)',
          options: _purposes,
          onSelect: (val) => setState(() { _purpose = val; _currentStep = 2; }),
        );
      }
      if (_currentStep == 2) {
        return _buildQuestionCard(
          title: 'Where will you place it?',
          options: _locations,
          onSelect: (val) => setState(() { _location = val; _currentStep = 3; }),
        );
      }
      if (_currentStep == 3) {
        return _buildQuestionCard(
          title: 'How much light is available?',
          options: _lights,
          onSelect: (val) => setState(() { _light = val; _currentStep = 4; }),
        );
      }
      if (_currentStep == 4) {
        return _buildQuestionCard(
          title: 'Current Season?',
          options: _seasons,
          onSelect: (val) => setState(() { _season = val; _currentStep = 5; }),
        );
      }
      if (_currentStep == 5) {
        return _buildQuestionCard(
          title: 'How much care can you provide?',
          options: _maintenances,
          onSelect: (val) {
            _maintenance = val;
            _fetchRecommendations();
          },
        );
      }
    }

    // --- Gift Flow Steps ---
    if (_flowType == 'Gift') {
      if (_currentStep == 1) {
        return _buildQuestionCard(
          title: 'Whom do you want to gift?',
          options: _giftRelations,
          onSelect: (val) => setState(() { _giftFor = val; _currentStep = 2; }),
        );
      }
      if (_currentStep == 2) {
        return _buildQuestionCard(
          title: 'What is the occasion?',
          options: _occasions,
          onSelect: (val) => setState(() { _occasion = val; _currentStep = 3; }),
        );
      }
      if (_currentStep == 3) {
        return _buildQuestionCard(
          title: 'What message do you want to convey? (Purpose)',
          options: _purposes,
          onSelect: (val) => setState(() { _purpose = val; _currentStep = 4; }),
        );
      }
      if (_currentStep == 4) {
        return _buildQuestionCard(
          title: 'Where will the recipient keep it?',
          options: _locations,
          onSelect: (val) => setState(() { _location = val; _currentStep = 5; }),
        );
      }
      if (_currentStep == 5) {
        return _buildQuestionCard(
          title: 'How much sunlight is available there?',
          options: _lights,
          onSelect: (val) {
            _light = val;
            _fetchRecommendations();
          },
        );
      }
    }

    // --- Results Step ---
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recommended Plants',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
        ),
        const SizedBox(height: 4),
        Text(
          'We found ${_recommendations.length} matching matches based on your inputs.',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: _recommendations.length,
            itemBuilder: (context, index) {
              final rec = _recommendations[index];
              final Plant plant = rec['plant'];
              final List<String> reasons = rec['reasons'];
              final int score = rec['score'];

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primaryColor.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              plant.imageUrl ?? '',
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plant.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3748)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Match Score: $score points',
                                  style: TextStyle(color: primaryColor, fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.star, color: Colors.amber[600], size: 20),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        'Why it matches:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      ...reasons.map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline, color: primaryColor, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    r,
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF4A5568)),
                                  ),
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: CustomButton(
                          text: 'View Plant Details',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => DetailsScreen(plant: plant)),
                            );
                          },
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            text: 'Retake Matcher',
            isPrimary: false,
            onTap: _reset,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard({
    required String title,
    required List<String> options,
    required Function(String) onSelect,
  }) {
    return Center(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2D3748),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 24),
            ...options.map((opt) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1.5),
                        backgroundColor: const Color(0xFFF8F9FA),
                      ),
                      onPressed: () => onSelect(opt),
                      child: Text(
                        opt,
                        style: const TextStyle(
                          color: Color(0xFF4A5568),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
