import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/chat_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/language_menu_button.dart';
import '../../widgets/triage_badge.dart';
import '../../widgets/typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send([String? preset]) async {
    final text = preset ?? _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    FocusScope.of(context).unfocus();
    final language = context.read<LocaleProvider>().code;
    final chat = context.read<ChatProvider>();
    _scrollToBottom();
    await chat.send(text, language);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final chat = context.watch<ChatProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: Column(
        children: [
          GradientHeader(
            leading: const AssistantAvatar(size: 44, onDark: true),
            title: t.healthAssistant,
            subtitle: t.assistantStatus,
            actions: [
              if (chat.messages.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.add_comment_outlined),
                  tooltip: t.newConsultation,
                  onPressed:
                      chat.isSending ? null : () => context.read<ChatProvider>().clear(),
                ),
              const LanguageMenuButton(),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: _DisclaimerPill(text: t.disclaimer),
          ),
          Expanded(
            child: chat.messages.isEmpty
                ? _WelcomeView(onExample: _send)
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: chat.messages.length + (chat.isSending ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == chat.messages.length) {
                        return TypingIndicator(text: t.thinking);
                      }
                      final m = chat.messages[i];
                      return ChatBubble(
                        message: m,
                        onRetry: m.isError
                            ? () async {
                                await context.read<ChatProvider>().retry();
                                _scrollToBottom();
                              }
                            : null,
                      );
                    },
                  ),
          ),
          _InputBar(
            controller: _controller,
            enabled: !chat.isSending,
            hint: t.chatHint,
            onSend: () => _send(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Pieces ───────────────────────────

class _DisclaimerPill extends StatelessWidget {
  final String text;
  const _DisclaimerPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(Icons.shield_outlined, size: 16, color: Colors.amber.shade800),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
        ),
      ]),
    );
  }
}

class _WelcomeView extends StatelessWidget {
  final void Function(String) onExample;
  const _WelcomeView({required this.onExample});

  static const _examples = [
    (Icons.thermostat, 'I have had fever, headache and chills for 2 days'),
    (Icons.sick, 'Nina homa na maumivu ya kichwa kwa siku tatu'),
    (Icons.air, 'I have a cough and chest pain since last week'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [primary, Color.lerp(primary, Colors.black, 0.35)!],
              ),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.health_and_safety, color: Colors.white, size: 48),
          ),
        ),
        const SizedBox(height: 20),
        Text(t.chatWelcomeTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(t.chatWelcomeBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 28),
        Text(t.chatTryExample,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ..._examples.map((e) => _ExampleCard(icon: e.$1, text: e.$2, onTap: () => onExample(e.$2))),
        const SizedBox(height: 24),
        Text(t.careLevels,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const ['self-care', 'pharmacy', 'clinic', 'emergency']
              .map((tg) => TriageBadge(triage: tg, compact: true))
              .toList(),
        ),
      ],
    );
  }
}

class _ExampleCard extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  const _ExampleCard({required this.icon, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
              Icon(Icons.arrow_forward_ios, size: 14, color: scheme.outline),
            ]),
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final String hint;
  final VoidCallback onSend;
  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.hint,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: hint,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Opacity(
              opacity: enabled ? 1 : 0.5,
              child: Material(
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: Ink(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [primary, Color.lerp(primary, Colors.black, 0.3)!],
                    ),
                  ),
                  child: InkWell(
                    onTap: enabled ? onSend : null,
                    child: const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}