import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _user;
  bool _loading = true;

  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get loading => _loading;
  ApiService get api => _api;

  Future<void> init() async {
    await _api.loadToken();
    try {
      _user = await _api.get('/auth/me');
    } catch (_) {
      _user = null;
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final data = await _api.login(email, password);
    _user = data['user'];
    notifyListeners();
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? gradeLevel,
  }) async {
    await _api.register(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      gradeLevel: gradeLevel,
    );
    await login(email, password);
  }

  Future<void> logout() async {
    await _api.clearToken();
    _user = null;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    try {
      _user = await _api.get('/auth/me');
      notifyListeners();
    } catch (_) {}
  }
}
