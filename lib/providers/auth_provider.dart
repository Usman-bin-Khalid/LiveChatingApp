import 'package:flutter/material.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  UserModel? _user;
  bool _isLoading = false;

  AuthProvider(this._authRepository);

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _authRepository.login(email, password);
      return _user != null;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signup(String username, String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      return await _authRepository.signup(username, email, password);
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _user = null;
    notifyListeners();
  }

  Future<void> checkAuth() async {
    final userId = await _authRepository.getUserId();
    if (userId != null) {
      // In a real app, you might fetch user profile here
      _user = UserModel(id: userId, username: 'User', email: '');
      notifyListeners();
    }
  }
}
