import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/phone_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/auth_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final t = AppLocalizations.of(context);
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      name: _name.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      phone: normalizeKenyanPhone(_phone.text)!,
      languagePref: context.read<LocaleProvider>().code,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(auth.error ?? t.registrationFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final loading = context.watch<AuthProvider>().isLoading;
    final language = context.watch<LocaleProvider>().code;

    return AuthScaffold(
      showBack: true,
      title: t.createAccount,
      subtitle: t.registerSubtitle,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: authInputDecoration(context,
                  label: t.fullName, icon: Icons.person_outline),
              validator: (v) => (v == null || v.trim().length < 2) ? t.errName : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: authInputDecoration(context,
                  label: t.email, icon: Icons.email_outlined),
              validator: (v) => (v == null || !v.contains('@')) ? t.errEmail : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: authInputDecoration(context,
                  label: t.phoneNumber, icon: Icons.phone_outlined, hint: '0712 345 678'),
              validator: (v) => normalizeKenyanPhone(v ?? '') == null ? t.errPhone : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              key: ValueKey(language),
              initialValue: language,
              decoration: authInputDecoration(context,
                  label: t.preferredLanguage, icon: Icons.language),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'sw', child: Text('Kiswahili')),
              ],
              onChanged: (v) {
                if (v != null) context.read<LocaleProvider>().setLocale(v);
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              textInputAction: TextInputAction.next,
              decoration: authInputDecoration(
                context,
                label: t.password,
                icon: Icons.lock_outline,
                suffix: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) => (v == null || v.length < 8) ? t.errPasswordShort : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirm,
              obscureText: _obscure,
              onFieldSubmitted: (_) => _submit(),
              decoration: authInputDecoration(context,
                  label: t.confirmPassword, icon: Icons.lock_reset),
              validator: (v) => v != _password.text ? t.errPasswordMatch : null,
            ),
            const SizedBox(height: 28),
            GradientButton(label: t.createAccount, loading: loading, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}