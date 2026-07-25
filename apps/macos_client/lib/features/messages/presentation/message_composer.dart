import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/messages/presentation/message_attachment_menu.dart';
import 'package:instant_chat/features/messages/presentation/message_composer_controls.dart';

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
  final _fieldKey = GlobalKey();
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
      child: LayoutBuilder(
        builder: (context, constraints) => AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) =>
              _buildBar(context, colors, constraints.maxWidth),
        ),
      ),
    );
  }

  Widget _buildBar(BuildContext context, ColorScheme colors, double width) {
    final expanded = _needsExpandedLayout(context, width);
    return Container(
      key: const Key('message-composer-bar'),
      constraints: const BoxConstraints(
        minHeight: RetroMetrics.composerBarHeight,
      ),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.9),
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(RetroMetrics.composerCornerRadius),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: expanded ? _buildExpandedLayout() : _buildCollapsedLayout(),
    );
  }

  Widget _buildCollapsedLayout() {
    return Padding(
      key: const Key('message-composer-collapsed'),
      padding: const EdgeInsets.symmetric(
        horizontal: RetroMetrics.composerActionInset,
      ),
      child: Row(
        children: [
          _buildAttachmentButton(),
          const SizedBox(width: RetroMetrics.composerActionInset),
          Expanded(child: _buildField(expanded: false)),
          const SizedBox(width: RetroMetrics.spaceSmall),
          _buildSendButton(),
        ],
      ),
    );
  }

  Widget _buildExpandedLayout() {
    return Column(
      key: const Key('message-composer-expanded'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildField(expanded: true),
        SizedBox(
          key: const Key('message-composer-actions'),
          height: RetroMetrics.composerExpandedActionHeight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              0,
              0,
              RetroMetrics.composerActionInset,
              RetroMetrics.composerActionInset,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildAttachmentButton(),
                const Spacer(),
                _buildSendButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField({required bool expanded}) {
    return MessageComposerField(
      fieldKey: _fieldKey,
      controller: widget.controller,
      focusNode: widget.focusNode,
      disabled: widget.disabled,
      expanded: expanded,
      recipientName: widget.recipientName,
      onSend: widget.onSend,
    );
  }

  Widget _buildAttachmentButton() {
    return CompositedTransformTarget(
      link: _menuLink,
      child: Tooltip(
        message: 'Add attachment',
        child: SizedBox.square(
          key: const Key('message-attachment-button'),
          dimension: RetroMetrics.composerSendDiameter,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: widget.disabled ? null : _toggleMenu,
              child: const Center(child: Icon(Icons.add_rounded, size: 20)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return MessageComposerSendButton(
      disabled: widget.disabled,
      onSend: widget.onSend,
    );
  }

  bool _needsExpandedLayout(BuildContext context, double width) {
    final text = widget.controller.text;
    if (text.isEmpty) {
      return false;
    }
    if (text.contains('\n')) {
      return true;
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
      text: TextSpan(
        text: text,
        style: MessageComposerField.textStyle(context),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout(maxWidth: textWidth);
    return painter.didExceedMaxLines;
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
