import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';

class LanguageMenuButton extends StatelessWidget {
  const LanguageMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final current = context.watch<LocaleProvider>().code;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.translate),
      tooltip: AppLocalizations.of(context).language,
      initialValue: current,
      onSelected: (code) async {
        final auth = context.read<AuthProvider>();
        if (auth.status == AuthStatus.loggedIn) {
          final ok = await auth.updateLanguage(code); // saves to DB → app follows
          if (!ok && context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(auth.error ?? 'Error')));
          }
        } else {
          context.read<LocaleProvider>().setLocale(code);
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'en', child: Text('English')),
        PopupMenuItem(value: 'sw', child: Text('Kiswahili')),
      ],
    );
  }
}