/// Converts Kenyan numbers to +2547XXXXXXXX / +2541XXXXXXXX, or null if invalid.
String? normalizeKenyanPhone(String input) {
  final p = input.replaceAll(RegExp(r'[\s-]'), '');
  if (RegExp(r'^0[17]\d{8}$').hasMatch(p)) return '+254${p.substring(1)}';
  if (RegExp(r'^\+254[17]\d{8}$').hasMatch(p)) return p;
  if (RegExp(r'^254[17]\d{8}$').hasMatch(p)) return '+$p';
  return null;
}