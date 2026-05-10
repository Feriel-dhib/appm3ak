import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../data/models/relation_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../providers/api_providers.dart';
import '../../../providers/auth_providers.dart';

/// Écran « Mes accompagnants » (relations handicapé–accompagnant).
/// Liste les liaisons avec statut, permet d'ajouter par ID, accepter ou supprimer.
class MyAccompagnantsRelationsScreen extends ConsumerStatefulWidget {
  const MyAccompagnantsRelationsScreen({super.key});

  @override
  ConsumerState<MyAccompagnantsRelationsScreen> createState() =>
      _MyAccompagnantsRelationsScreenState();
}

class _MyAccompagnantsRelationsScreenState
    extends ConsumerState<MyAccompagnantsRelationsScreen> {
  List<RelationModel> _relations = [];
  bool _isLoading = true;
  String? _error;

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = ref.read(relationsRepositoryProvider);
      final list = await repo.getMyAccompagnants(acceptedOnly: false);
      if (mounted) setState(() => _relations = list);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = AppStrings.fr().errorGeneric;
          _relations = [];
        });
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _accept(String relationId) async {
    try {
      final repo = ref.read(relationsRepositoryProvider);
      await repo.accept(relationId);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.fr().relationStatusAccepted)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.fr().relationNotFound)),
        );
      }
    }
  }

  Future<void> _delete(String relationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.fr().deleteRelation),
        content: const Text(
          'Voulez-vous vraiment supprimer cette liaison ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.fr().cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final repo = ref.read(relationsRepositoryProvider);
      await repo.delete(relationId);
      await _load();
    } catch (_) {}
  }

  void _showAddDialog(BuildContext context) {
    final strings = AppStrings.fromPreferredLanguage(
      ref.read(authStateProvider).valueOrNull?.preferredLanguage?.name,
    );
    final idController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.addAccompagnantById),
        content: TextField(
          controller: idController,
          decoration: InputDecoration(
            labelText: strings.idPlaceholder,
            hintText: 'ObjectId MongoDB',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(strings.cancelLabel),
          ),
          FilledButton(
            onPressed: () async {
              final id = idController.text.trim();
              if (id.isEmpty) return;
              Navigator.of(ctx).pop();
              try {
                final repo = ref.read(relationsRepositoryProvider);
                await repo.create(accompagnantId: id);
                await _load();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(strings.relationStatusPending)),
                  );
                }
              } on DioException catch (e) {
                if (mounted) {
                  final msg = e.response?.statusCode == 400
                      ? strings.relationAlreadyExists
                      : strings.errorGeneric;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(msg)),
                  );
                }
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(strings.errorGeneric)),
                  );
                }
              }
            },
            child: Text(strings.addAccompagnant),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final strings = AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.myAccompagnants),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _load,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _load,
                        child: Text(strings.save),
                      ),
                    ],
                  ),
                )
              : _relations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: theme.colorScheme.primary),
                          const SizedBox(height: 16),
                          Text(
                            strings.noAccompagnantsYet,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              strings.relationsSubtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () => _showAddDialog(context),
                            icon: const Icon(Icons.add),
                            label: Text(strings.addAccompagnant),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _relations.length,
                        itemBuilder: (_, i) {
                          final r = _relations[i];
                          final u = r.accompagnant;
                          final photo = UserRepository.photoUrl(u?.photoProfil);
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage:
                                    photo.isNotEmpty ? NetworkImage(photo) : null,
                                child: photo.isEmpty ? const Icon(Icons.person) : null,
                              ),
                              title: Text(u?.displayName ?? r.accompagnantId),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (u?.contact != null) Text(u!.contact),
                                  const SizedBox(height: 4),
                                  Chip(
                                    label: Text(
                                      r.isEnAttente
                                          ? strings.relationStatusPending
                                          : strings.relationStatusAccepted,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                itemBuilder: (ctx) => [
                                  if (r.isEnAttente)
                                    PopupMenuItem(
                                      value: 'accept',
                                      child: Text(strings.acceptRelation),
                                    ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Supprimer'),
                                  ),
                                ],
                                onSelected: (v) {
                                  if (v == 'accept') _accept(r.id);
                                  if (v == 'delete') _delete(r.id);
                                },
                              ),
                              minVerticalPadding: 12,
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: _relations.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showAddDialog(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
