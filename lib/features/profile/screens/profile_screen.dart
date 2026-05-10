import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart' as pv;

import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/profile_photo_rules.dart';
import '../../../core/widgets/accessible_button.dart';
import '../../../data/models/type_accompagnant.dart';
import '../../../data/models/type_handicap.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/user_service.dart';
import '../../../providers/api_providers.dart';
import '../../../providers/auth_providers.dart';
import '../widgets/animal_section.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _telephoneController;
  late TextEditingController _besoinSpecifiqueController;
  TypeHandicap? _selectedTypeHandicap;
  late TextEditingController _specialisationController;
  TypeAccompagnant? _selectedTypeAccompagnant;
  PreferredLanguage? _preferredLanguage;
  bool _disponible = false;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).valueOrNull;
    _nomController = TextEditingController(text: user?.nom ?? '');
    _prenomController = TextEditingController(text: user?.prenom ?? '');
    _telephoneController = TextEditingController(text: user?.telephone ?? '');
    _selectedTypeHandicap = TypeHandicap.fromBackendValue(user?.typeHandicap);
    _besoinSpecifiqueController = TextEditingController(text: user?.besoinSpecifique ?? '');
    _selectedTypeAccompagnant = user?.isCompanion == true
        ? TypeAccompagnant.chauffeursSolidaires
        : TypeAccompagnant.fromBackendValue(user?.typeAccompagnant);
    _specialisationController = TextEditingController(text: user?.specialisation ?? '');
    _preferredLanguage = user?.preferredLanguage;
    _disponible = user?.disponible ?? false;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _besoinSpecifiqueController.dispose();
    _specialisationController.dispose();
    super.dispose();
  }

  Future<void> _changePhoto() async {
    final strings = AppStrings.fromPreferredLanguage(
      ref.read(authStateProvider).valueOrNull?.preferredLanguage?.name,
    );
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
    setState(() => _isLoading = true);
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
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _removePhoto() async {
    final strings = AppStrings.fromPreferredLanguage(
      ref.read(authStateProvider).valueOrNull?.preferredLanguage?.name,
    );
    setState(() => _isLoading = true);
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
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final me = ref.read(authStateProvider).valueOrNull;
      final userRepo = ref.read(userRepositoryProvider);
      final user = await userRepo.updateMe(
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        telephone: _telephoneController.text.trim().isEmpty
            ? null
            : _telephoneController.text.trim(),
        typeHandicap: _selectedTypeHandicap?.backendValue,
        besoinSpecifique: _besoinSpecifiqueController.text.trim().isEmpty
            ? null
            : _besoinSpecifiqueController.text.trim(),
        typeAccompagnant: me?.isCompanion == true
            ? TypeAccompagnant.chauffeursSolidaires.backendValue
            : _selectedTypeAccompagnant?.backendValue,
        specialisation: _specialisationController.text.trim().isEmpty
            ? null
            : _specialisationController.text.trim(),
        disponible: _disponible,
        langue: _preferredLanguage?.name ?? 'fr',
      );
      ref.read(authStateProvider.notifier).setUser(user);
      if (mounted) context.pop();
    } catch (_) {}
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final strings = AppStrings.fromPreferredLanguage(user.preferredLanguage?.name);
    final imageUrl = UserRepository.photoUrl(user.photoProfil);

    return Scaffold(
      appBar: AppBar(title: Text(strings.profile)),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _changePhoto,
                            child: Semantics(
                              button: true,
                              label: strings.changePhoto,
                              child: CircleAvatar(
                                radius: 56,
                                backgroundImage: imageUrl.isNotEmpty
                                    ? NetworkImage(imageUrl)
                                    : null,
                                child: imageUrl.isEmpty
                                    ? const Icon(Icons.person, size: 64)
                                    : null,
                              ),
                            ),
                          ),
                          if (user.photoProfil != null &&
                              user.photoProfil!.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _isLoading ? null : _removePhoto,
                              icon: const Icon(Icons.delete_outline, size: 20),
                              label: Text(strings.removeProfilePhoto),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nomController,
                      decoration: const InputDecoration(
                        labelText: 'Nom de famille',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Obligatoire' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _prenomController,
                      decoration: const InputDecoration(
                        labelText: 'Prénom',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Obligatoire' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _telephoneController,
                      decoration: InputDecoration(
                        labelText: strings.phoneNumber,
                        prefixIcon: const Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(strings.preferredLanguage),
                    Row(
                      children: [
                        Radio<PreferredLanguage?>(
                          value: PreferredLanguage.fr,
                          groupValue: _preferredLanguage,
                          onChanged: (v) =>
                              setState(() => _preferredLanguage = v),
                        ),
                        const Text('Français'),
                        Radio<PreferredLanguage?>(
                          value: PreferredLanguage.en,
                          groupValue: _preferredLanguage,
                          onChanged: (v) =>
                              setState(() => _preferredLanguage = v),
                        ),
                        Text(strings.englishLanguage),
                        Radio<PreferredLanguage?>(
                          value: PreferredLanguage.ar,
                          groupValue: _preferredLanguage,
                          onChanged: (v) =>
                              setState(() => _preferredLanguage = v),
                        ),
                        const Text('العربية'),
                      ],
                    ),
                    if (user.isBeneficiary) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<TypeHandicap>(
                        value: _selectedTypeHandicap,
                        decoration: const InputDecoration(
                          labelText: 'Type de handicap',
                          prefixIcon: Icon(Icons.accessible),
                        ),
                        items: TypeHandicap.values
                            .map((TypeHandicap t) =>
                                DropdownMenuItem<TypeHandicap>(
                                  value: t,
                                  child: Text(
                                    strings.typeHandicapLabel(
                                      t.backendValue,
                                    ),
                                  ),
                                ))
                            .toList(),
                        onChanged: (TypeHandicap? v) {
                          setState(() => _selectedTypeHandicap = v);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _besoinSpecifiqueController,
                        decoration: const InputDecoration(
                          labelText: 'Besoins spécifiques',
                          prefixIcon: Icon(Icons.health_and_safety_outlined),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),
                      pv.ChangeNotifierProvider<AnimalAssistanceController>(
                        key: ValueKey<String>(
                          '${user.id}_${user.animalAssistance}_${user.animalName}_${user.animalType}',
                        ),
                        create: (_) => AnimalAssistanceController(
                          userService: UserService(
                            apiClient: ref.read(apiClientProvider),
                          ),
                          initialUser: user,
                        ),
                        child: AnimalSection(
                          saveLabel: strings.save,
                          successMessage: 'Animal d’assistance enregistré.',
                          onSaved: (u) =>
                              ref.read(authStateProvider.notifier).setUser(u),
                        ),
                      ),
                    ],
                    if (user.isCompanion) ...[
                      const SizedBox(height: 16),
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Type accompagnant',
                          prefixIcon: Icon(Icons.local_taxi_outlined),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.typeAccompagnantLabel(
                                TypeAccompagnant.chauffeursSolidaires.backendValue,
                              ),
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              strings.companionAccountIsChauffeurSolidaireOnly,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _specialisationController,
                        decoration: const InputDecoration(
                          labelText: 'Spécialisation',
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        value: _disponible,
                        onChanged: (v) =>
                            setState(() => _disponible = v ?? false),
                        title: const Text('Disponible'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                    const SizedBox(height: 32),
                    AccessibleButton(
                      label: strings.save,
                      onPressed: _isSaving ? null : _save,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading || _isSaving)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black26,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
