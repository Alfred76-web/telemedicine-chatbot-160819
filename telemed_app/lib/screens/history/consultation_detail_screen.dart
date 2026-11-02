import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../models/chat_message.dart';
import '../../models/health_record.dart';
import '../../services/consultation_service.dart';
import '../../widgets/chat_bubble.dart';

class ConsultationDetailScreen extends StatefulWidget {
  final HealthRecord record;
  const ConsultationDetailScreen({super.key, required this.record});

  @override
  State<ConsultationDetailScreen> createState() => _ConsultationDetailScreenState();
}

class _ConsultationDetailScreenState extends State<ConsultationDetailScreen> {
  late Future<List<ChatMessage>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ChatMessage>> _load() async {
    final msgs = await ConsultationService().messages(widget.record.consultationId);
    final i = msgs.lastIndexWhere((m) => m.sender == Sender.bot);
    if (i != -1) {
      final m = msgs[i];
      msgs[i] = ChatMessage(
        sender: m.sender,
        text: m.text,
        triage: widget.record.triage,
        time: m.time,
      );
    }
    return msgs;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).languageCode;
    final date = DateFormat.yMMMMEEEEd(locale).add_jm().format(widget.record.createdAt);

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(t.consultationDetails),
        backgroundColor: scheme.surfaceContainerLowest,
      ),
      body: FutureBuilder<List<ChatMessage>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(t.historyError),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() => _future = _load()),
                  child: Text(t.retry),
                ),
              ]),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
            children: [
              // Summary card
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
                ),
                child: Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.event_note, color: scheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(date,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.record.language == 'sw' ? 'Kiswahili' : 'English',
                      style: TextStyle(
                          color: scheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ]),
              ),
              ...snap.data!.map((m) => ChatBubble(message: m)),
            ],
          );
        },
      ),
    );
  }
}