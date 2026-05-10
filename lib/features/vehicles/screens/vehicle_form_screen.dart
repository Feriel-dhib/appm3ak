import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../data/models/accessibilite.dart';
import '../../../../data/models/vehicle.dart';
import '../../../../data/models/vehicle_statut.dart';
import '../../../../providers/auth_providers.dart';
import '../../../../providers/api_providers.dart';
import '../../../../providers/vehicle_providers.dart';
import '../widgets/equipment_card.dart';

/// Écran de formulaire pour créer ou modifier un véhicule.
class VehicleFormScreen extends ConsumerStatefulWidget {
  const VehicleFormScreen({
    super.key,
    this.vehicleId,
  });

  final String? vehicleId;

  bool get isEditMode => vehicleId != null;

  @override
  ConsumerState<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends ConsumerState<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _marqueController;
  late TextEditingController _modeleController;
  late TextEditingController _immatriculationController;
  late Accessibilite _accessibilite;
  bool _isLoading = false;
  File? _selectedPhoto;
  String? _immatriculationError;

  @override
  void initState() {
    super.initState();
    _marqueController = TextEditingController();
    _modeleController = TextEditingController();
    _immatriculationController = TextEditingController();
    _accessibilite = const Accessibilite();
  }

  @override
  void dispose() {
    _marqueController.dispose();
    _modeleController.dispose();
    _immatriculationController.dispose();
    super.dispose();
  }

