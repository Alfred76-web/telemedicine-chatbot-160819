import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocaleProvider extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  static const _key = 'app_locale';

  Locale _locale = const Locale('en');
  Locale get locale => _locale;
  String get code => _locale.languageCode;

  /// Load the language saved on this phone (used before login).
  Future<void> load() async {
    final saved = await _storage.read(key: _key);
    if (saved == 'en' || saved == 'sw') {
      _locale = Locale(saved!);
      notifyListeners();
    }
  }

  Future<void> setLocale(String code) async {
    if ((code != 'en' && code != 'sw') || code == _locale.languageCode) return;
    _locale = Locale(code);
    notifyListeners();
    await _storage.write(key: _key, value: code);
  }
}