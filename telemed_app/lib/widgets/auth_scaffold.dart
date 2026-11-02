import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'language_menu_button.dart';

const authGradient = [Color(0xFF26A69A), Color(0xFF00796B), Color(0xFF01579B)];

/// Colourful background + logo + floating white card for Login/Register.
class AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;
  final bool showBack;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final height = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: [
            // Gradient background
            Container(
              height: height * 0.45,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: authGradient,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
              ),
            ),
            // Decorative circles
            Positioned(
              top: -70,
              right: -50,
              child: _Orb(size: 200, color: Colors.white.withValues(alpha: 0.08)),
            ),
            Positioned(
              top: height * 0.22,
              left: -60,
              child: _Orb(size: 150, color: Colors.white.withValues(alpha: 0.07)),
            ),
            Positioned(
              top: 90,
              right: 44,
              child: _Orb(size: 26, color: Colors.amber.withValues(alpha: 0.75)),
            ),
            Positioned(
              top: height * 0.30,
              right: 72,
              child: _Orb(size: 14, color: Colors.lightGreenAccent.withValues(alpha: 0.75)),
            ),
            Positioned(
              top: 150,
              left: 36,
              child: _Orb(size: 10, color: Colors.cyanAccent.withValues(alpha: 0.7)),
            ),

            // Content
            SafeArea(
              child: Column(
                children: [
                  Theme(
                    data: theme.copyWith(
                      iconTheme: const IconThemeData(color: Colors.white),
                      iconButtonTheme: IconButtonThemeData(
                        style: IconButton.styleFrom(foregroundColor: Colors.white),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(children: [
                        if (showBack)
                          const BackButton(color: Colors.white)
                        else
                          const SizedBox(width: 48),
                        const Spacer(),
                        const LanguageMenuButton(),
                      ]),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: Column(
                        children: [
                          // Logo badge
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.health_and_safety,
                                size: 46, color: Color(0xFF00796B)),
                          ),
                          const SizedBox(height: 16),
                          Text(title,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(subtitle,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: Colors.white.withValues(alpha: 0.9))),
                          const SizedBox(height: 24),

                          // Floating form card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: scheme.surface,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.10),
                                  blurRadius: 30,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: child,
                          ),
                          if (footer != null) ...[const SizedBox(height: 16), footer!],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  const _Orb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

/// Tinted, rounded input style for auth forms.
InputDecoration authInputDecoration(
  BuildContext context, {
  required String label,
  required IconData icon,
  Widget? suffix,
  String? hint,
}) {
  final scheme = Theme.of(context).colorScheme;
  final radius = BorderRadius.circular(16);
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon, color: scheme.primary),
    suffixIcon: suffix,
    filled: true,
    fillColor: scheme.primary.withValues(alpha: 0.05),
    border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: scheme.primary.withValues(alpha: 0.12)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: scheme.primary, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: scheme.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: scheme.error, width: 1.6),
    ),
  );
}

/// Full-width gradient button with glow and loading state.
class GradientButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final radius = BorderRadius.circular(16);

    return Opacity(
      opacity: (enabled || loading) ? 1 : 0.6,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: authGradient),
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: authGradient[1].withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: enabled ? onPressed : null,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                    )
                  : Text(label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      )),
            ),
          ),
        ),
      ),
    );
  }
}