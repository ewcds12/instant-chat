import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/glass.dart';
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
    return GlassPanel(
      radius: 0,
      tint: RetroColors.glassStrong,
      borderColor: Colors.transparent,
      shadows: const [],
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
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
                  icon: const Icon(Icons.add_rounded, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 10),
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
                ).textTheme.bodyMedium?.copyWith(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Message $recipientName',
                  counterText: '',
                  isDense: true,
                  fillColor: RetroColors.glass,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: RetroMetrics.composerControlHeight,
                    minHeight: RetroMetrics.composerControlHeight,
                  ),
                  suffixIcon: IconButton(
                    tooltip: 'Insert emoji',
                    onPressed: disabled ? null : _insertEmoji,
                    icon: const Icon(Icons.sentiment_satisfied_alt, size: 17),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(color: colors.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
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
            const SizedBox(width: 12),
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
                      : const Icon(Icons.send_rounded, size: 18),
                ),
              ),
            ),
          ],
        ),
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
