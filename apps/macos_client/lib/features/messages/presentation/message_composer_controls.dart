import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:instant_chat/app/app_localizations.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';

bool composerNeedsExpandedLayout(
  BuildContext context,
  double width,
  String text, {
  required bool hasImage,
  bool hasReply = false,
}) {
  if (hasImage || hasReply || text.contains('\n')) {
    return true;
  }
  if (text.isEmpty) {
    return false;
  }
  final chromeWidth =
      (RetroMetrics.composerActionInset * 3) +
      (RetroMetrics.composerSendDiameter * 2) +
      RetroMetrics.spaceSmall +
      (RetroMetrics.spaceSmall * 2);
  final textWidth = width - chromeWidth;
  if (textWidth <= 0) {
    return true;
  }
  final painter = TextPainter(
    text: TextSpan(text: text, style: MessageComposerField.textStyle(context)),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout(maxWidth: textWidth);
  return painter.didExceedMaxLines;
}

class MessageComposerField extends StatelessWidget {
  const MessageComposerField({
    required this.fieldKey,
    required this.controller,
    required this.focusNode,
    required this.disabled,
    required this.expanded,
    required this.recipientName,
    required this.onSend,
    required this.spellCheckEnabled,
    this.spellCheckService,
    this.onPasteImage,
    super.key,
  });

  final GlobalKey fieldKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool disabled;
  final bool expanded;
  final String recipientName;
  final VoidCallback onSend;
  final bool spellCheckEnabled;
  final SpellCheckService? spellCheckService;
  final Future<bool> Function()? onPasteImage;

  static TextStyle textStyle(BuildContext context) {
    return Theme.of(
      context,
    ).textTheme.bodyMedium!.copyWith(fontSize: RetroMetrics.composerTextSize);
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyV, meta: true):
            _PasteComposerIntent(),
        SingleActivator(LogicalKeyboardKey.keyV, control: true):
            _PasteComposerIntent(),
      },
      child: Actions(
        actions: {
          _PasteComposerIntent: _ComposerPasteAction(onPasteImage, controller),
        },
        child: Focus(
          key: fieldKey,
          onKeyEvent: _handleKeyEvent,
          child: TextField(
            key: const Key('message-composer'),
            controller: controller,
            focusNode: focusNode,
            enabled: !disabled,
            minLines: 1,
            maxLines: RetroMetrics.composerMaxLines,
            maxLength: 4000,
            textInputAction: TextInputAction.send,
            spellCheckConfiguration: _spellCheckConfiguration,
            style: textStyle(context),
            decoration: InputDecoration(
              hintText: context.l10n.messageRecipient(recipientName),
              counterText: '',
              isDense: true,
              filled: false,
              contentPadding: expanded
                  ? const EdgeInsets.fromLTRB(
                      RetroMetrics.composerExpandedTextHorizontalInset,
                      RetroMetrics.composerExpandedTextTopInset,
                      RetroMetrics.composerExpandedTextHorizontalInset,
                      RetroMetrics.composerExpandedTextBottomInset,
                    )
                  : const EdgeInsets.symmetric(
                      horizontal: RetroMetrics.spaceSmall,
                      vertical: 10,
                    ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            onSubmitted: (_) {
              if (!_hasActiveComposition) {
                _send();
              }
            },
          ),
        ),
      ),
    );
  }

  SpellCheckConfiguration get _spellCheckConfiguration {
    if (!spellCheckEnabled || spellCheckService == null) {
      return const SpellCheckConfiguration.disabled();
    }
    return SpellCheckConfiguration(spellCheckService: spellCheckService);
  }

  KeyEventResult _handleKeyEvent(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey != LogicalKeyboardKey.enter) {
      return KeyEventResult.ignored;
    }
    if (_hasActiveComposition) {
      return KeyEventResult.ignored;
    }
    if (HardwareKeyboard.instance.isShiftPressed) {
      _insertLineBreak();
    } else {
      _send();
    }
    return KeyEventResult.handled;
  }

  bool get _hasActiveComposition {
    final composing = controller.value.composing;
    return composing.isValid && !composing.isCollapsed;
  }

  void _insertLineBreak() {
    _insertText('\n');
  }

  void _insertText(String text) {
    final selection = controller.selection;
    final start = selection.isValid ? selection.start : controller.text.length;
    final end = selection.isValid ? selection.end : start;
    controller.value = TextEditingValue(
      text: controller.text.replaceRange(start, end, text),
      selection: TextSelection.collapsed(offset: start + text.length),
    );
  }

  void _send() {
    if (!disabled) {
      onSend();
    }
  }
}

class _PasteComposerIntent extends Intent {
  const _PasteComposerIntent();
}

class _ComposerPasteAction extends Action<_PasteComposerIntent> {
  _ComposerPasteAction(this.onPasteImage, this.controller);

  final Future<bool> Function()? onPasteImage;
  final TextEditingController controller;

  @override
  Object? invoke(_PasteComposerIntent intent) {
    unawaited(_paste());
    return null;
  }

  Future<void> _paste() async {
    if (await onPasteImage?.call() ?? false) {
      return;
    }
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) {
      return;
    }
    final selection = controller.selection;
    final start = selection.isValid ? selection.start : controller.text.length;
    final end = selection.isValid ? selection.end : start;
    controller.value = TextEditingValue(
      text: controller.text.replaceRange(start, end, text),
      selection: TextSelection.collapsed(offset: start + text.length),
    );
  }

  @override
  bool get isActionEnabled => true;

  @override
  bool consumesKey(_PasteComposerIntent intent) => true;
}

class MessageComposerSendButton extends StatelessWidget {
  const MessageComposerSendButton({
    required this.disabled,
    required this.onSend,
    super.key,
  });

  final bool disabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: context.l10n.ui('Send message'),
      child: SizedBox.square(
        key: const Key('message-send-button'),
        dimension: RetroMetrics.composerSendDiameter,
        child: FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size.square(RetroMetrics.composerSendDiameter),
            padding: EdgeInsets.zero,
            shape: const CircleBorder(),
          ),
          onPressed: disabled ? null : onSend,
          child: disabled
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.arrow_upward_rounded, size: 18),
        ),
      ),
    );
  }
}
