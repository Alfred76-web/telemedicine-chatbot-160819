import '../core/api_client.dart';
import '../core/token_storage.dart';
import '../models/user.dart';

class AuthService {
  final _dio = ApiClient.instance.dio;

  Future<User> login(String email, String password) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    await TokenStorage.save(res.data['token']);
    return User.fromJson(res.data['user']);
  }

  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String languagePref,
  }) async {
    final res = await _dio.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'language_pref': languagePref,
    });
    await TokenStorage.save(res.data['token']);
    return User.fromJson(res.data['user']);
  }

  Future<User> fetchProfile() async {
    final res = await _dio.get('/auth/profile');
    return User.fromJson(res.data['user']);
  }

  Future<User> updateProfile({
    required String name,
    required String phone,
    String? dateOfBirth,
    String? gender,
    String? chronicConditions,
  }) async {
    final res = await _dio.put('/auth/profile', data: {
      'name': name,
      'phone': phone,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'chronic_conditions': chronicConditions,
    });
    return User.fromJson(res.data['user']);
  }

  Future<void> updateLanguage(String code) async {
    await _dio.patch('/auth/language', data: {'language_pref': code});
  }

  Future<void> logout() => TokenStorage.clear();
}