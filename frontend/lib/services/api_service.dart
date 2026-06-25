import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:greennest/models/plant.dart';
import 'package:greennest/models/plant_card.dart';
import 'package:greennest/models/health_log.dart';

class ApiService {
  // Use http://10.0.2.2:8000 for Android emulator, or http://127.0.0.1:8000 for web/desktop/iOS simulator
  static const String baseUrl = 'http://127.0.0.1:8000'; 

  // Fetch all plants from catalog
  Future<List<Plant>> fetchPlants({String? category, String? search}) async {
    String url = '$baseUrl/api/plants';
    List<String> params = [];
    if (category != null && category.isNotEmpty) params.add('category=$category');
    if (search != null && search.isNotEmpty) params.add('search=$search');
    if (params.isNotEmpty) url += '?${params.join('&')}';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => Plant.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load plants catalog');
    }
  }

  // Fetch single plant details
  Future<Plant> fetchPlantDetails(int plantId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/plants/$plantId'));
    if (response.statusCode == 200) {
      return Plant.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load plant details');
    }
  }

  // Fetch recommendations from AI Engine
  Future<List<Map<String, dynamic>>> getRecommendations(Map<String, dynamic> answers) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/plants/recommend'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(answers),
    );
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => {
        'plant': Plant.fromJson(item['plant']),
        'score': item['score'] as int,
        'reasons': List<String>.from(item['reasons']),
      }).toList();
    } else {
      throw Exception('Failed to fetch recommendations');
    }
  }

  // Request plant disease diagnosis
  Future<Map<String, dynamic>> diagnosePlant({
    required List<String> symptoms,
    String? location,
    String? light,
    String? waterFrequency,
    int? plantCardId,
  }) async {
    final payload = {
      'symptoms': symptoms,
      'location': location,
      'light': light,
      'water_frequency': waterFrequency,
      'plant_card_id': plantCardId,
    };
    final response = await http.post(
      Uri.parse('$baseUrl/api/diagnosis'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Diagnosis failed');
    }
  }

  // Request plant disease diagnosis via chat bot conversational flow
  Future<Map<String, dynamic>> diagnosePlantChat({
    required String message,
    required List<Map<String, String>> history,
    String? photoUrl,
    int? plantCardId,
  }) async {
    final payload = {
      'message': message,
      'history': history,
      'photo_url': photoUrl,
      'plant_card_id': plantCardId,
    };
    final response = await http.post(
      Uri.parse('$baseUrl/api/diagnosis/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      try {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Diagnosis failed');
      } catch (_) {
        throw Exception('Diagnosis failed: ${response.statusCode}');
      }
    }
  }

  // Fetch saved plant cards for digital journal
  Future<List<PlantCard>> fetchUserPlantCards(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/users/$userId/plantcards'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => PlantCard.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load user plant cards');
    }
  }

  // Fetch detailed single plant card
  Future<PlantCard> fetchPlantCardDetails(int plantCardId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/plantcards/$plantCardId'));
    if (response.statusCode == 200) {
      return PlantCard.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load plant card details');
    }
  }

  // Create/Save a new plant card
  Future<PlantCard> createPlantCard(int userId, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/users/$userId/plantcards'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return PlantCard.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create plant card');
    }
  }

  // Delete/Remove a plant card
  Future<void> deletePlantCard(int plantCardId) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/plantcards/$plantCardId'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete plant card');
    }
  }

  // Add a health log entry to a plant card
  Future<HealthLog> addHealthLog(int plantCardId, Map<String, dynamic> logData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/plantcards/$plantCardId/logs'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(logData),
    );
    if (response.statusCode == 200) {
      return HealthLog.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add health log');
    }
  }

  // Place a shopping checkout order
  Future<Map<String, dynamic>> placeOrder(int userId, List<Map<String, int>> items) async {
    final payload = {
      'user_id': userId,
      'items': items.map((i) => {'plant_id': i['plant_id'], 'quantity': i['quantity']}).toList(),
    };
    final response = await http.post(
      Uri.parse('$baseUrl/api/orders'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Checkout order placement failed');
    }
  }

  // Send a plant gift
  Future<Map<String, dynamic>> sendGift(Map<String, dynamic> giftData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/gifts'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(giftData),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Sending gift failed');
    }
  }

  // Upload an image file to the backend (returns absolute URL)
  Future<String> uploadImage(List<int> bytes, String filename) async {
    final uri = Uri.parse('$baseUrl/api/upload');
    final request = http.MultipartRequest('POST', uri);
    
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
    ));
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final relativeUrl = data['url'] as String;
      return '$baseUrl$relativeUrl';
    } else {
      try {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Failed to upload image');
      } catch (_) {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    }
  }

  // Create a new plant catalog entry (Admin)
  Future<Plant> createPlant(Map<String, dynamic> plantData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/plants'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(plantData),
    );
    if (response.statusCode == 200) {
      return Plant.fromJson(jsonDecode(response.body));
    } else {
      try {
        final error = jsonDecode(response.body);
        // If there's a Pydantic validation error or detailed error list, extract it nicely
        if (error['detail'] is List) {
          final list = error['detail'] as List;
          final messages = list.map((err) => "${err['loc']?.last ?? 'field'}: ${err['msg']}").join(", ");
          throw Exception(messages);
        }
        throw Exception(error['detail'] ?? 'Failed to add plant to catalog');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to add plant to catalog: ${response.statusCode}');
      }
    }
  }

  // Update an existing plant catalog entry (Admin)
  Future<Plant> updatePlant(int plantId, Map<String, dynamic> plantData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/plants/$plantId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(plantData),
    );
    if (response.statusCode == 200) {
      return Plant.fromJson(jsonDecode(response.body));
    } else {
      try {
        final error = jsonDecode(response.body);
        if (error['detail'] is List) {
          final list = error['detail'] as List;
          final messages = list.map((err) => "${err['loc']?.last ?? 'field'}: ${err['msg']}").join(", ");
          throw Exception(messages);
        }
        throw Exception(error['detail'] ?? 'Failed to update plant');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to update plant: ${response.statusCode}');
      }
    }
  }

  // Delete a plant catalog entry (Admin)
  Future<void> deletePlant(int plantId) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/plants/$plantId'));
    if (response.statusCode != 200) {
      try {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Failed to delete plant');
      } catch (_) {
        throw Exception('Failed to delete plant: ${response.statusCode}');
      }
    }
  }

  // Fetch all user checkout orders (Admin)
  Future<List<Map<String, dynamic>>> fetchAllOrders() async {
    final response = await http.get(Uri.parse('$baseUrl/api/admin/orders'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => item as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to load customer orders');
    }
  }

  // Fetch all scheduled gifts (Admin)
  Future<List<Map<String, dynamic>>> fetchAllGifts() async {
    final response = await http.get(Uri.parse('$baseUrl/api/admin/gifts'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => item as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to load scheduled gifts');
    }
  }

  // User Sign In / Log In
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to log in');
    }
  }

  // User Sign Up / Registration
  Future<Map<String, dynamic>> signup(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to sign up');
    }
  }
}
