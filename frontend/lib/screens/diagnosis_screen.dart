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
  final List<Map<String, dynamic>> _messages = [];
  
  final TextEditingController _chatInputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoadingBotResponse = false;
  bool _isUploadingPhoto = false;
  
  String? _uploadedPhotoUrl;
  List<PlantCard> _userCards = [];
  PlantCard? _selectedCard; // Context plant card selected at the top

  @override
  void initState() {
    super.initState();
    _loadUserPlantCards();
    
    // Add initial bot greeting
    _messages.add({
      'sender': 'bot',
      'text': "Hello! I am your GreenNest Plant Health Assistant. 🌿\n\nPlease describe any symptoms you see (e.g. 'leaves are yellowing', 'stems feel mushy'), ask questions, or attach a photo of your plant, and I will help you diagnose it!",
    });
  }

  @override
  void dispose() {
    _chatInputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserPlantCards() async {
    try {
      final cards = await _apiService.fetchUserPlantCards(1);
      setState(() {
        _userCards = cards;
      });
    } catch (e) {
      // Fail silently
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

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
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Symptom photo attached successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to attach photo: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _chatInputController.text.trim();
    final photoUrl = _uploadedPhotoUrl;
    
    if (text.isEmpty && photoUrl == null) return;
    
    // Add user message to screen
    setState(() {
      _messages.add({
        'sender': 'user',
        'text': text.isNotEmpty ? text : 'Shared a symptom photo.',
        'photoUrl': photoUrl,
      });
      _chatInputController.clear();
      _uploadedPhotoUrl = null;
      _isLoadingBotResponse = true;
    });
    
    _scrollToBottom();
    
    try {
      // Map conversation history
      final history = _messages.map((m) => {
        'sender': m['sender'] as String,
        'text': m['text'] as String,
      }).toList();
      
      final response = await _apiService.diagnosePlantChat(
        message: text,
        history: history,
        photoUrl: photoUrl,
        plantCardId: _selectedCard?.plantCardId,
      );
      
      setState(() {
        _messages.add({
          'sender': 'bot',
          'text': response['response'],
          'diagnosis': response['diagnosis'],
          'photoUrl': photoUrl, // Keep reference to save log
        });
        _isLoadingBotResponse = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'sender': 'bot',
          'text': "Sorry, I had trouble analyzing that. Error details: $e",
        });
        _isLoadingBotResponse = false;
      });
    }
    
    _scrollToBottom();
  }

  void _showSaveOptionDialog(String diagnosis, String? photoUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Save Health Diagnosis'),
          content: const Text('Would you like to log this diagnosis to an existing plant or register a new PlantCard?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showSelectCardDialog(diagnosis, photoUrl);
              },
              child: const Text('Existing Plant'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showCreateCardDialog(context, diagnosis, photoUrl);
              },
              child: const Text('New PlantCard'),
            ),
          ],
        );
      },
    );
  }

  void _showSelectCardDialog(String diagnosis, String? photoUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Saved Plant'),
          content: SizedBox(
            width: double.maxFinite,
            child: _userCards.isEmpty
                ? const Text('You have no saved plants in your garden. Please create a new PlantCard.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _userCards.length,
                    itemBuilder: (context, index) {
                      final card = _userCards[index];
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            card.photoUrl ?? 'https://images.unsplash.com/photo-1596547609652-9cf5d8d76921',
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(card.nickname),
                        subtitle: Text(card.species),
                        onTap: () async {
                          Navigator.pop(context);
                          await _logToExistingCard(card.plantCardId, diagnosis, photoUrl);
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logToExistingCard(int plantCardId, String diagnosis, String? photoUrl) async {
    setState(() => _isLoadingBotResponse = true);
    try {
      await _apiService.addHealthLog(plantCardId, {
        'entry_type': 'Diagnosis',
        'diagnosis': diagnosis,
        'confidence': 80.0,
        'photo_url': photoUrl,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diagnosis successfully logged to PlantCard timeline!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save log: $e')),
        );
      }
    } finally {
      setState(() => _isLoadingBotResponse = false);
    }
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
                Navigator.pop(context); // close dialog
                setState(() => _isLoadingBotResponse = true);
                
                try {
                  final card = await _apiService.createPlantCard(1, {
                    'nickname': nicknameController.text,
                    'species': speciesController.text,
                    'water_frequency': 'Weekly',
                    'fertilize_frequency': 'Monthly',
                    'photo_url': photoUrl,
                  });
                  
                  await _apiService.addHealthLog(card.plantCardId, {
                    'entry_type': 'Diagnosis',
                    'diagnosis': currentDiagnosis,
                    'confidence': 80.0,
                    'photo_url': photoUrl,
                  });

                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const PlantCardsScreen()),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Successfully created PlantCard and saved diagnosis!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to save PlantCard: $e')),
                    );
                  }
                } finally {
                  setState(() => _isLoadingBotResponse = false);
                }
              },
              child: const Text('Save'),
            )
          ],
        );
      },
    );
  }

  List<TextSpan> _parseFormattedText(String text) {
    final List<TextSpan> spans = [];
    final RegExp regExp = RegExp(r'\*\*(.*?)\*\*');
    int start = 0;
    
    for (final Match match in regExp.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
      start = match.end;
    }
    
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    
    return spans;
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
      body: Column(
        children: [
          // Select Plant Card Context Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.spa_outlined, color: primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Diagnosing Plant:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A5568)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<PlantCard?>(
                        value: _selectedCard,
                        hint: const Text('General / Unsaved Plant'),
                        items: [
                          const DropdownMenuItem<PlantCard?>(
                            value: null,
                            child: Text('General / Unsaved Plant'),
                          ),
                          ..._userCards.map((c) => DropdownMenuItem<PlantCard?>(
                            value: c,
                            child: Text(c.nickname),
                          )),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedCard = val;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Chat bubbles feed
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoadingBotResponse ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  // Show typing bubble
                  return _buildTypingBubble(primaryColor);
                }
                
                final msg = _messages[index];
                final isUser = msg['sender'] == 'user';
                
                return _buildMessageBubble(msg, isUser, primaryColor);
              },
            ),
          ),
          
          // Attached image preview bar
          if (_uploadedPhotoUrl != null) _buildAttachedPhotoPreview(),
          
          // Text Input and controls
          _buildChatInputBar(primaryColor),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isUser, Color primaryColor) {
    final bubbleColor = isUser ? primaryColor : Colors.white;
    final textColor = isUser ? Colors.white : const Color(0xFF2D3748);
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final radius = isUser 
        ? const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomLeft: Radius.circular(18))
        : const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomRight: Radius.circular(18));

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (msg['photoUrl'] != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  msg['photoUrl'] as String,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                ),
              ),
              const SizedBox(height: 8),
            ],
            RichText(
              text: TextSpan(
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  height: 1.4,
                  fontFamily: 'Inter',
                ),
                children: _parseFormattedText(msg['text'] as String),
              ),
            ),
            if (!isUser && msg['diagnosis'] != null) ...[
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showSaveOptionDialog(msg['diagnosis'] as String, msg['photoUrl'] as String?),
                    icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                    label: const Text('Log to Garden'),
                    style: TextButton.styleFrom(
                      foregroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              )
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypingBubble(Color primaryColor) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Scanning symptoms...',
              style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachedPhotoPreview() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _uploadedPhotoUrl!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _uploadedPhotoUrl = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Symptom image attached and ready to analyze.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInputBar(Color primaryColor) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Upload button
            _isUploadingPhoto
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: Icon(Icons.photo_camera_back_outlined, color: primaryColor),
                    tooltip: 'Attach Symptom Photo',
                    onPressed: _pickAndUploadPhoto,
                  ),
            const SizedBox(width: 8),
            
            // Text box
            Expanded(
              child: TextFormField(
                controller: _chatInputController,
                decoration: InputDecoration(
                  hintText: 'Describe plant symptoms here...',
                  fillColor: const Color(0xFFF1F5F9),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onFieldSubmitted: (_) => _sendMessage(),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Send button
            IconButton(
              icon: Icon(Icons.send_rounded, color: primaryColor),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
