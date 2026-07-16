import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';

class MessageComposer extends StatelessWidget {
  const MessageComposer({
    required this.controller,
    required this.focusNode,
    required this.disabled,
    required this.recipientName,
    required this.onSend,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool disabled;
  final String recipientName;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Tooltip(
            message: 'Attachments are not available yet',
            child: SizedBox.square(
              dimension: RetroMetrics.composerControlHeight,
              child: IconButton.outlined(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Attachments are not available yet.'),
                    ),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 17),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              key: const Key('message-composer'),
              controller: controller,
              focusNode: focusNode,
              enabled: !disabled,
              minLines: 1,
              maxLines: 5,
              maxLength: 4000,
              textInputAction: TextInputAction.send,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Message $recipientName',
                counterText: '',
                isDense: true,
                fillColor: colors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 8,
                ),
                suffixIconConstraints: const BoxConstraints(
                  minWidth: RetroMetrics.composerControlHeight,
                  minHeight: RetroMetrics.composerControlHeight,
                ),
                suffixIcon: IconButton(
                  tooltip: 'Insert emoji',
                  onPressed: disabled ? null : _insertEmoji,
                  icon: const Icon(Icons.sentiment_satisfied_alt, size: 16),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: colors.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: colors.primary),
                ),
              ),
              onSubmitted: (_) {
                if (!disabled) {
                  onSend();
                }
              },
            ),
          ),
          const SizedBox(width: 10),
          Tooltip(
            message: 'Send message',
            child: SizedBox.square(
              dimension: RetroMetrics.composerControlHeight,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.square(
                    RetroMetrics.composerControlHeight,
                  ),
                  padding: EdgeInsets.zero,
                  shape: const CircleBorder(),
                ),
                onPressed: disabled ? null : onSend,
                child: disabled
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded, size: 17),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _insertEmoji() {
    final selection = controller.selection;
    final offset = selection.isValid ? selection.start : controller.text.length;
    final updated = controller.text.replaceRange(offset, offset, '🙂');
    controller.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: offset + 2),
    );
  }
}
