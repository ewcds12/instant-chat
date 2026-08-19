import 'package:flutter/material.dart';
import 'package:instant_chat/app/app_localizations.dart';
import 'package:instant_chat/core/platform/macos_message_translation.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';

Future<MessageTranslationLanguage?> showMessageTranslationLanguageDialog({
  required BuildContext context,
  required MessageTranslationLanguage? currentLanguage,
  required List<MessageTranslationLanguage> languages,
  required bool selectionRequired,
}) {
  return showDialog<MessageTranslationLanguage>(
    context: context,
    barrierDismissible: !selectionRequired,
    builder: (context) => _MessageTranslationLanguageDialog(
      currentLanguage: currentLanguage,
      languages: languages,
      selectionRequired: selectionRequired,
    ),
  );
}

class _MessageTranslationLanguageDialog extends StatefulWidget {
  const _MessageTranslationLanguageDialog({
    required this.currentLanguage,
    required this.languages,
    required this.selectionRequired,
  });

  final MessageTranslationLanguage? currentLanguage;
  final List<MessageTranslationLanguage> languages;
  final bool selectionRequired;

  @override
  State<_MessageTranslationLanguageDialog> createState() =>
      _MessageTranslationLanguageDialogState();
}

class _MessageTranslationLanguageDialogState
    extends State<_MessageTranslationLanguageDialog> {
  final _searchController = TextEditingController();
  String _query = '';

  List<MessageTranslationLanguage> get _filteredLanguages {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.languages;
    return widget.languages
        .where((language) {
          return language.label.toLowerCase().contains(query) ||
              language.code.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languages = _filteredLanguages;
    final textTheme = Theme.of(context).textTheme;
    return PopScope(
      canPop: !widget.selectionRequired,
      child: AlertDialog(
        key: const Key('message-translation-language-dialog'),
        titlePadding: const EdgeInsets.fromLTRB(
          RetroMetrics.spaceMedium,
          RetroMetrics.spaceMedium,
          RetroMetrics.spaceMedium,
          RetroMetrics.spaceSmall,
        ),
        title: Text(
          context.l10n.ui('Translate to'),
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        contentPadding: const EdgeInsets.fromLTRB(
          RetroMetrics.spaceMedium,
          0,
          RetroMetrics.spaceMedium,
          RetroMetrics.spaceSmall,
        ),
        content: SizedBox(
          width: RetroMetrics.messageTranslationDialogWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LanguageSearchField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                onClear: _clearSearch,
              ),
              const SizedBox(height: RetroMetrics.spaceSmall),
              _LanguageList(
                languages: languages,
                currentLanguage: widget.currentLanguage,
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          RetroMetrics.spaceSmall,
          0,
          RetroMetrics.spaceSmall,
          RetroMetrics.spaceSmall,
        ),
        actions: widget.selectionRequired
            ? null
            : [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.l10n.ui('Cancel')),
                ),
              ],
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }
}

class _LanguageSearchField extends StatelessWidget {
  const _LanguageSearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasQuery = controller.text.isNotEmpty;
    return SizedBox(
      height: RetroMetrics.messageTranslationSearchHeight,
      child: TextField(
        key: const Key('message-translation-language-search'),
        controller: controller,
        autofocus: true,
        onChanged: onChanged,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: context.l10n.ui('Search languages'),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: RetroMetrics.messageTranslationSearchIconSize,
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 34),
          suffixIcon: hasQuery
              ? IconButton(
                  key: const Key('message-translation-language-search-clear'),
                  tooltip: context.l10n.ui('Clear search'),
                  onPressed: onClear,
                  padding: EdgeInsets.zero,
                  iconSize: RetroMetrics.messageTranslationSearchIconSize,
                  icon: const Icon(Icons.close_rounded),
                )
              : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 34),
          filled: true,
          fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.55),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: RetroMetrics.spaceSmall,
          ),
          border: _border(colors.outlineVariant),
          enabledBorder: _border(colors.outlineVariant),
          focusedBorder: _border(colors.primary),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(RetroMetrics.corner),
      borderSide: BorderSide(color: color),
    );
  }
}

class _LanguageList extends StatelessWidget {
  const _LanguageList({required this.languages, required this.currentLanguage});

  final List<MessageTranslationLanguage> languages;
  final MessageTranslationLanguage? currentLanguage;

  @override
  Widget build(BuildContext context) {
    if (languages.isEmpty) {
      return SizedBox(
        key: Key('message-translation-language-empty'),
        height: RetroMetrics.messageTranslationEmptyHeight,
        child: Center(child: Text(context.l10n.ui('No languages found'))),
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: RetroMetrics.messageTranslationDialogMaxHeight,
      ),
      child: ListView.builder(
        key: const Key('message-translation-language-list'),
        shrinkWrap: true,
        itemCount: languages.length,
        itemBuilder: (context, index) {
          final language = languages[index];
          return _LanguageOption(
            language: language,
            selected: language == currentLanguage,
          );
        },
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({required this.language, required this.selected});

  final MessageTranslationLanguage language;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      key: ValueKey('message-translation-language-${language.code}'),
      height: RetroMetrics.messageTranslationRowHeight,
      child: InkWell(
        borderRadius: BorderRadius.circular(RetroMetrics.corner),
        onTap: () => Navigator.pop(context, language),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: RetroMetrics.spaceSmall,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  language.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_rounded,
                  size: RetroMetrics.messageTranslationCheckIconSize,
                  color: colors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
