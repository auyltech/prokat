import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/base_tile.dart';
import 'package:prokat/features/equipment/state/equipment_provider.dart';

class SearchBox extends ConsumerStatefulWidget {
  final String? placeholder;

  const SearchBox({super.key, this.placeholder});

  @override
  ConsumerState<SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends ConsumerState<SearchBox> {
  late final TextEditingController _searchController;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onChange(String value) {
    // Cancel the previous timer if the user types before 500ms
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      ref.read(equipmentProvider.notifier).setQuery(value);
    });
  }

  void _onSubmit() {
    // Cancel any pending debounce timers to avoid duplicate requests
    _debounceTimer?.cancel();
    ref.read(equipmentProvider.notifier).setQuery(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BaseTile(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      // decoration: BoxDecoration(
      //   color: theme.cardColor,
      //   border: Border.all(color: theme.dividerColor.withValues(alpha: 0.7)),
      //   borderRadius: BorderRadius.circular(16),
      // ),
      child: TextField(
        controller: _searchController,
        onChanged: _onChange,
        onSubmitted: (_) => _onSubmit(),
        decoration: InputDecoration(
          hintText: widget.placeholder ?? 'Search equipment...',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          icon: Icon(
            Icons.tune_rounded,
            size: 24,
            color: theme.colorScheme.primary,
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _onSubmit,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
