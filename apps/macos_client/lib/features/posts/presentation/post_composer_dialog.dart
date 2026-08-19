import 'dart:io';

import 'package:flutter/material.dart';
import 'package:instant_chat/app/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/platform/macos_image_picker.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/posts/presentation/posts_controller.dart';

Future<void> showPostComposer(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _PostComposerDialog(),
  );
}

class _PostComposerDialog extends ConsumerStatefulWidget {
  const _PostComposerDialog();

  @override
  ConsumerState<_PostComposerDialog> createState() =>
      _PostComposerDialogState();
}

class _PostComposerDialogState extends ConsumerState<_PostComposerDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _images = <String>[];
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postState = ref.watch(postsControllerProvider).asData?.value;
    final submitting = postState?.isSubmitting ?? false;
    return Dialog(
      child: SizedBox(
        width: 430,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(submitting),
              _editor(),
              if (_images.isNotEmpty) _previews(submitting),
              if (_error != null) _errorLabel(),
              const SizedBox(height: 10),
              _actions(submitting),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(bool submitting) {
    return Row(
      children: [
        Text(
          context.l10n.ui('New Post'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const Spacer(),
        IconButton(
          tooltip: context.l10n.ui('Close'),
          splashRadius: 18,
          onPressed: submitting ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded, size: 19),
        ),
      ],
    );
  }

  Widget _editor() {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      minLines: 4,
      maxLines: 8,
      maxLength: 1000,
      decoration: InputDecoration(
        hintText: context.l10n.ui('Share something with everyone…'),
        counterText: '',
      ),
      onChanged: (_) => setState(() => _error = null),
    );
  }

  Widget _previews(bool submitting) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        height: 74,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _images.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) => _SelectedPhoto(
            path: _images[index],
            onRemove: submitting
                ? null
                : () => setState(() => _images.removeAt(index)),
          ),
        ),
      ),
    );
  }

  Widget _errorLabel() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        _error!,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }

  Widget _actions(bool submitting) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: submitting || _images.length >= 4 ? null : _addPhoto,
          icon: const Icon(Icons.add_photo_alternate_outlined, size: 17),
          label: Text(context.l10n.photoCount(_images.length)),
        ),
        const Spacer(),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(76, 34),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          onPressed: submitting ? null : _publish,
          child: submitting
              ? const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.l10n.ui('Post')),
        ),
      ],
    );
  }

  Future<void> _addPhoto() async {
    final path = await ref
        .read(localImagePickerProvider)
        .pickImagePath(prompt: context.l10n.ui('Choose a photo for your post'));
    if (path == null || !mounted) return;
    if (_images.contains(path)) {
      setState(
        () => _error = context.l10n.ui('That photo is already selected.'),
      );
      return;
    }
    final size = await File(path).length();
    if (!mounted) return;
    if (size == 0 || size > 15 * 1024 * 1024) {
      setState(
        () => _error = context.l10n.ui(
          'Each photo must be no larger than 15 MB.',
        ),
      );
      return;
    }
    setState(() {
      _images.add(path);
      _error = null;
    });
  }

  Future<void> _publish() async {
    final localizations = context.l10n;
    if (_controller.text.trim().isEmpty && _images.isEmpty) {
      setState(
        () => _error = context.l10n.ui('Add text or at least one photo.'),
      );
      return;
    }
    final created = await ref
        .read(postsControllerProvider.notifier)
        .create(_controller.text, List.unmodifiable(_images));
    if (!mounted) return;
    if (created) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        final message = ref.read(postsControllerProvider).value?.errorMessage;
        _error = message == null ? null : localizations.ui(message);
      });
    }
  }
}

class _SelectedPhoto extends StatelessWidget {
  const _SelectedPhoto({required this.path, required this.onRemove});

  final String path;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(RetroMetrics.corner),
          child: Image.file(
            File(path),
            width: 74,
            height: 74,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          right: 3,
          top: 3,
          child: InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(10),
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xB0000000),
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.close_rounded, size: 13, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
