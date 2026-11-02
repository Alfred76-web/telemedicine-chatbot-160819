class HealthRecord {
  final String id;
  final String consultationId;
  final String symptoms;
  final String triage;
  final String advice;
  final String language;
  final DateTime createdAt;

  HealthRecord({
    required this.id,
    required this.consultationId,
    required this.symptoms,
    required this.triage,
    required this.advice,
    required this.language,
    required this.createdAt,
  });

  factory HealthRecord.fromJson(Map<String, dynamic> json) => HealthRecord(
        id: json['id'].toString(),
        consultationId: json['consultation_id'].toString(),
        symptoms: json['symptoms_reported'] ?? '',
        triage: json['triage_outcome'] ?? 'clinic',
        advice: json['advice_given'] ?? '',
        language: json['language_used'] ?? 'en',
        createdAt: DateTime.parse(json['created_at']).toLocal(),
      );
}