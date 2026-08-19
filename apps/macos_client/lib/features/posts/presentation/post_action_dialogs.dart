import 'package:flutter/material.dart';
import 'package:instant_chat/app/app_localizations.dart';

Future<bool> confirmDeletePost(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.ui('Delete Post?')),
          content: Text(
            context.l10n.ui('This post will be permanently removed.'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.l10n.ui('Cancel')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.l10n.ui('Delete')),
            ),
          ],
        ),
      ) ??
      false;
}

Future<String?> askReportReason(BuildContext context) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.l10n.ui('Report Post')),
      content: SizedBox(
        width: 340,
        child: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 500,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: context.l10n.ui('Tell us what is wrong with this post'),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.ui('Cancel')),
        ),
        FilledButton(
          onPressed: () {
            final value = controller.text.trim();
            if (value.isNotEmpty) Navigator.of(context).pop(value);
          },
          child: Text(context.l10n.ui('Report')),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}
