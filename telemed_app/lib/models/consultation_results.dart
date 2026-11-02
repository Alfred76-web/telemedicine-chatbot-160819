class ConsultationResult {
  final String consultationId;
  final String language;
  final String triage;
  final String response;
  final bool smsSent;

  ConsultationResult({
    required this.consultationId,
    required this.language,
    required this.triage,
    required this.response,
    required this.smsSent,
  });

  factory ConsultationResult.fromJson(Map<String, dynamic> json) => ConsultationResult(
        consultationId: json['consultationId'].toString(),
        language: json['language'] ?? 'en',
        triage: json['triage'] ?? 'clinic',
        response: json['response'] ?? '',
        smsSent: json['smsSent'] == true,
      );
}