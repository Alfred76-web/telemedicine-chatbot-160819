import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/chat_message.dart';
import '../models/consultation_results.dart';
import '../models/health_record.dart';

class ConsultationService {
  final _dio = ApiClient.instance.dio;

  Future<ConsultationResult> start(String symptoms, String language) async {
    final res = await _dio.post(
      '/consultation/start',
      data: {'symptoms': symptoms, 'language': language},
      options: Options(receiveTimeout: const Duration(seconds: 90)),
    );
    return ConsultationResult.fromJson(res.data);
  }

  Future<List<HealthRecord>> history() async {
    final res = await _dio.get('/consultation/history');
    final list = (res.data['consultations'] as List).cast<Map<String, dynamic>>();
    return list.map(HealthRecord.fromJson).toList();
  }

  Future<List<ChatMessage>> messages(String consultationId) async {
    final res = await _dio.get('/consultation/$consultationId/messages');
    final list = (res.data['messages'] as List).cast<Map<String, dynamic>>();
    return list
        .map((m) => ChatMessage(
              sender: m['sender'] == 'patient' ? Sender.patient : Sender.bot,
              text: m['content'] ?? '',
              time: DateTime.parse(m['created_at']).toLocal(),
            ))
        .toList();
  }
}