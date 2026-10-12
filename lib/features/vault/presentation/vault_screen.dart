import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/preferences.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/ls_button.dart';
import '../../../core/widgets/ls_card.dart';
import '../../../core/widgets/states.dart';
import '../../transfers/domain/transfer.dart';

/// Link Vault (PRD §8.12) — private by default.
class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  String _query = '';
  String _tag = 'all';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = ref.watch(vaultProvider);

    final tags = <String>{for (final i in items) ...i.tags};
    final filtered = items.where((i) {
      final matchesQuery = _query.isEmpty ||
          i.title.toLowerCase().contains(_query.toLowerCase()) ||
          i.content.toLowerCase().contains(_query.toLowerCase());
      final matchesTag = _tag == 'all' || i.tags.contains(_tag);
      return matchesQuery && matchesTag;
    }).toList();

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Vault'),
        actions: [
          LsIconButton(
            icon: Icons.add_rounded,
            tooltip: 'Add item',
            onPressed: () => _addItem(context, ref),
          ),
          const SizedBox(width: Insets.sm),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addItem(context, ref),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add'),
      ),
      body: Column(
        children: [
          if (items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Insets.gutter, 0, Insets.gutter, Insets.md),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Search your vault',
                  prefixIcon: Icon(Icons.search_rounded, size: 19),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: Insets.lg, vertical: Insets.md),
                ),
              ),
            ),
          if (tags.isNotEmpty)
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Insets.gutter),
                children: [
                  _TagChip(
                    label: 'all',
                    selected: _tag == 'all',
                    onTap: () => setState(() => _tag = 'all'),
                  ),
                  for (final tag in tags)
                    _TagChip(
                      label: tag,
                      selected: _tag == tag,
                      onTap: () => setState(() => _tag = tag),
                    ),
                ],
              ),
            ),
          Expanded(
            child: items.isEmpty
                ? LsEmptyState(
                    icon: Icons.bookmark_border_rounded,
                    title: 'Your vault is empty',
                    message: 'Save links, notes and references here. Everything '
                        'stays private to your account.',
                    actionLabel: 'Add the first item',
                    onAction: () => _addItem(context, ref),
                  )
                : filtered.isEmpty
                    ? const LsEmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No matches',
                        message: 'Nothing in your vault matches that search.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                            Insets.gutter, Insets.md, Insets.gutter, 96),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: Insets.sm),
                        itemBuilder: (context, i) =>
                            _VaultRow(item: filtered[i], now: DateTime.now()),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _addItem(BuildContext context, WidgetRef ref) async {
    final title = TextEditingController();
    final content = TextEditingController();
    final tags = TextEditingController();
    var kind = VaultKind.url;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
                Insets.gutter, Insets.lg, Insets.gutter, Insets.xxl),
            decoration: BoxDecoration(
              color: Theme.of(sheetContext).colorScheme.surfaceContainer,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(Radii.xl)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(sheetContext)
                            .colorScheme
                            .outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: Insets.xl),
                  Text('New vault item',
                      style: Theme.of(sheetContext).textTheme.heading),
                  const SizedBox(height: Insets.xl),
                  LsSegmented<VaultKind>(
                    value: kind,
                    options: VaultKind.values,
                    labelBuilder: (k) => switch (k) {
                      VaultKind.url => 'Link',
                      VaultKind.note => 'Note',
                      VaultKind.file => 'Reference',
                    },
                    onChanged: (k) => setSheet(() => kind = k),
                  ),
                  const SizedBox(height: Insets.lg),
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: Insets.md),
                  TextField(
                    controller: content,
                    maxLines: kind == VaultKind.note ? 4 : 1,
                    decoration: InputDecoration(
                      labelText: switch (kind) {
                        VaultKind.url => 'URL',
                        VaultKind.note => 'Note',
                        VaultKind.file => 'Reference',
                      },
                    ),
                  ),
                  const SizedBox(height: Insets.md),
                  TextField(
                    controller: tags,
                    decoration: const InputDecoration(
                      labelText: 'Tags',
                      hintText: 'work, receipts',
                    ),
                  ),
                  const SizedBox(height: Insets.xl),
                  LsButton(
                    label: 'Save to vault',
                    expand: true,
                    onPressed: () {
                      if (title.text.trim().isEmpty) return;
                      ref.read(vaultProvider.notifier).add(
                            VaultItem(
                              id: 'v${DateTime.now().microsecondsSinceEpoch}',
                              kind: kind,
                              title: title.text.trim(),
                              content: content.text.trim(),
                              createdAt: DateTime.now(),
                              tags: tags.text
                                  .split(',')
                                  .map((s) => s.trim())
                                  .where((s) => s.isNotEmpty)
                                  .toList(),
                            ),
                          );
                      Navigator.of(sheetContext).pop();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: Insets.sm),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: Insets.md, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? scheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(Radii.pill),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _VaultRow extends ConsumerWidget {
  const _VaultRow({required this.item, required this.now});

  final VaultItem item;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final (IconData icon, Color color) = switch (item.kind) {
      VaultKind.url => (Icons.link_rounded, scheme.primary),
      VaultKind.note => (Icons.notes_rounded, AppColors.cyan),
      VaultKind.file => (Icons.description_outlined, scheme.onSurfaceVariant),
    };

    return LsCard(
      padding: const EdgeInsets.all(Insets.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: t.bodyStrong, maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  item.content,
                  style: AppType.monoSmall
                      .copyWith(color: scheme.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Insets.sm),
                Row(
                  children: [
                    Text(
                      Fmt.ago(item.createdAt, now),
                      style: AppType.monoTiny
                          .copyWith(color: scheme.onSurfaceVariant),
                    ),
                    for (final tag in item.tags) ...[
                      const SizedBox(width: Insets.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(Radii.pill),
                        ),
                        child: Text(
                          tag,
                          style: AppType.monoTiny
                              .copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Item actions',
            icon: Icon(Icons.more_vert_rounded, color: scheme.onSurfaceVariant),
            onSelected: (v) {
              if (v == 'copy') {
                Clipboard.setData(ClipboardData(text: item.content));
              } else if (v == 'delete') {
                ref.read(vaultProvider.notifier).remove(item.id);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'copy', child: Text('Copy content')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}