import 'package:flutter/material.dart';

Future<String?> showContactRemarkDialog({
  required BuildContext context,
  required String originalName,
  required String currentRemark,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _ContactRemarkDialog(
      originalName: originalName,
      currentRemark: currentRemark,
    ),
  );
}

class _ContactRemarkDialog extends StatefulWidget {
  const _ContactRemarkDialog({
    required this.originalName,
    required this.currentRemark,
  });

  final String originalName;
  final String currentRemark;

  @override
  State<_ContactRemarkDialog> createState() => _ContactRemarkDialogState();
}

class _ContactRemarkDialogState extends State<_ContactRemarkDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentRemark);
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Remark'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const Key('contact-remark-field'),
              controller: _controller,
              autofocus: true,
              maxLength: 64,
              maxLines: 1,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: widget.originalName,
                prefixIcon: const Icon(Icons.edit_outlined, size: 18),
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 4),
            Text(
              'The original name stays visible and searchable. Leave this empty to clear the remark.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }

  void _save() {
    Navigator.of(context).pop(_controller.text.trim());
  }
}
