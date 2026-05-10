import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/map/geocode_result.dart';
import '../../providers/api_providers.dart';

/// Champ de recherche d'adresse avec suggestions (géocodage via backend).
class AddressSearchField extends ConsumerStatefulWidget {
  const AddressSearchField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.countrycodes = 'TN',
    this.limit = 5,
    required this.onSelected,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String countrycodes;
  final int limit;
  final void Function(GeocodeResult? result) onSelected;

  @override
  ConsumerState<AddressSearchField> createState() => _AddressSearchFieldState();
}

class _AddressSearchFieldState extends ConsumerState<AddressSearchField> {
  List<GeocodeResult> _suggestions = [];
  bool _loading = false;
  Timer? _debounce;
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  double _fieldWidth = 300;
  double _fieldHeight = 56;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onTextChanged);
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    _debounce?.cancel();
    final query = widget.controller.text.trim();
    if (query.length < 2) {
      _removeOverlay();
      setState(() => _suggestions = []);
      return;
    }
    // Ne pas lancer de recherche si le texte ressemble à une adresse complète
    // (ex. pré-remplie par reverse-geocode / "Ma position actuelle") pour éviter
    // un geocode avec countrycodes restreint qui renverrait [].
    if (query.length >= 40 && query.contains(',')) {
      _removeOverlay();
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(mapRepositoryProvider);
      final results = await repo.geocode(
        query: query,
        countrycodes: widget.countrycodes,
        limit: widget.limit,
      );
      if (mounted) {
        setState(() {
          _suggestions = results;
          _loading = false;
        });
        // Afficher l'overlay après le layout pour avoir les bonnes dimensions
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showOverlay();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _loading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showOverlay();
        });
      }
    }
  }

  void _showOverlay() {
    _removeOverlay();
    if (_suggestions.isEmpty && !_loading) return;

    final box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      _fieldWidth = box.size.width;
      _fieldHeight = box.size.height;
    }

    final width = _fieldWidth;
    final height = _fieldHeight;
    final suggestions = List<GeocodeResult>.from(_suggestions);
    final loading = _loading;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Fermer les suggestions en tapant à l'extérieur
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                _removeOverlay();
                setState(() => _suggestions = []);
              },
            ),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, height + 4),
            child: SizedBox(
              width: width,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: loading
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          itemCount: suggestions.length,
                          itemBuilder: (context, index) {
                            final r = suggestions[index];
                            return ListTile(
                              leading: Icon(Icons.place, color: Colors.grey.shade600, size: 22),
                              title: Text(
                                r.displayName,
                                style: const TextStyle(fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                widget.controller.text = r.displayName;
                                widget.onSelected(r);
                                _removeOverlay();
                                setState(() => _suggestions = []);
                              },
                            );
                          },
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary, size: 22),
          suffixIcon: _loading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
        ),
        onTap: () {
          if (widget.controller.text.trim().length >= 2 && _suggestions.isNotEmpty) {
            _showOverlay();
          }
        },
      ),
    );
  }
}
