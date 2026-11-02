import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/health_record.dart';
import '../../providers/history_provider.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/triage_badge.dart';
import 'consultation_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  static const _order = ['self-care', 'pharmacy', 'clinic', 'emergency'];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final history = context.watch<HistoryProvider>();
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).languageCode;
    final records = history.records;

    final counts = <String, int>{for (final k in _order) k: 0};
    for (final r in records) {
      counts[r.triage] = (counts[r.triage] ?? 0) + 1;
    }

    final children = <Widget>[
      GradientHeader(
        title: t.navHistory,
        subtitle: t.historySubtitle,
        bottom: records.isEmpty
            ? null
            : _SummaryCard(total: records.length, counts: counts, order: _order),
      ),
    ];

    if (history.isLoading && records.isEmpty) {
      children.add(const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(child: CircularProgressIndicator()),
      ));
    } else if (history.hasError && records.isEmpty) {
      children.add(_StateMessage(
        icon: Icons.cloud_off,
        title: t.historyError,
        action: FilledButton.tonal(
          onPressed: () => context.read<HistoryProvider>().load(),
          child: Text(t.retry),
        ),
      ));
    } else if (records.isEmpty) {
      children.add(_StateMessage(
        icon: Icons.history,
        title: t.historyEmpty,
        subtitle: t.historyEmptyBody,
      ));
    } else {
      String? currentMonth;
      for (final r in records) {
        final month = DateFormat.yMMMM(locale).format(r.createdAt);
        if (month != currentMonth) {
          currentMonth = month;
          children.add(_MonthHeader(label: month));
        }
        children.add(_HistoryTile(record: r));
      }
      children.add(const SizedBox(height: 24));
    }

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: RefreshIndicator(
        onRefresh: () => context.read<HistoryProvider>().load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: children,
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int total;
  final Map<String, int> counts;
  final List<String> order;
  const _SummaryCard({required this.total, required this.counts, required this.order});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final present = order.where((k) => (counts[k] ?? 0) > 0).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$total',
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(t.statConsultations,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: present
                    .map((k) => Expanded(
                          flex: counts[k]!,
                          child: Container(color: triageInfo(context, k).color),
                        ))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: present.map((k) {
              final info = triageInfo(context, k);
              return Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: info.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
                const SizedBox(width: 6),
                Text('${info.label} · ${counts[k]}',
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ]);
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final String label;
  const _MonthHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(label.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.outline,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          )),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final HealthRecord record;
  const _HistoryTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final info = triageInfo(context, record.triage);
    final locale = Localizations.localeOf(context).languageCode;
    final time = DateFormat.MMMd(locale).add_jm().format(record.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ConsultationDetailScreen(record: record)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: info.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(info.icon, color: info.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(record.symptoms,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                        ),
                        Icon(Icons.chevron_right, color: scheme.outline),
                      ]),
                      const SizedBox(height: 2),
                      Text(record.advice,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 10),
                      Row(children: [
                        Flexible(child: TriageBadge(triage: record.triage, compact: true)),
                        const SizedBox(width: 8),
                        Icon(Icons.schedule, size: 13, color: scheme.outline),
                        const SizedBox(width: 3),
                        Text(time,
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: scheme.outline)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            border: Border.all(color: scheme.outlineVariant),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(record.language.toUpperCase(),
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: scheme.outline)),
                        ),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  const _StateMessage({required this.icon, required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 60, 32, 32),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary.withValues(alpha: 0.08),
            ),
            child: Icon(icon, size: 44, color: primary),
          ),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ],
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}