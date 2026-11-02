import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/phone_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _chronic;
  String? _dob; // 'YYYY-MM-DD'
  String? _gender;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user!;
    _name = TextEditingController(text: user.name);
    _phone = TextEditingController(text: user.phone ?? '');
    _chronic = TextEditingController(text: user.chronicConditions ?? '');
    _dob = user.dateOfBirth;
    _gender = user.gender;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _chronic.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final initial = (_dob != null ? DateTime.tryParse(_dob!) : null) ?? DateTime(2000, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dob = DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final t = AppLocalizations.of(context);
    final auth = context.read<AuthProvider>();

    final ok = await auth.updateProfile(
      name: _name.text.trim(),
      phone: normalizeKenyanPhone(_phone.text)!,
      dateOfBirth: _dob,
      gender: _gender,
      chronicConditions: _chronic.text.trim(),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? t.profileSaved : (auth.error ?? t.profileSaveFailed))),
    );
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final saving = context.watch<AuthProvider>().isSaving;
    final locale = Localizations.localeOf(context).languageCode;
    final dobText = (_dob != null && DateTime.tryParse(_dob!) != null)
        ? DateFormat.yMMMMd(locale).format(DateTime.parse(_dob!))
        : t.notSet;

    return Scaffold(
      appBar: AppBar(title: Text(t.editProfile)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                      labelText: t.fullName, prefixIcon: const Icon(Icons.person_outline)),
                  validator: (v) => (v == null || v.trim().length < 2) ? t.errName : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                      labelText: t.phoneNumber, prefixIcon: const Icon(Icons.phone_outlined)),
                  validator: (v) => normalizeKenyanPhone(v ?? '') == null ? t.errPhone : null,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickDob,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: t.dateOfBirth,
                      prefixIcon: const Icon(Icons.cake_outlined),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    child: Text(dobText),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: InputDecoration(
                      labelText: t.gender, prefixIcon: const Icon(Icons.wc)),
                  items: [
                    DropdownMenuItem(value: 'male', child: Text(t.genderMale)),
                    DropdownMenuItem(value: 'female', child: Text(t.genderFemale)),
                    DropdownMenuItem(value: 'other', child: Text(t.genderOther)),
                  ],
                  onChanged: (v) => setState(() => _gender = v),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _chronic,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: t.chronicConditions,
                    hintText: t.chronicHint,
                    prefixIcon: const Icon(Icons.medical_information_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: saving ? null : _save,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  child: saving
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(t.save),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}