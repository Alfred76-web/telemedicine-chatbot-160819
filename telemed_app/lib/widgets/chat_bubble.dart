import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../models/chat_message.dart';
import 'care_actions.dart';
import 'triage_badge.dart';

/// Round assistant icon — gradient on light backgrounds, white on the header.
class AssistantAvatar extends StatelessWidget {
  final double size;
  final bool onDark;
  const AssistantAvatar({super.key, this.size = 32, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: onDark ? Colors.white : null,
        gradient: onDark
            ? null
            : LinearGradient(colors: [primary, Color.lerp(primary, Colors.black, 0.35)!]),
      ),
      child: Icon(Icons.health_and_safety,
          size: size * 0.55, color: onDark ? primary : Colors.white),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onRetry;
  const ChatBubble({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isPatient = message.sender == Sender.patient;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.75;
    final primary = scheme.primary;

    final Widget content = message.isError
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t.chatError, style: TextStyle(color: scheme.onErrorContainer)),
              if (onRetry != null)
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(t.retry),
                ),
            ],
          )
        : SelectableText(
            message.text,
            style: TextStyle(
              color: isPatient ? Colors.white : scheme.onSurface,
              height: 1.45,
              fontSize: 15,
            ),
          );

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: message.isError
            ? scheme.errorContainer
            : (isPatient ? null : scheme.surface),
        gradient: (isPatient && !message.isError)
            ? LinearGradient(colors: [primary, Color.lerp(primary, Colors.black, 0.25)!])
            : null,
        border: isPatient
            ? null
            : Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isPatient ? 20 : 6),
          topRight: Radius.circular(isPatient ? 6 : 20),
          bottomLeft: const Radius.circular(20),
          bottomRight: const Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: content,
    );

    final timeText = Padding(
      padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
      child: Text(DateFormat.Hm().format(message.time),
          style: theme.textTheme.labelSmall?.copyWith(color: scheme.outline)),
    );

    // ── Patient message (right side) ─────────────────────────────────────
    if (isPatient) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [bubble, timeText],
          ),
        ),
      );
    }

    // ── Bot message (left side, with avatar) ─────────────────────────────
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AssistantAvatar(size: 32),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bubble,

                // Triage card
                if (message.triage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: TriageBadge(triage: message.triage!),
                    ),
                  ),

                // Find nearby care / Call 999 buttons
                if (message.triage != null) CareActions(triage: message.triage!),

                // "SMS summary sent" note
                if (message.smsSent)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.sms_outlined, size: 14, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(t.smsSent,
                            style: TextStyle(fontSize: 12, color: Colors.green.shade700)),
                      ),
                    ]),
                  ),

                timeText,
              ],
            ),
          ),
        ],
      ),
    );
  }
}