  /// Valide le format d'immatriculation tunisienne (ex: 123 TUN 4567 ou 123TUN4567).
  bool _validateImmatriculation(String value) {
    if (value.trim().isEmpty) return false;
    
    // Format tunisien : 3-4 chiffres + TUN + 4 chiffres
    // Exemples: "123 TUN 4567", "123TUN4567", "1234 TUN 5678"
    final pattern = RegExp(r'^\d{3,4}\s*TUN\s*\d{4}$', caseSensitive: false);
    return pattern.hasMatch(value.trim().replaceAll(' ', ''));
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    
    if (image != null) {
      final file = File(image.path);
      final sizeInMB = await file.length() / (1024 * 1024);
      
      if (sizeInMB > 10) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.fr().isAr
                    ? 'حجم الملف كبير جداً (الحد الأقصى 10MB)'
                    : 'Fichier trop volumineux (maximum 10MB)',
              ),
            ),
          );
        }
        return;
      }
      
      setState(() => _selectedPhoto = file);
    }
  }

  Future<void> _save() async {
    // Réinitialiser l'erreur d'immatriculation
    setState(() => _immatriculationError = null);
    
    if (!_formKey.currentState!.validate()) return;

    // Valider le format d'immatriculation
    final immatriculation = _immatriculationController.text.trim();
    if (!_validateImmatriculation(immatriculation)) {
      setState(() {
        _immatriculationError = AppStrings.fr().invalidImmatriculationFormat;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      final repository = ref.read(vehicleRepositoryProvider);
      final marque = _marqueController.text.trim();
      final modele = _modeleController.text.trim();
      
      if (marque.isEmpty) {
        throw Exception(AppStrings.fromPreferredLanguage(user.preferredLanguage?.name).requiredField);
      }

      // TODO: Upload photo si _selectedPhoto != null
      // Pour l'instant, on garde photos vide
      final photos = <String>[];

      if (widget.isEditMode) {
        // Mise à jour
        final updateData = <String, dynamic>{
          'marque': marque,
          'modele': modele,
          'immatriculation': immatriculation,
          'accessibilite': _accessibilite.toJson(),
          'photos': photos,
        };
        await repository.update(widget.vehicleId!, updateData);
      } else {
        // Création
        await repository.create(
          Vehicle(
            id: '',
            ownerId: user.id,
            marque: marque,
            modele: modele,
            immatriculation: immatriculation,
            accessibilite: _accessibilite,
            photos: photos,
            statut: VehicleStatut.enAttente,
          ),
        );
      }

      if (mounted) {
        final strings = AppStrings.fromPreferredLanguage(user.preferredLanguage?.name);
        
        // Invalider les providers pour rafraîchir les données
        ref.invalidate(myVehiclesProvider(user.id));
        if (widget.isEditMode) {
          ref.invalidate(vehicleProvider(widget.vehicleId!));
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditMode
                  ? strings.vehicleUpdated
                  : strings.vehicleCreated,
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final strings = AppStrings.fromPreferredLanguage(user.preferredLanguage?.name);
    final isAr = strings.isAr;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    // Charger le véhicule si en mode édition
    if (widget.isEditMode) {
      final vehicleAsync = ref.watch(vehicleProvider(widget.vehicleId!));
      vehicleAsync.whenData((vehicle) {
        if (_marqueController.text.isEmpty) {
          _marqueController.text = vehicle.marque;
          _modeleController.text = vehicle.modele;
          _immatriculationController.text = vehicle.immatriculation;
          _accessibilite = vehicle.accessibilite;
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(isAr ? Icons.arrow_forward : Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(strings.vehicles),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre principal
              Text(
                strings.vehicleDetailsTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                strings.vehicleDetailsDescription,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              
              // Section Photo
              Text(
                strings.vehiclePhoto,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickPhoto,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: primary,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _selectedPhoto != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            _selectedPhoto!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 48,
                              color: primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              strings.addPhoto,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              strings.photoFormats,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Champ Marque
              TextFormField(
                controller: _marqueController,
                decoration: InputDecoration(
                  labelText: strings.marque,
                  hintText: strings.isAr ? 'مثال: فولكس فاجن' : 'Ex: Volkswagen',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return strings.requiredField;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Champ Modèle
              TextFormField(
                controller: _modeleController,
                decoration: InputDecoration(
                  labelText: strings.modele,
                  hintText: strings.isAr ? 'مثال: كادي' : 'Ex: Caddy',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return strings.requiredField;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Champ Immatriculation
              TextFormField(
                controller: _immatriculationController,
                decoration: InputDecoration(
                  labelText: strings.immatriculation,
                  hintText: 'Ex: 123 TUN 4567',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _immatriculationError != null
                          ? theme.colorScheme.error
                          : Colors.grey.shade300,
                    ),
                  ),
                  errorText: _immatriculationError,
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return strings.requiredField;
                  }
                  if (!_validateImmatriculation(value)) {
                    return strings.invalidImmatriculationFormat;
                  }
                  return null;
                },
              ),
              if (_immatriculationError != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _immatriculationError!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              
              // Section Équipements spécialisés
              Text(
                strings.specializedEquipment,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              
              // Rampe d'accès
              EquipmentCard(
                title: strings.rampeAcces,
                description: strings.rampeAccesDescription,
                isSelected: _accessibilite.rampeAcces,
                onTap: () {
                  setState(() {
                    _accessibilite = _accessibilite.copyWith(
                      rampeAcces: !_accessibilite.rampeAcces,
                    );
                  });
                },
              ),
              const SizedBox(height: 12),
              
              // Siège pivotant
              EquipmentCard(
                title: strings.siegePivotant,
                description: strings.siegePivotantDescription,
                isSelected: _accessibilite.siegePivotant,
                onTap: () {
                  setState(() {
                    _accessibilite = _accessibilite.copyWith(
                      siegePivotant: !_accessibilite.siegePivotant,
                    );
                  });
                },
              ),
              const SizedBox(height: 12),
              
              // Espace fauteuil roulant (mappé sur coffreVaste du backend)
              EquipmentCard(
                title: strings.espaceFauteuilRoulant,
                description: strings.espaceFauteuilRoulantDescription,
                isSelected: _accessibilite.coffreVaste,
                onTap: () {
                  setState(() {
                    _accessibilite = _accessibilite.copyWith(
                      coffreVaste: !_accessibilite.coffreVaste,
                    );
                  });
                },
              ),
              const SizedBox(height: 12),
              
              // Commandes au volant (mappé sur climatisation du backend)
              // Note: Ce champ de l'UX est mappé sur climatisation car il n'existe pas dans le backend
              EquipmentCard(
                title: strings.commandesVolant,
                description: strings.commandesVolantDescription,
                isSelected: _accessibilite.climatisation,
                onTap: () {
                  setState(() {
                    _accessibilite = _accessibilite.copyWith(
                      climatisation: !_accessibilite.climatisation,
                    );
                  });
                },
              ),
              const SizedBox(height: 12),
              
              // Animal accepté (champ backend supplémentaire)
              EquipmentCard(
                title: strings.animalAccepte,
                description: strings.animalAccepteDescription,
                isSelected: _accessibilite.animalAccepte,
                onTap: () {
                  setState(() {
                    _accessibilite = _accessibilite.copyWith(
                      animalAccepte: !_accessibilite.animalAccepte,
                    );
                  });
                },
              ),
              const SizedBox(height: 32),
              
              // Bouton Enregistrer
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          strings.save,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
