import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import 'triage_badge.dart';

/// Action buttons shown under a triage result: find care nearby / call 999.
class CareActions extends StatelessWidget {
  final String triage;
  const CareActions({super.key, required this.triage});

  Uri _mapsSearch(String query) => Uri.https(
        'www.google.com',
        '/maps/search/',
        {'api': '1', 'query': query},
      );

  Future<void> _open(BuildContext context, Uri uri) async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        messenger.showSnackBar(SnackBar(content: Text(t.openMapsError)));
      }
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(t.openMapsError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final info = triageInfo(context, triage);

    final List<Widget> buttons;
    switch (triage) {
      case 'pharmacy':
        buttons = [
          _ActionButton(
            icon: Icons.local_pharmacy_outlined,
            label: t.findPharmacy,
            color: info.color,
            onTap: () => _open(context, _mapsSearch('pharmacy near me')),
          ),
        ];
        break;
      case 'clinic':
        buttons = [
          _ActionButton(
            icon: Icons.local_hospital_outlined,
            label: t.findClinic,
            color: info.color,
            onTap: () => _open(context, _mapsSearch('clinic near me')),
          ),
        ];
        break;
      case 'emergency':
        buttons = [
          _ActionButton(
            icon: Icons.call,
            label: t.callEmergency,
            color: info.color,
            filled: true,
            onTap: () => _open(context, Uri(scheme: 'tel', path: '999')),
          ),
          _ActionButton(
            icon: Icons.local_hospital_outlined,
            label: t.findHospital,
            color: info.color,
            onTap: () => _open(context, _mapsSearch('hospital near me')),
          ),
        ];
        break;
      default: // self-care → no action needed
        return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(spacing: 8, runSpacing: 8, children: buttons),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        backgroundColor: color.withValues(alpha: 0.06),
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        shape: const StadiumBorder(),
      ),
    );
  }
}