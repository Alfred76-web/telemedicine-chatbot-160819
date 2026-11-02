import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/consultation_service.dart';

class ChatProvider extends ChangeNotifier {
  final ConsultationService _service = ConsultationService();

  final List<ChatMessage> messages = [];
  bool isSending = false;

  String? _lastFailedText;
  String _lastLanguage = 'en';

  Future<void> send(String text, String language) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || isSending) return;
    messages.add(ChatMessage(sender: Sender.patient, text: trimmed));
    await _ask(trimmed, language);
  }

  Future<void> retry() async {
    if (_lastFailedText == null || isSending) return;
    messages.removeWhere((m) => m.isError);
    await _ask(_lastFailedText!, _lastLanguage);
  }

  Future<void> _ask(String text, String language) async {
    isSending = true;
    notifyListeners();
    try {
      final result = await _service.start(text, language);
      messages.add(ChatMessage(
        sender: Sender.bot,
        text: result.response,
        triage: result.triage,
        smsSent: result.smsSent,
      ));
      _lastFailedText = null;
    } catch (_) {
      _lastFailedText = text;
      _lastLanguage = language;
      messages.add(ChatMessage(sender: Sender.bot, text: '', isError: true));
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  void clear() {
    messages.clear();
    _lastFailedText = null;
    notifyListeners();
  }
}