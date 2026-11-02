import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GradientHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final Widget? bottom;

  const GradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light, // white status-bar icons on teal
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
            16, MediaQuery.paddingOf(context).top + 8, 8, bottom == null ? 16 : 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primary, Color.lerp(primary, Colors.black, 0.35)!],
          ),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
        child: Theme(
          data: theme.copyWith(
            iconTheme: const IconThemeData(color: Colors.white),
            iconButtonTheme: IconButtonThemeData(
              style: IconButton.styleFrom(foregroundColor: Colors.white),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 12)],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white, fontWeight: FontWeight.bold)),
                        if (subtitle != null)
                          Text(subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: Colors.white.withValues(alpha: 0.85))),
                      ],
                    ),
                  ),
                  ...actions,
                ],
              ),
              if (bottom != null) ...[
                const SizedBox(height: 16),
                Padding(padding: const EdgeInsets.only(right: 8), child: bottom!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}