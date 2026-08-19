import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/settings/presentation/launch_at_login_setting.dart';

enum SettingsCategory {
  general('General', Icons.settings_outlined),
  appearance('Appearance', Icons.palette_outlined),
  messages('Messages', Icons.chat_bubble_outline_rounded),
  notifications('Notifications', Icons.notifications_none_rounded),
  privacy('Privacy', Icons.shield_outlined),
  storage('Storage', Icons.storage_outlined);

  const SettingsCategory(this.label, this.icon);

  final String label;
  final IconData icon;
}

class SettingsWindowPage extends StatefulWidget {
  const SettingsWindowPage({super.key});

  @override
  State<SettingsWindowPage> createState() => _SettingsWindowPageState();
}

class _SettingsWindowPageState extends State<SettingsWindowPage> {
  final _searchController = TextEditingController();
  var _selectedCategory = SettingsCategory.general;
  var _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final visibleCategories = SettingsCategory.values.where((category) {
      return category.label.toLowerCase().contains(_query.toLowerCase());
    }).toList();
    return Scaffold(
      backgroundColor: RetroColors.canvasTop,
      body: Row(
        children: [
          SizedBox(
            width: 250,
            child: ColoredBox(
              color: const Color(0xFFF4F7FC),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 58, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SettingsSearchField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                    ),
                    const SizedBox(height: 18),
                    for (final category in visibleCategories)
                      _SettingsCategoryTile(
                        category: category,
                        selected: category == _selectedCategory,
                        onTap: () =>
                            setState(() => _selectedCategory = category),
                      ),
                    if (visibleCategories.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'No settings found',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          VerticalDivider(width: 1, color: colors.outlineVariant),
          Expanded(
            child: ColoredBox(
              color: const Color(0xFFFBFCFF),
              child: _SettingsContent(category: _selectedCategory),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSearchField extends StatelessWidget {
  const _SettingsSearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: TextField(
        key: const Key('settings-search-field'),
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13),
        decoration: const InputDecoration(
          hintText: 'Search',
          prefixIcon: Icon(Icons.search_rounded, size: 18),
          prefixIconConstraints: BoxConstraints(minWidth: 38),
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
      ),
    );
  }
}

class _SettingsCategoryTile extends StatelessWidget {
  const _SettingsCategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final SettingsCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = selected ? colors.primary : colors.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? colors.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: Key('settings-category-${category.name}'),
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(category.icon, size: 20, color: foreground),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: selected ? colors.primary : colors.onSurface,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsContent extends StatelessWidget {
  const _SettingsContent({required this.category});

  final SettingsCategory category;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 60, 34, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            category.label,
            key: const Key('settings-content-title'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 25,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          if (category == SettingsCategory.general)
            const _GeneralSettingsShell()
          else
            _CategoryPlaceholder(category: category),
        ],
      ),
    );
  }
}

class _GeneralSettingsShell extends StatefulWidget {
  const _GeneralSettingsShell();

  @override
  State<_GeneralSettingsShell> createState() => _GeneralSettingsShellState();
}

class _GeneralSettingsShellState extends State<_GeneralSettingsShell> {
  var _openLinksExternally = true;
  var _keepInDock = true;
  var _checkSpelling = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const LaunchAtLoginSetting(),
        _SettingsToggleRow(
          label: 'Open links in default browser',
          value: _openLinksExternally,
          onChanged: (value) => setState(() => _openLinksExternally = value),
        ),
        _SettingsToggleRow(
          label: 'Keep app in Dock',
          value: _keepInDock,
          onChanged: (value) => setState(() => _keepInDock = value),
        ),
        const Divider(height: 1),
        const _SettingsValueRow(label: 'Language', value: 'System Default'),
        const _SettingsValueRow(
          label: 'Close window',
          value: 'Keep Instant Chat running',
        ),
        const Divider(height: 1),
        _SettingsToggleRow(
          label: 'Check spelling while typing',
          value: _checkSpelling,
          onChanged: (value) => setState(() => _checkSpelling = value),
        ),
      ],
    );
  }
}

class _SettingsToggleRow extends StatelessWidget {
  const _SettingsToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
          Transform.scale(
            scale: 0.82,
            child: Switch(value: value, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}

class _SettingsValueRow extends StatelessWidget {
  const _SettingsValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 58,
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: colors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _CategoryPlaceholder extends StatelessWidget {
  const _CategoryPlaceholder({required this.category});

  final SettingsCategory category;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.7),
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Icon(category.icon, size: 20, color: colors.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${category.label} settings will be added here.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
