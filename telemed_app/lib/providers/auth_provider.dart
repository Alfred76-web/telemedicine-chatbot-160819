import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../core/token_storage.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

enum AuthStatus { checking, loggedOut, loggedIn }

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  AuthStatus status = AuthStatus.checking;
  User? user;
  bool isLoading = false;
  bool isSaving = false;
  String? error;

  Future<void> tryAutoLogin() async {
    final token = await TokenStorage.read();
    if (token == null) {
      status = AuthStatus.loggedOut;
    } else {
      try {
        user = await _service.fetchProfile();
        status = AuthStatus.loggedIn;
      } catch (_) {
        status = AuthStatus.loggedOut;
      }
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) =>
      _run(() => _service.login(email, password));

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String languagePref,
  }) =>
      _run(() => _service.register(
            name: name,
            email: email,
            password: password,
            phone: phone,
            languagePref: languagePref,
          ));

  Future<bool> updateProfile({
    required String name,
    required String phone,
    String? dateOfBirth,
    String? gender,
    String? chronicConditions,
  }) async {
    isSaving = true;
    error = null;
    notifyListeners();
    try {
      user = await _service.updateProfile(
        name: name,
        phone: phone,
        dateOfBirth: dateOfBirth,
        gender: gender,
        chronicConditions: chronicConditions,
      );
      return true;
    } catch (e) {
      error = ApiClient.errorMessage(e);
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateLanguage(String code) async {
    if (user == null) return false;
    try {
      await _service.updateLanguage(code);
      user = user!.copyWith(languagePref: code);
      notifyListeners();
      return true;
    } catch (e) {
      error = ApiClient.errorMessage(e);
      return false;
    }
  }

  Future<void> logout() async {
    await _service.logout();
    user = null;
    status = AuthStatus.loggedOut;
    notifyListeners();
  }

  Future<bool> _run(Future<User> Function() action) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      user = await action();
      // Login/register return basic info only → load the full profile too
      try {
        user = await _service.fetchProfile();
      } catch (_) {}
      status = AuthStatus.loggedIn;
      return true;
    } catch (e) {
      error = ApiClient.errorMessage(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}