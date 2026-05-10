import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/accessible_button.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/user_service.dart';

/// Types d’animal attendus par l’API (`animalType`).
const String kAnimalTypeChien = 'chien';
const String kAnimalTypeAutre = 'autre';

/// **Exemple d’usage** (avec [ChangeNotifierProvider]) :
///
/// ```dart
/// ChangeNotifierProvider(
///   create: (_) => AnimalAssistanceController(
///     userService: UserService(apiClient: ref.read(apiClientProvider)),
///     initialUser: user,
///   ),
///   child: AnimalSection(
///     saveLabel: strings.save,
///     onSaved: (u) => ref.read(authStateProvider.notifier).setUser(u),
///   ),
/// )
/// ```
class AnimalAssistanceController extends ChangeNotifier {
  AnimalAssistanceController({
    required this.userService,
    required UserModel initialUser,
  })  : _nameController = TextEditingController(),
        _notesController = TextEditingController() {
    _nameController.addListener(_emit);
    _notesController.addListener(_emit);
    applyFromUser(initialUser);
  }

  final UserService userService;
  final TextEditingController _nameController;
  final TextEditingController _notesController;

  TextEditingController get nameController => _nameController;
  TextEditingController get notesController => _notesController;

  bool _assistance = false;
  String _type = kAnimalTypeChien;
  bool _loading = false;

  bool get animalAssistance => _assistance;
  String get animalType => _type;
  bool get isLoading => _loading;

  void _emit() => notifyListeners();

  void applyFromUser(UserModel u) {
    _assistance = u.animalAssistance;
    final t = u.animalType?.trim().toLowerCase();
    if (t == kAnimalTypeChien) {
      _type = kAnimalTypeChien;
    } else if (t == kAnimalTypeAutre) {
      _type = kAnimalTypeAutre;
    } else {
      _type = kAnimalTypeChien;
    }
    _nameController.text = u.animalName ?? '';
    _notesController.text = u.animalNotes ?? '';
    notifyListeners();
  }

  void setAnimalAssistance(bool value) {
    if (_assistance == value) return;
    _assistance = value;
    if (!_assistance) {
      _type = kAnimalTypeChien;
      _nameController.clear();
      _notesController.clear();
    }
    notifyListeners();
  }

  void setAnimalType(String value) {
    if (_type == value) return;
    _type = value;
    notifyListeners();
  }

  /// Bouton Enregistrer actif si l’état est cohérent (hors chargement).
  bool get canSubmit {
    if (_loading) return false;
    if (!_assistance) return true;
    return _nameController.text.trim().isNotEmpty &&
        (_type == kAnimalTypeChien || _type == kAnimalTypeAutre);
  }

  Future<UserModel?> persist() async {
    _loading = true;
    notifyListeners();
    try {
      final name = _nameController.text.trim();
      final notes = _notesController.text.trim();
      final user = await userService.updateAnimalAssistance(
        animalAssistance: _assistance,
        animalType: _assistance ? _type : null,
        animalName: _assistance ? name : null,
        animalNotes: _assistance ? (notes.isEmpty ? '' : notes) : null,
      );
      applyFromUser(user);
      return user;
    } catch (_) {
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_emit);
    _notesController.removeListener(_emit);
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

/// Bloc profil : animal d’assistance (switch, champs conditionnels, enregistrement dédié).
class AnimalSection extends StatefulWidget {
  const AnimalSection({
    super.key,
    required this.saveLabel,
    required this.onSaved,
    this.successMessage = 'Informations enregistrées.',
    this.errorMessage = 'Enregistrement impossible. Réessayez.',
  });

  final String saveLabel;
  final void Function(UserModel user) onSaved;
  final String successMessage;
  final String errorMessage;

  @override
  State<AnimalSection> createState() => _AnimalSectionState();
}

class _AnimalSectionState extends State<AnimalSection>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final AnimationController _expandController;
  bool _didInitialExpandSync = false;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _syncAnimation(bool assistance) {
    if (!_didInitialExpandSync) {
      _didInitialExpandSync = true;
      _expandController.value = assistance ? 1.0 : 0.0;
      return;
    }
    if (assistance) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  Future<void> _onSave(BuildContext context) async {
    final ctrl = context.read<AnimalAssistanceController>();
    if (!ctrl.canSubmit) return;
    if (ctrl.animalAssistance) {
      final ok = _formKey.currentState?.validate() ?? false;
      if (!ok) return;
    }
    try {
      final user = await ctrl.persist();
      if (!context.mounted || user == null) return;
      widget.onSaved(user);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.successMessage)),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.errorMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnimalAssistanceController>(
      builder: (context, ctrl, _) {
        _syncAnimation(ctrl.animalAssistance);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Avez-vous un animal d’assistance ?',
                    ),
                    value: ctrl.animalAssistance,
                    onChanged: ctrl.isLoading ? null : ctrl.setAnimalAssistance,
                  ),
                  SizeTransition(
                    sizeFactor: CurvedAnimation(
                      parent: _expandController,
                      curve: Curves.easeOutCubic,
                      reverseCurve: Curves.easeInCubic,
                    ),
                    axisAlignment: -1,
                    child: FadeTransition(
                      opacity: _expandController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: ctrl.animalType,
                            decoration: const InputDecoration(
                              labelText: 'Type',
                              prefixIcon: Icon(Icons.pets_outlined),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: kAnimalTypeChien,
                                child: Text('Chien'),
                              ),
                              DropdownMenuItem(
                                value: kAnimalTypeAutre,
                                child: Text('Autre'),
                              ),
                            ],
                            onChanged: ctrl.isLoading
                                ? null
                                : (v) {
                                    if (v != null) ctrl.setAnimalType(v);
                                  },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: ctrl.nameController,
                            enabled: !ctrl.isLoading,
                            decoration: const InputDecoration(
                              labelText: 'Nom',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            textInputAction: TextInputAction.next,
                            validator: (v) {
                              if (!ctrl.animalAssistance) return null;
                              if (v == null || v.trim().isEmpty) {
                                return 'Le nom est obligatoire';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: ctrl.notesController,
                            enabled: !ctrl.isLoading,
                            decoration: const InputDecoration(
                              labelText: 'Notes',
                              prefixIcon: Icon(Icons.notes_outlined),
                            ),
                            maxLines: 3,
                            textInputAction: TextInputAction.newline,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AccessibleButton(
                    label: widget.saveLabel,
                    onPressed: (!ctrl.canSubmit || ctrl.isLoading)
                        ? null
                        : () => _onSave(context),
                  ),
                ],
              ),
            ),
            if (ctrl.isLoading)
              const Positioned.fill(
                child: AbsorbPointer(
                  child: ColoredBox(
                    color: Color(0x14000000),
                    child: Center(
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
