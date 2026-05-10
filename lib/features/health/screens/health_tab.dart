import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../providers/auth_providers.dart';
import '../models/health_chat_launch.dart';

/// Onglet Santé humaine : SOS Médical, Mes Rendez-vous (calendrier + fiche), Rappels médicaux, Pas/Sommeil.
class HealthTab extends ConsumerStatefulWidget {
  const HealthTab({super.key});

  @override
  ConsumerState<HealthTab> createState() => _HealthTabState();
}

class _HealthTabState extends ConsumerState<HealthTab> {
  static const Color _teal = Color(0xFF00897B);

  DateTime _selectedDate = DateTime(2023, 10, 5);
  late List<_ReminderItem> _reminders;

  @override
  void initState() {
    super.initState();
    _reminders = [
      _ReminderItem(
        id: '1',
        title: 'Insuline',
        subtitle: '08:00 - Avant repas',
        icon: Icons.medication_outlined,
        iconColor: Colors.orange,
        enabled: true,
      ),
      _ReminderItem(
        id: '2',
        title: 'Contrôle Glycémie',
        subtitle: '12:00 - Quotidien',
        icon: Icons.medical_services_outlined,
        iconColor: const Color(0xFF1976D2),
        enabled: false,
      ),
      _ReminderItem(
        id: '3',
        title: 'Hydratation',
        subtitle: 'Toutes les 2 heures',
        icon: Icons.water_drop_outlined,
        iconColor: Colors.green,
        enabled: true,
      ),
    ];
  }

  void _toggleReminder(int index) {
    setState(() {
      _reminders[index] = _reminders[index].copyWith(
        enabled: !_reminders[index].enabled,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final strings = user != null
        ? AppStrings.fromPreferredLanguage(user.preferredLanguage?.name)
        : AppStrings.fr();
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: user != null
          ? FloatingActionButton.extended(
              heroTag: 'health_ai_fab',
              icon: const Icon(Icons.record_voice_over_rounded, size: 26),
              label: Text(
                strings.healthFabChat,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              tooltip: strings.healthOpenChat,
              onPressed: () => context.push(
                    '/health-chat',
                    extra: HealthChatLaunch(user: user),
                  ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildHeader(context, strings, primary),
            SliverToBoxAdapter(child: _buildSosCard(context, strings)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _buildSmartSecurityCard(context, strings),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: _buildSectionHeader(
                  strings.myAppointments,
                  strings.seeAll,
                  primary,
                  onSeeAll: () {},
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildCalendar(strings, primary)),
            SliverToBoxAdapter(child: _buildAppointmentCard(primary)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: _buildSectionHeader(
                  strings.reminders,
                  strings.add,
                  primary,
                  onSeeAll: () {},
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildRemindersList(strings, primary)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Row(
                  children: [
                    Expanded(child: _buildStatCard(strings.stepsToday, '4 231', Icons.directions_walk, Colors.grey)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard(strings.sleep, '7h 20', Icons.nightlight_round, theme.colorScheme.primary)),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 88)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppStrings strings, Color primary) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () => context.push('/profile'),
              color: Colors.black87,
            ),
            Expanded(
              child: Text(
                strings.health,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () => context.push('/notifications'),
              color: Colors.black87,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSosCard(BuildContext context, AppStrings strings) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: _teal,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/sos-medical'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'SOS',
                    style: TextStyle(
                      color: _teal,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.sosMedical,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strings.sosMedicalSubtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Accès visible à l’écran **SOS & sécurité intelligente** (fusion + matching).
  Widget _buildSmartSecurityCard(BuildContext context, AppStrings strings) {
    const indigo = Color(0xFF3949AB);
    return Material(
      color: indigo,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/sos-alerts'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.hub_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.healthSmartSosTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.healthSmartSosSubtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.92),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String actionLabel,
    Color actionColor, {
    VoidCallback? onSeeAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: Text(
            actionLabel,
            style: TextStyle(
              fontSize: 14,
              color: actionColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  static final List<String> _weekDays = ['LUN', 'MAR', 'MER', 'JEU', 'VEN', 'SAM', 'DIM'];
  static const List<String> _months = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
  ];

  Widget _buildCalendar(AppStrings strings, Color primary) {
    final monthStart = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final firstWeekday = monthStart.weekday; // 1 = Monday
    final leadingEmpty = firstWeekday - 1;
    final firstDay = monthStart.subtract(Duration(days: leadingEmpty));
    final daysToShow = 7;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(
                      _selectedDate.year,
                      _selectedDate.month - 1,
                      _selectedDate.day.clamp(1, 28),
                    );
                  });
                },
              ),
              Text(
                '${_months[_selectedDate.month - 1]} ${_selectedDate.year}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(
                      _selectedDate.year,
                      _selectedDate.month + 1,
                      _selectedDate.day.clamp(1, 28),
                    );
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) => SizedBox(
              width: 36,
              child: Text(
                _weekDays[i],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(daysToShow, (col) {
              final dayDate = firstDay.add(Duration(days: col));
              final isSelected = dayDate.year == _selectedDate.year &&
                  dayDate.month == _selectedDate.month &&
                  dayDate.day == _selectedDate.day;
              final hasDot = dayDate.month == _selectedDate.month && dayDate.day == 6;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDate = dayDate),
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSelected ? primary : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${dayDate.day}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      if (hasDot)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1976D2),
                            shape: BoxShape.circle,
                          ),
                        )
                      else
                        const SizedBox(height: 10),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Color primary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AUJOURD\'HUI • 14:30',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Dr. Amine - Cardiologue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Clinique El Amen, Tunis',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const Spacer(),
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, size: 32, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindersList(AppStrings strings, Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(_reminders.length, (i) {
          final r = _reminders[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: r.iconColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(r.icon, color: r.iconColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          r.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: r.enabled,
                    onChanged: (_) => _toggleReminder(i),
                    activeColor: primary,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Icon(icon, size: 18, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReminderItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool enabled;

  _ReminderItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.enabled,
  });

  _ReminderItem copyWith({bool? enabled}) {
    return _ReminderItem(
      id: id,
      title: title,
      subtitle: subtitle,
      icon: icon,
      iconColor: iconColor,
      enabled: enabled ?? this.enabled,
    );
  }
}
