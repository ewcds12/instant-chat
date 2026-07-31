import 'package:flutter/material.dart';

class ContactSharedLinksDialog extends StatelessWidget {
  const ContactSharedLinksDialog({
    required this.links,
    required this.onOpen,
    super.key,
  });

  final List<Uri> links;
  final Future<void> Function(Uri link) onOpen;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('contact-shared-links-dialog'),
      title: const Text('Shared Links'),
      content: SizedBox(
        width: 520,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: links.length,
          separatorBuilder: (_, _) => const Divider(),
          itemBuilder: (context, index) {
            final link = links[index];
            return ListTile(
              key: ValueKey('contact-shared-link-$index'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.link_rounded),
              title: Text(
                link.host,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                link.toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.open_in_new_rounded, size: 18),
              onTap: () => onOpen(link),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
