import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';

enum ExploreFeedTab { forYou, contacts }

class ExploreHeader extends StatelessWidget {
  const ExploreHeader({
    required this.selectedTab,
    required this.onTabSelected,
    required this.onCreate,
    required this.onRefresh,
    required this.onBlockedUsers,
    super.key,
  });

  final ExploreFeedTab selectedTab;
  final ValueChanged<ExploreFeedTab> onTabSelected;
  final VoidCallback onCreate;
  final VoidCallback onRefresh;
  final VoidCallback onBlockedUsers;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: RetroMetrics.exploreHeaderHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: RetroColors.glassStrong,
          border: Border(bottom: BorderSide(color: colors.outlineVariant)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 24,
              child: Text(
                'Explore',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FeedTab(
                  label: 'For you',
                  selected: selectedTab == ExploreFeedTab.forYou,
                  onTap: () => onTabSelected(ExploreFeedTab.forYou),
                ),
                _FeedTab(
                  label: 'Contacts',
                  selected: selectedTab == ExploreFeedTab.contacts,
                  onTap: () => onTabSelected(ExploreFeedTab.contacts),
                ),
              ],
            ),
            Positioned(
              right: 12,
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Refresh',
                    visualDensity: VisualDensity.compact,
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Explore settings',
                    icon: const Icon(Icons.more_horiz_rounded, size: 18),
                    onSelected: (_) => onBlockedUsers(),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'blocked',
                        height: 34,
                        child: Text(
                          'Blocked Users',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    key: const Key('explore-compose-button'),
                    tooltip: 'New Post',
                    visualDensity: VisualDensity.compact,
                    color: colors.primary,
                    onPressed: onCreate,
                    icon: const Icon(Icons.edit_square, size: 19),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedTab extends StatelessWidget {
  const _FeedTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        key: Key('explore-tab-${label.toLowerCase().replaceAll(' ', '-')}'),
        onTap: onTap,
        child: SizedBox(
          width: 96,
          height: RetroMetrics.exploreHeaderHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? colors.onSurface : colors.onSurfaceVariant,
                ),
              ),
              if (selected)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 0,
                  child: Container(height: 2, color: colors.primary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
