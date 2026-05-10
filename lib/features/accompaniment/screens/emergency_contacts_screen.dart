import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/emergency_contact_model.dart';
import '../../../data/models/local_trusted_contact.dart';
import '../../../data/repositories/emergency_contacts_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../providers/api_providers.dart';
import '../../../providers/local_trusted_contacts_provider.dart';

/// Contacts d’urgence : **proches sur l’appareil** (nom + téléphone) + compte API (ID).
class EmergencyContactsScreen extends ConsumerStatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  ConsumerState<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState
    extends ConsumerState<EmergencyContactsScreen> {
  List<EmergencyContactModel> _apiContacts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadApi();
  }

  Future<void> _loadApi() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = ref.read(emergencyContactsRepositoryProvider);
      final list = await repo.getMyContacts();
      if (mounted) setState(() => _apiContacts = list);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error =
              'Serveur indisponible ou non connecté. Vous pouvez quand même ajouter des proches sur cet appareil.';
          _apiContacts = [];
        });
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _removeApi(String id) async {
    try {
      final repo = ref.read(emergencyContactsRepositoryProvider);
      await repo.delete(id);
      await _loadApi();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de supprimer (serveur)')),
        );
      }
    }
  }

  void _showAddLocalDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajouter un proche'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enregistré sur cet appareil — utilisé pour les appels / SMS SOS (pas besoin d’ID serveur).',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                hintText: 'Ex. Sami Ben Ali',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                hintText: '+216…',
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              final n = nameCtrl.text.trim();
              final ph = phoneCtrl.text.trim();
              if (n.isEmpty || ph.isEmpty) return;
              await ref.read(localTrustedContactsProvider.notifier).add(
                    displayName: n,
                    phone: ph,
                  );
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Proche enregistré — visible dans SOS intelligent'),
                  ),
                );
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showAddServerIdDialog() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lier un accompagnant (compte Ma3ak)'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'ID utilisateur accompagnant',
            hintText: 'Identifiant fourni par l’admin / l’API',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              final id = controller.text.trim();
              if (id.isEmpty) return;
              Navigator.pop(ctx);
              try {
                final repo = ref.read(emergencyContactsRepositoryProvider);
                await repo.add(accompagnantId: id);
                await _loadApi();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contact serveur ajouté')),
                  );
                }
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Échec : vérifiez l’ID ou la connexion au serveur.',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _showLinkByPhoneDialog() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lier un accompagnant par telephone'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Telephone',
            hintText: '+21655000001',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              final telephone = controller.text.trim();
              if (telephone.isEmpty) return;
              Navigator.pop(ctx);
              try {
                final repo = ref.read(emergencyContactsRepositoryProvider);
                final normalized = EmergencyContactsRepository.normalizePhoneForLink(
                  telephone,
                );
                await repo.linkByPhone(normalized);
                await _loadApi();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Contact lie avec succes via numero de telephone ($normalized).',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().replaceFirst('Exception: ', ''),
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Lier'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localList = ref.watch(localTrustedContactsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts d\'urgence'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadApi,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddLocalDialog,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Proche (téléphone)'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _loadApi();
                await ref.read(localTrustedContactsProvider.notifier).refresh();
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  if (_error != null)
                    Card(
                      color: Colors.amber.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.amber.shade900),
                            const SizedBox(width: 12),
                            Expanded(child: Text(_error!)),
                          ],
                        ),
                      ),
                    ),
                  Text(
                    'Sur cet appareil',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Utilisés en priorité pour « SOS intelligent » (appel + SMS + position).',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  if (localList.isEmpty)
                    OutlinedButton.icon(
                      onPressed: _showAddLocalDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter un proche avec son numéro'),
                    )
                  else
                    ...localList.map((e) => _LocalContactTile(
                          contact: e,
                          onDelete: () async {
                            await ref
                                .read(localTrustedContactsProvider.notifier)
                                .remove(e.id);
                          },
                        )),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Compte Ma3ak (serveur)',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showAddServerIdDialog,
                        icon: const Icon(Icons.link, size: 18),
                        label: const Text('ID'),
                      ),
                      TextButton.icon(
                        onPressed: _showLinkByPhoneDialog,
                        icon: const Icon(Icons.phone, size: 18),
                        label: const Text('Telephone'),
                      ),
                    ],
                  ),
                  Text(
                    'Vous pouvez lier via ID ou numero de telephone d\'un accompagnant existant.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  if (_apiContacts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Aucun contact synchronisé.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    )
                  else
                    ..._apiContacts.map(
                      (c) {
                        final u = c.accompagnant;
                        final photo = UserRepository.photoUrl(u?.photoProfil);
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage:
                                  photo.isNotEmpty ? NetworkImage(photo) : null,
                              child: photo.isEmpty
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(
                              u?.displayName ?? 'Contact #${c.ordrePriorite}',
                            ),
                            subtitle: Text(u?.contact ?? c.accompagnantId),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => _removeApi(c.id),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}

class _LocalContactTile extends StatelessWidget {
  const _LocalContactTile({
    required this.contact,
    required this.onDelete,
  });

  final LocalTrustedContact contact;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.phone_in_talk,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(contact.displayName),
        subtitle: Text(contact.phone),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Retirer ce proche ?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Annuler'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Retirer'),
                  ),
                ],
              ),
            );
            if (ok == true) onDelete();
          },
        ),
      ),
    );
  }
}
