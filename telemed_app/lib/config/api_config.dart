class ApiConfig {
  // 10.0.2.2 = your computer's localhost, as seen from the Android emulator.
  // On a real phone, replace with your PC's Wi-Fi IP (run `ipconfig`), e.g. 192.168.1.20
  static const String host = 'http://localhost:5000';
  static const String baseUrl = '$host/api';
  static const Duration timeout = Duration(seconds: 30); // Gemini can be slow
}