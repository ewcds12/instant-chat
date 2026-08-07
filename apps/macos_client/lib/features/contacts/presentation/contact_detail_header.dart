import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/glass.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';

class ContactDetailHeader extends StatelessWidget {
  const ContactDetailHeader({
    required this.disabled,
    required this.onSearch,
    required this.onSetRemark,
    required this.onRemove,
    this.onBack,
    super.key,
  });

  final bool disabled;
  final VoidCallback onSearch;
  final VoidCallback onSetRemark;
  final VoidCallback onRemove;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GlassPanel(
      radius: 0,
      tint: RetroColors.glassStrong,
      borderColor: Colors.transparent,
      shadows: const [],
      child: Container(
        key: const Key('contact-detail-header'),
        height: RetroMetrics.contactDetailHeaderHeight,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.outlineVariant)),
        ),
        child: Row(
          children: [
            if (onBack != null) ...[
              IconButton(
                key: const Key('contact-detail-back'),
                tooltip: 'Back to conversation',
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 19),
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                'Contact Info',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              key: const Key('contact-message-search-open'),
              tooltip: 'Search message history',
              onPressed: disabled ? null : onSearch,
              icon: const Icon(Icons.search_rounded, size: 19),
            ),
            PopupMenuButton<_ContactMenuAction>(
              tooltip: 'Contact options',
              enabled: !disabled,
              onSelected: (action) {
                switch (action) {
                  case _ContactMenuAction.setRemark:
                    onSetRemark();
                  case _ContactMenuAction.delete:
                    onRemove();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: _ContactMenuAction.setRemark,
                  child: Text('Set Remark…'),
                ),
                PopupMenuItem(
                  value: _ContactMenuAction.delete,
                  child: Text(
                    'Delete Contact…',
                    style: TextStyle(color: colors.error),
                  ),
                ),
              ],
              icon: const Icon(Icons.more_horiz_rounded, size: 19),
            ),
          ],
        ),
      ),
    );
  }
}

class ContactDetailEmptyState extends StatelessWidget {
  const ContactDetailEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 32,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'Select a contact',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Choose a contact from the directory to view their details.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

enum _ContactMenuAction { setRemark, delete }
