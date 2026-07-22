import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/messages/presentation/message_attachment_menu.dart';

class MessageComposer extends StatefulWidget {
  const MessageComposer({
    required this.controller,
    required this.focusNode,
    required this.disabled,
    required this.recipientName,
    required this.onSend,
    required this.onPickImage,
    required this.onPickFile,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool disabled;
  final String recipientName;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final VoidCallback onPickFile;

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer>
    with TickerProviderStateMixin {
  final _menuLink = LayerLink();
  OverlayEntry? _menuEntry;
  AnimationController? _menuController;
  var _closingMenu = false;

  @override
  void dispose() {
    _menuEntry?.remove();
    _menuController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        RetroMetrics.composerHorizontalInset,
        RetroMetrics.composerTopInset,
        RetroMetrics.composerHorizontalInset,
        RetroMetrics.composerBottomInset,
      ),
      child: Container(
        key: const Key('message-composer-bar'),
        constraints: const BoxConstraints(
          minHeight: RetroMetrics.composerBarHeight,
        ),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.9),
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(RetroMetrics.cornerPill),
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            CompositedTransformTarget(
              link: _menuLink,
              child: Tooltip(
                message: 'Add attachment',
                child: SizedBox.square(
                  dimension: RetroMetrics.composerBarHeight,
                  child: IconButton(
                    onPressed: widget.disabled ? null : _toggleMenu,
                    icon: const Icon(Icons.add_rounded, size: 24),
                  ),
                ),
              ),
            ),
            Expanded(child: _ComposerField(widget: widget)),
            const SizedBox(width: RetroMetrics.spaceSmall),
            _SendButton(disabled: widget.disabled, onSend: widget.onSend),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }

  void _toggleMenu() {
    if (_closingMenu) {
      return;
    }
    if (_menuEntry == null) {
      _openMenu();
      return;
    }
    _closeMenu();
  }

  void _openMenu() {
    _closeMenu(immediate: true);
    _closingMenu = false;
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 170),
      reverseDuration: const Duration(milliseconds: 110),
    );
    _menuEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeMenu,
            ),
          ),
          CompositedTransformFollower(
            link: _menuLink,
            targetAnchor: Alignment.topLeft,
            followerAnchor: Alignment.bottomLeft,
            offset: const Offset(0, -8),
            child: MessageAttachmentMenu(
              animation: _menuController!,
              onPhoto: () {
                _closeMenu(immediate: true);
                widget.onPickImage();
              },
              onFile: () {
                _closeMenu(immediate: true);
                widget.onPickFile();
              },
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_menuEntry!);
    _menuController!.forward();
  }

  void _closeMenu({bool immediate = false}) {
    final entry = _menuEntry;
    final controller = _menuController;
    if (entry == null || controller == null) {
      return;
    }
    if (immediate) {
      entry.remove();
      controller.dispose();
      _menuEntry = null;
      _menuController = null;
      _closingMenu = false;
      return;
    }
    _closingMenu = true;
    controller.reverse().whenComplete(() {
      if (_menuEntry == entry) {
        _menuEntry = null;
      }
      if (_menuController == controller) {
        _menuController = null;
      }
      _closingMenu = false;
      entry.remove();
      controller.dispose();
    });
  }
}

class _ComposerField extends StatelessWidget {
  const _ComposerField({required this.widget});

  final MessageComposer widget;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('message-composer'),
      controller: widget.controller,
      focusNode: widget.focusNode,
      enabled: !widget.disabled,
      minLines: 1,
      maxLines: 5,
      maxLength: 4000,
      textInputAction: TextInputAction.send,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Message ${widget.recipientName}',
        counterText: '',
        isDense: true,
        filled: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: RetroMetrics.spaceSmall,
          vertical: 10,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
      onSubmitted: (_) {
        if (!widget.disabled) {
          widget.onSend();
        }
      },
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.disabled, required this.onSend});

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
              : const Icon(Icons.arrow_upward_rounded, size: 20),
        ),
      ),
    );
  }
}
