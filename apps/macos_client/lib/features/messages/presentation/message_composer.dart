import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:instant_chat/app/app_localizations.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/presentation/message_attachment_menu.dart';
import 'package:instant_chat/features/messages/presentation/message_composer_controls.dart';
import 'package:instant_chat/features/messages/presentation/message_composer_image_preview.dart';
import 'package:instant_chat/features/messages/presentation/message_reply_preview.dart';

class MessageComposer extends StatefulWidget {
  const MessageComposer({
    required this.controller,
    required this.focusNode,
    required this.disabled,
    required this.recipientName,
    required this.onSend,
    required this.onPickImage,
    required this.onPickFile,
    this.imagePaths = const [],
    this.onRemoveImage,
    this.onPasteImage,
    this.replyingTo,
    this.onCancelReply,
    this.spellCheckEnabled = true,
    this.spellCheckService,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool disabled;
  final String recipientName;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final VoidCallback onPickFile;
  final List<String> imagePaths;
  final ValueChanged<String>? onRemoveImage;
  final Future<bool> Function()? onPasteImage;
  final Message? replyingTo;
  final VoidCallback? onCancelReply;
  final bool spellCheckEnabled;
  final SpellCheckService? spellCheckService;

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
    final expanded = composerNeedsExpandedLayout(
      context,
      width,
      widget.controller.text,
      hasImage: widget.imagePaths.isNotEmpty,
      hasReply: widget.replyingTo != null,
    );
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
        if (widget.replyingTo case final message?)
          MessageReplyComposerPreview(
            message: message,
            onCancel: widget.onCancelReply ?? () {},
          ),
        if (widget.imagePaths.isNotEmpty)
          MessageComposerImagePreviews(
            imagePaths: widget.imagePaths,
            disabled: widget.disabled,
            onRemove: widget.onRemoveImage ?? (_) {},
          ),
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
      onPasteImage: widget.onPasteImage,
      spellCheckEnabled: widget.spellCheckEnabled,
      spellCheckService: widget.spellCheckService,
    );
  }

  Widget _buildAttachmentButton() {
    return CompositedTransformTarget(
      link: _menuLink,
      child: Tooltip(
        message: context.l10n.ui('Add attachment'),
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
