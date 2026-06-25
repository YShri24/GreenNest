import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:greennest/services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  int? _userId;
  String? _name;
  String? _email;
  String? _role;
  bool _isLoading = false;

  bool get isAuthenticated => _userId != null;
  int? get userId => _userId;
  String? get name => _name;
  String? get email => _email;
  String? get role => _role;
  bool get isLoading => _isLoading;

  // Try to load cached user credentials from SharedPreferences on app startup
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userId')) return false;

    _userId = prefs.getInt('userId');
    _name = prefs.getString('userName');
    _email = prefs.getString('userEmail');
    _role = prefs.getString('userRole');
    notifyListeners();
    return true;
  }

  // Handle User Login
  Future<void> login(String emailInput, String passwordInput) async {
    _isLoading = true;
    notifyListeners();
    try {
      final userData = await _apiService.login(emailInput, passwordInput);
      _userId = userData['user_id'];
      _name = userData['name'];
      _email = userData['email'];
      _role = userData['role'];

      // Cache locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('userId', _userId!);
      await prefs.setString('userName', _name!);
      await prefs.setString('userEmail', _email!);
      await prefs.setString('userRole', _role!);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Handle User Registration
  Future<void> signup(
    String nameInput,
    String emailInput,
    String mobileInput,
    String passwordInput, {
    String? addressInput,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final payload = {
        'name': nameInput,
        'email': emailInput,
        'mobile': mobileInput,
        'password': passwordInput,
        'address': addressInput,
      };
      
      final userData = await _apiService.signup(payload);
      _userId = userData['user_id'];
      _name = userData['name'];
      _email = userData['email'];
      _role = userData['role'];

      // Cache locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('userId', _userId!);
      await prefs.setString('userName', _name!);
      await prefs.setString('userEmail', _email!);
      await prefs.setString('userRole', _role!);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Handle Logout
  Future<void> logout() async {
    _userId = null;
    _name = null;
    _email = null;
    _role = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
