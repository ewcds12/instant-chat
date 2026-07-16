import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/glass.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';

class MessageComposer extends StatefulWidget {
  const MessageComposer({
    required this.controller,
    required this.focusNode,
    required this.disabled,
    required this.recipientName,
    required this.onSend,
    required this.onPickImage,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool disabled;
  final String recipientName;
  final VoidCallback onSend;
  final VoidCallback onPickImage;

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
            CompositedTransformTarget(
              link: _menuLink,
              child: Tooltip(
                message: 'Add photo',
                child: SizedBox.square(
                  dimension: RetroMetrics.composerControlHeight,
                  child: IconButton.outlined(
                    onPressed: widget.disabled ? null : _toggleMenu,
                    icon: const Icon(Icons.add_rounded, size: 18),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: _ComposerField(widget: widget)),
            const SizedBox(width: 12),
            _SendButton(disabled: widget.disabled, onSend: widget.onSend),
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
            child: _AttachmentMenu(
              animation: _menuController!,
              onPhoto: () {
                _closeMenu(immediate: true);
                widget.onPickImage();
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

class _AttachmentMenu extends StatelessWidget {
  const _AttachmentMenu({required this.animation, required this.onPhoto});

  final Animation<double> animation;
  final VoidCallback onPhoto;

  @override
  Widget build(BuildContext context) {
    final opacity = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final scale = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );
    final slide = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: opacity,
      child: ScaleTransition(
        alignment: Alignment.bottomLeft,
        scale: scale.drive(Tween(begin: 0.96, end: 1.0)),
        child: SlideTransition(
          position: slide.drive(
            Tween(begin: const Offset(0, 0.05), end: Offset.zero),
          ),
          child: SizedBox(
            width: 178,
            child: GlassPanel(
              tint: RetroColors.glassStrong,
              radius: 16,
              padding: const EdgeInsets.all(6),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(11),
                  onTap: onPhoto,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.photo_outlined,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Photo…',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ComposerField extends StatelessWidget {
  const _ComposerField({required this.widget});

  final MessageComposer widget;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
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
          onPressed: widget.disabled ? null : _insertEmoji,
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
        if (!widget.disabled) {
          widget.onSend();
        }
      },
    );
  }

  void _insertEmoji() {
    final selection = widget.controller.selection;
    final offset = selection.isValid
        ? selection.start
        : widget.controller.text.length;
    final updated = widget.controller.text.replaceRange(offset, offset, '🙂');
    widget.controller.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: offset + 2),
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
        dimension: RetroMetrics.composerControlHeight,
        child: FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size.square(RetroMetrics.composerControlHeight),
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
    );
  }
}
