import 'package:flutter/foundation.dart';
import '../models/health_record.dart';
import '../services/consultation_service.dart';

class HistoryProvider extends ChangeNotifier {
  final ConsultationService _service = ConsultationService();

  List<HealthRecord> records = [];
  bool isLoading = false;
  bool hasError = false;

  Future<void> load() async {
    if (isLoading) return;
    isLoading = true;
    hasError = false;
    notifyListeners();
    try {
      records = await _service.history();
    } catch (e) {
      debugPrint('❌ History failed: $e');
      hasError = true;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    records = [];
    hasError = false;
    notifyListeners();
  }
}