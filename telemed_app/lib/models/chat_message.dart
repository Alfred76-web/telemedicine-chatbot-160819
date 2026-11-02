enum Sender { patient, bot }

class ChatMessage {
  final Sender sender;
  final String text;
  final String? triage;
  final bool isError;
  final bool smsSent;
  final DateTime time;

  ChatMessage({
    required this.sender,
    required this.text,
    this.triage,
    this.isError = false,
    this.smsSent = false,
    DateTime? time,
  }) : time = time ?? DateTime.now();
}