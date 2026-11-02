import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class TriageInfo {
  final Color color;
  final IconData icon;
  final String label;
  final String description;
  const TriageInfo(this.color, this.icon, this.label, this.description);
}

TriageInfo triageInfo(BuildContext context, String triage) {
  final t = AppLocalizations.of(context);
  switch (triage) {
    case 'self-care':
      return TriageInfo(Colors.green.shade700, Icons.home_outlined,
          t.triageSelfCare, t.triageSelfCareDesc);
    case 'pharmacy':
      return TriageInfo(Colors.blue.shade700, Icons.local_pharmacy_outlined,
          t.triagePharmacy, t.triagePharmacyDesc);
    case 'emergency':
      return TriageInfo(Colors.red.shade700, Icons.warning_amber_rounded,
          t.triageEmergency, t.triageEmergencyDesc);
    case 'clinic':
    default:
      return TriageInfo(Colors.orange.shade800, Icons.local_hospital_outlined,
          t.triageClinic, t.triageClinicDesc);
  }
}

class TriageBadge extends StatelessWidget {
  final String triage;
  final bool compact;
  const TriageBadge({super.key, required this.triage, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final info = triageInfo(context, triage);

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: info.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(info.icon, size: 14, color: info.color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(info.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: info.color, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ]),
      );
    }

    final isEmergency = triage == 'emergency';
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: isEmergency ? 0.10 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: info.color.withValues(alpha: 0.4)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, color: info.color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: info.color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(info.icon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(info.label,
                              style: TextStyle(
                                  color: info.color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(info.description,
                              style: const TextStyle(fontSize: 13, height: 1.35)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}