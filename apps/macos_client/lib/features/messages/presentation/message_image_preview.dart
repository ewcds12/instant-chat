import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:instant_chat/core/network/api_response.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/presentation/message_image_view.dart';

part 'message_image_preview_parts.dart';

Future<void> showMessageImagePreview({
  required BuildContext context,
  required List<MessageImage> images,
  required MessageImage initialImage,
  required String accessToken,
}) {
  if (images.isEmpty) {
    return Future<void>.value();
  }
  final initialIndex = images.indexWhere(
    (image) => image.id == initialImage.id,
  );
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.42),
    builder: (_) => MessageImagePreview(
      images: images,
      initialIndex: initialIndex < 0 ? 0 : initialIndex,
      accessToken: accessToken,
    ),
  );
}

class MessageImagePreview extends StatefulWidget {
  const MessageImagePreview({
    required this.images,
    required this.initialIndex,
    required this.accessToken,
    super.key,
  });

  final List<MessageImage> images;
  final int initialIndex;
  final String accessToken;

  @override
  State<MessageImagePreview> createState() => _MessageImagePreviewState();
}

class _MessageImagePreviewState extends State<MessageImagePreview> {
  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex.clamp(0, widget.images.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.images[selectedIndex];
    return Focus(
      autofocus: true,
      onKeyEvent: (_, event) => _handleKey(event),
      child: Dialog(
        key: const Key('message-image-preview'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(42),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: _PreviewFrame(
            child: _PreviewContent(
              image: image,
              accessToken: widget.accessToken,
              index: selectedIndex,
              total: widget.images.length,
              onClose: () => Navigator.of(context).pop(),
              onPrevious: () => _move(-1),
              onNext: () => _move(1),
            ),
          ),
        ),
      ),
    );
  }

  KeyEventResult _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _move(-1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _move(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _move(int delta) {
    if (widget.images.length < 2) {
      return;
    }
    setState(() {
      selectedIndex =
          (selectedIndex + delta + widget.images.length) % widget.images.length;
    });
  }
}

class _PreviewFrame extends StatelessWidget {
  const _PreviewFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 920, maxHeight: 680),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.76),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.72),
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x330F172A),
              blurRadius: 36,
              offset: Offset(0, 24),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _PreviewContent extends StatelessWidget {
  const _PreviewContent({
    required this.image,
    required this.accessToken,
    required this.index,
    required this.total,
    required this.onClose,
    required this.onPrevious,
    required this.onNext,
  });

  final MessageImage image;
  final String accessToken;
  final int index;
  final int total;
  final VoidCallback onClose;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PreviewToolbar(index: index, total: total, onClose: onClose),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(26, 8, 26, 26),
            child: Stack(
              alignment: Alignment.center,
              children: [
                _PreviewImage(
                  key: ValueKey('message-image-preview-${image.id}'),
                  image: image,
                  accessToken: accessToken,
                ),
                if (total > 1) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _ArrowButton(
                      key: const Key('message-image-preview-prev'),
                      icon: Icons.chevron_left,
                      onPressed: onPrevious,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _ArrowButton(
                      key: const Key('message-image-preview-next'),
                      icon: Icons.chevron_right,
                      onPressed: onNext,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewImage extends StatelessWidget {
  const _PreviewImage({
    required this.image,
    required this.accessToken,
    super.key,
  });

  final MessageImage image;
  final String accessToken;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Image.network(
        messageImageUrl(image),
        key: ValueKey(image.id),
        headers: bearerAuthorization(accessToken),
        fit: BoxFit.contain,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }
          return _PreviewPlaceholder(color: colors.surfaceContainer);
        },
        errorBuilder: (context, _, _) =>
            _PreviewPlaceholder(color: colors.surfaceContainer),
      ),
    );
  }
}
