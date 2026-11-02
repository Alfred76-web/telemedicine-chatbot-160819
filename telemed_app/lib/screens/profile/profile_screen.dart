import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/locale_provider.dart';
import 'edit_profile_screen.dart';

String genderLabel(AppLocalizations t, String? g) {
  switch (g) {
    case 'male':
      return t.genderMale;
    case 'female':
      return t.genderFemale;
    case 'other':
      return t.genderOther;
    default:
      return t.notSet;
  }
}

int? ageFromDob(String? dob) {
  final date = dob == null ? null : DateTime.tryParse(dob);
  if (date == null) return null;
  final now = DateTime.now();
  var age = now.year - date.year;
  if (now.month < date.month || (now.month == date.month && now.day < date.day)) age--;
  return age;
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.logout),
        title: Text(t.logoutConfirmTitle),
        content: Text(t.logoutConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.logout)),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<AuthProvider>().logout();
    }
  }

  Future<void> _changeLanguage(BuildContext context, String code) async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.updateLanguage(code);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(auth.error ?? 'Error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    final history = context.watch<HistoryProvider>();
    final currentLang = context.watch<LocaleProvider>().code;
    final locale = Localizations.localeOf(context).languageCode;

    final age = ageFromDob(user.dateOfBirth);
    final dob = DateTime.tryParse(user.dateOfBirth ?? '');
    final dobText = dob != null ? DateFormat.yMMMMd(locale).format(dob) : t.notSet;
    final lastVisit = history.records.isNotEmpty
        ? DateFormat.MMMd(locale).format(history.records.first.createdAt)
        : '–';
    final conditions = (user.chronicConditions ?? '')
        .split(RegExp(r'[,;\n]'))
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Header + floating stats card ─────────────────────────────
          Stack(
            clipBehavior: Clip.none,
            children: [
              _Header(
                initials: _initials(user.name),
                name: user.name,
                email: user.email,
                title: t.navProfile,
                editTooltip: t.editProfile,
                chips: [
                  _HeaderChip(
                      icon: Icons.translate,
                      label: user.languagePref == 'sw' ? 'Kiswahili' : 'English'),
                  if (user.phone != null) _HeaderChip(icon: Icons.phone, label: user.phone!),
                ],
                onEdit: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: -44,
                child: _StatsCard(stats: [
                  _Stat(Icons.forum_outlined, '${history.records.length}', t.statConsultations),
                  _Stat(Icons.cake_outlined, age?.toString() ?? '–', t.statAge),
                  _Stat(Icons.event_outlined, lastVisit, t.statLastVisit),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 64),

          // ── Personal information ─────────────────────────────────────
          _SectionTitle(
            title: t.personalInfo,
            trailing: TextButton.icon(
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(t.editProfile),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              ),
            ),
          ),
          _RoundedCard(
            child: Column(
              children: [
                _InfoRow(
                    icon: Icons.phone_outlined,
                    color: Colors.blue,
                    label: t.phone,
                    value: user.phone ?? t.notSet),
                const Divider(height: 1, indent: 72),
                _InfoRow(
                    icon: Icons.cake_outlined,
                    color: Colors.pink,
                    label: t.dateOfBirth,
                    value: dobText),
                const Divider(height: 1, indent: 72),
                _InfoRow(
                    icon: Icons.wc,
                    color: Colors.purple,
                    label: t.gender,
                    value: genderLabel(t, user.gender)),
              ],
            ),
          ),

          // ── Health ───────────────────────────────────────────────────
          _SectionTitle(title: t.chronicConditions),
          _RoundedCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (conditions.isEmpty)
                    Row(children: [
                      Icon(Icons.medical_information_outlined, color: scheme.outline),
                      const SizedBox(width: 12),
                      Text(t.notSet, style: TextStyle(color: scheme.onSurfaceVariant)),
                    ])
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: conditions
                          .map((c) => Chip(
                                avatar: Icon(Icons.healing, size: 16, color: Colors.red.shade700),
                                label: Text(c),
                                backgroundColor: Colors.red.withValues(alpha: 0.08),
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                              ))
                          .toList(),
                    ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline, size: 20, color: Colors.amber.shade800),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(t.profileContextNote,
                              style: theme.textTheme.bodySmall),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Settings ─────────────────────────────────────────────────
          _SectionTitle(title: t.settings),
          _RoundedCard(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const _IconBox(icon: Icons.translate, color: Colors.teal),
                        const SizedBox(width: 16),
                        Text(t.language, style: theme.textTheme.titleSmall),
                      ]),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'en', label: Text('English')),
                            ButtonSegment(value: 'sw', label: Text('Kiswahili')),
                          ],
                          selected: {currentLang},
                          showSelectedIcon: false,
                          onSelectionChanged: (s) => _changeLanguage(context, s.first),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: const _IconBox(icon: Icons.logout, color: Colors.red),
                  title: Text(t.logout,
                      style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600)),
                  trailing: Icon(Icons.chevron_right, color: scheme.outline),
                  onTap: () => _confirmLogout(context),
                ),
              ],
            ),
          ),

          // ── Footer ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
            child: Column(children: [
              Icon(Icons.health_and_safety, color: scheme.outline),
              const SizedBox(height: 4),
              Text('${t.appTitle} · v1.0',
                  style: theme.textTheme.labelSmall?.copyWith(color: scheme.outline)),
              const SizedBox(height: 4),
              Text(t.disclaimer,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(color: scheme.outline)),
            ]),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════ Building blocks ═══════════════════════

class _Header extends StatelessWidget {
  final String initials, name, email, title, editTooltip;
  final List<Widget> chips;
  final VoidCallback onEdit;
  const _Header({
    required this.initials,
    required this.name,
    required this.email,
    required this.title,
    required this.editTooltip,
    required this.chips,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 8, 8, 68),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, Color.lerp(primary, Colors.black, 0.35)!],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Row(children: [
            Text(title,
                style: theme.textTheme.titleLarge
                    ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
              tooltip: editTooltip,
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
            ),
          ]),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.25),
            ),
            child: CircleAvatar(
              radius: 44,
              backgroundColor: Colors.white,
              child: Text(initials,
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(color: primary, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          Text(name,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(email,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.white.withValues(alpha: 0.8))),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: chips),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeaderChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ]),
    );
  }
}

class _Stat {
  final IconData icon;
  final String value, label;
  const _Stat(this.icon, this.value, this.label);
}

class _StatsCard extends StatelessWidget {
  final List<_Stat> stats;
  const _StatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final children = <Widget>[];
    for (var i = 0; i < stats.length; i++) {
      if (i > 0) {
        children.add(const VerticalDivider(width: 1, indent: 8, endIndent: 8));
      }
      final s = stats[i];
      children.add(Expanded(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(s.icon, size: 22, color: theme.colorScheme.primary),
          const SizedBox(height: 6),
          Text(s.value,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(s.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ]),
      ));
    }

    return Card(
      elevation: 6,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: IntrinsicHeight(child: Row(children: children)),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _SectionTitle({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
      child: Row(children: [
        Expanded(
          child: Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ),
        ?trailing,
      ]),
    );
  }
}

class _RoundedCard extends StatelessWidget {
  final Widget child;
  const _RoundedCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: child,
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  const _InfoRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _IconBox(icon: icon, color: color),
      title: Text(label,
          style: theme.textTheme.labelMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      subtitle: Text(value,
          style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600)),
    );
  }
}