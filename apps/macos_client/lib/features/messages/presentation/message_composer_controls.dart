import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';

class MessageComposerField extends StatelessWidget {
  const MessageComposerField({
    required this.fieldKey,
    required this.controller,
    required this.focusNode,
    required this.disabled,
    required this.expanded,
    required this.recipientName,
    required this.onSend,
    super.key,
  });

  final GlobalKey fieldKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool disabled;
  final bool expanded;
  final String recipientName;
  final VoidCallback onSend;

  static TextStyle textStyle(BuildContext context) {
    return Theme.of(
      context,
    ).textTheme.bodyMedium!.copyWith(fontSize: RetroMetrics.composerTextSize);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
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
        style: textStyle(context),
        decoration: InputDecoration(
          hintText: 'Message $recipientName',
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
        onSubmitted: (_) => _send(),
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.enter) {
      return KeyEventResult.ignored;
    }
    if (HardwareKeyboard.instance.isShiftPressed) {
      _insertLineBreak();
    } else {
      _send();
    }
    return KeyEventResult.handled;
  }

  void _insertLineBreak() {
    final selection = controller.selection;
    final start = selection.isValid ? selection.start : controller.text.length;
    final end = selection.isValid ? selection.end : start;
    controller.value = TextEditingValue(
      text: controller.text.replaceRange(start, end, '\n'),
      selection: TextSelection.collapsed(offset: start + 1),
    );
  }

  void _send() {
    if (!disabled) {
      onSend();
    }
  }
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
      message: 'Send message',
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
