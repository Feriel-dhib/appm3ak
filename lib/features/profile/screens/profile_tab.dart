import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/profile_photo_rules.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../providers/auth_providers.dart';
import '../../../core/widgets/ma3ak_day_night_toggle.dart';
import '../../../providers/theme_provider.dart';

/// Onglet Mon Profil : design maquette (photo, infos, cartes, sécurité, déconnexion).
class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key, this.showLeadingBack = false});

  /// Route `/profile` : bouton retour en haut du contenu.
  final bool showLeadingBack;

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  bool _isLoadingPhoto = false;

  Future<void> _removePhoto(AppStrings strings) async {
    setState(() => _isLoadingPhoto = true);
    try {
      final userRepo = ref.read(userRepositoryProvider);
      final user = await userRepo.deleteProfilePhoto();
      ref.read(authStateProvider.notifier).setUser(user);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.profilePhotoActionFailed)),
        );
      }
    }
    if (mounted) setState(() => _isLoadingPhoto = false);
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, AppStrings strings) {
    final notifier = ref.read(themeModeProvider.notifier);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.theme),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Ma3akDayNightThemeToggle(
                width: (MediaQuery.sizeOf(dialogContext).shortestSide * 0.32)
                    .clamp(112.0, 132.0),
                height: 48,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              strings.themeToggleHint,
              textAlign: TextAlign.center,
              style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                    color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                  ),
            ),
            const Divider(height: 28),
            ListTile(
              leading: Icon(
                Icons.brightness_auto_rounded,
                color: Theme.of(dialogContext).colorScheme.primary,
              ),
              title: Text(strings.themeSystem),
              onTap: () {
                notifier.setThemeMode(ThemeMode.system);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changePhoto(AppStrings strings) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 92,
    );
    if (x == null) return;
    final file = File(x.path);
    if (!isProfilePhotoFileAllowed(file)) {
      if (!mounted) return;
      final msg = file.lengthSync() > kProfilePhotoMaxBytes
          ? strings.profilePhotoTooLarge
          : strings.profilePhotoInvalidType;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }
    setState(() => _isLoadingPhoto = true);
    try {
      final userRepo = ref.read(userRepositoryProvider);
      final user = await userRepo.updateProfilePhoto(file);
      ref.read(authStateProvider.notifier).setUser(user);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.profilePhotoActionFailed)),
        );
      }
    }
    if (mounted) setState(() => _isLoadingPhoto = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final strings =
        AppStrings.fromPreferredLanguage(user.preferredLanguage?.name);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final imageUrl = UserRepository.photoUrl(user.photoProfil);

    String memberSince = strings.memberSince;
    if (user.createdAt != null) {
      const months = [
        'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
        'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
      ];
      final m = user.createdAt!.month;
      final y = user.createdAt!.year;
      memberSince = '${strings.memberSince} ${months[m - 1]} $y';
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
              child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  if (widget.showLeadingBack) ...[
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: IconButton(
                        tooltip: MaterialLocalizations.of(context)
                            .backButtonTooltip,
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/home');
                          }
                        },
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  // Titre
                  Text(
                    strings.myProfile,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Photo + nom + badge + date
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            GestureDetector(
                              onTap: () => _changePhoto(strings),
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.orange.shade100,
                                  border: Border.all(
                                    color: primary.withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                ),
                                child: _isLoadingPhoto
                                    ? const Padding(
                                        padding: EdgeInsets.all(32),
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : imageUrl.isNotEmpty
                                        ? ClipOval(
                                            child: Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              width: 120,
                                              height: 120,
                                            ),
                                          )
                                        : Icon(
                                            Icons.person,
                                            size: 64,
                                            color: Colors.orange.shade700,
                                          ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: GestureDetector(
                                onTap: () => _changePhoto(strings),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (user.photoProfil != null &&
                            user.photoProfil!.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed:
                                _isLoadingPhoto ? null : () => _removePhoto(strings),
                            icon: const Icon(Icons.delete_outline, size: 20),
                            label: Text(strings.removeProfilePhoto),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          user.displayName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, size: 18, color: primary),
                              const SizedBox(width: 6),
                              Text(
                                strings.verifiedUser,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          memberSince,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Cartes stats
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: '12',
                          label: strings.assistedTrips,
                          primary: primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          value: '4.9',
                          label: strings.communityRating,
                          primary: primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // INFORMATIONS PERSONNELLES
                  Text(
                    strings.personalInfo,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoTile(
                    icon: Icons.email_outlined,
                    iconBg: primary.withValues(alpha: 0.12),
                    label: 'E-mail',
                    value: user.email,
                    onTap: () => context.push('/profile-edit'),
                  ),
                  const SizedBox(height: 8),
                  _InfoTile(
                    icon: Icons.phone_outlined,
                    iconBg: primary.withValues(alpha: 0.12),
                    label: strings.phoneNumber,
                    value: user.contact,
                    onTap: () => context.push('/profile-edit'),
                  ),
                  const SizedBox(height: 24),
                  // SÉCURITÉ ET SUPPORT
                  Text(
                    strings.securitySupport,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoTile(
                    icon: Icons.dark_mode_outlined,
                    iconBg: primary.withValues(alpha: 0.12),
                    label: strings.theme,
                    onTap: () => _showThemeDialog(context, ref, strings),
                  ),
                  const SizedBox(height: 8),
                  if (!user.isChauffeurSolidaire) ...[
                    _InfoTile(
                      icon: Icons.closed_caption_outlined,
                      iconBg: primary.withValues(alpha: 0.12),
                      label: strings.conversationCaptionsMenu,
                      onTap: () =>
                          context.push('/accessibility/conversation-captions'),
                    ),
                    const SizedBox(height: 8),
                    _InfoTile(
                      icon: Icons.emergency_outlined,
                      iconBg: Colors.red.withValues(alpha: 0.12),
                      label: strings.emergencyContacts,
                      onTap: () => context.push('/accompagnants'),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (user.isBeneficiary) ...[
                    _InfoTile(
                      icon: Icons.medical_services_outlined,
                      iconBg: primary.withValues(alpha: 0.12),
                      label: strings.medicalRecordMenu,
                      onTap: () => context.push('/medical-record'),
                    ),
                    const SizedBox(height: 8),
                    _InfoTile(
                      icon: Icons.people_outlined,
                      iconBg: primary.withValues(alpha: 0.12),
                      label: strings.myAccompagnants,
                      onTap: () => context.push('/relations/accompagnants'),
                    ),
                  ],
                  if (user.isCompanion && !user.isChauffeurSolidaire)
                    _InfoTile(
                      icon: Icons.accessible_outlined,
                      iconBg: primary.withValues(alpha: 0.12),
                      label: strings.myHandicapes,
                      onTap: () => context.push('/relations/handicapes'),
                    ),
                  const SizedBox(height: 8),
                  _InfoTile(
                    icon: Icons.notifications_outlined,
                    iconBg: primary.withValues(alpha: 0.12),
                    label: 'Notifications',
                    onTap: () => context.push('/notifications'),
                  ),
                  if ((user.isBeneficiary || user.isCompanion) &&
                      !user.isChauffeurSolidaire) ...[
                    const SizedBox(height: 8),
                    _InfoTile(
                      icon: Icons.calendar_today_outlined,
                      iconBg: primary.withValues(alpha: 0.12),
                      label: strings.myVehicleReservations,
                      onTap: () => context.push('/vehicle-reservations'),
                    ),
                  ],
                  if (!user.isChauffeurSolidaire) ...[
                    const SizedBox(height: 8),
                    _InfoTile(
                      icon: Icons.history,
                      iconBg: primary.withValues(alpha: 0.12),
                      label: strings.assistanceHistory,
                      onTap: () {},
                    ),
                  ],
                  const SizedBox(height: 8),
                  _InfoTile(
                    icon: Icons.settings_outlined,
                    iconBg: primary.withValues(alpha: 0.12),
                    label: strings.settings,
                    onTap: () => context.push('/profile-edit'),
                  ),
                  const SizedBox(height: 24),
                  // Déconnexion
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ref.read(authStateProvider.notifier).logout();
                        if (context.mounted) context.go('/welcome');
                      },
                      icon: const Icon(Icons.logout, size: 22),
                      label: Text(
                        strings.logout,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'MA3AK V2.4.0 (TUNISIE)',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.primary,
  });

  final String value;
  final String label;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.iconBg,
    required this.label,
    this.value,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semanticLabel =
        value != null && value!.isNotEmpty ? '$label, $value' : label;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          excludeFromSemantics: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 22, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (value != null && value!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          value!,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
