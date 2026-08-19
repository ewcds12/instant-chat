import 'package:flutter/material.dart';
import 'package:instant_chat/app/app_localizations.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';

Future<String?> showProfileTextEditor({
  required BuildContext context,
  required String title,
  required String label,
  required String initialValue,
  required String hintText,
  bool lowercase = false,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _ProfileTextEditor(
      title: title,
      label: label,
      initialValue: initialValue,
      hintText: hintText,
      lowercase: lowercase,
    ),
  );
}

Future<String?> showProfileChoiceEditor({
  required BuildContext context,
  required String currentValue,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _ProfileChoiceEditor(currentValue: currentValue),
  );
}

class _ProfileTextEditor extends StatefulWidget {
  const _ProfileTextEditor({
    required this.title,
    required this.label,
    required this.initialValue,
    required this.hintText,
    required this.lowercase,
  });

  final String title;
  final String label;
  final String initialValue;
  final String hintText;
  final bool lowercase;

  @override
  State<_ProfileTextEditor> createState() => _ProfileTextEditorState();
}

class _ProfileTextEditorState extends State<_ProfileTextEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 320,
        child: TextField(
          autofocus: true,
          controller: _controller,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _save(),
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hintText,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.ui('Cancel')),
        ),
        FilledButton(onPressed: _save, child: Text(context.l10n.ui('Save'))),
      ],
    );
  }

  void _save() {
    var value = _controller.text.trim();
    if (widget.lowercase) {
      value = value.toLowerCase();
    }
    Navigator.of(context).pop(value);
  }
}

class _ProfileChoiceEditor extends StatelessWidget {
  const _ProfileChoiceEditor({required this.currentValue});

  final String currentValue;

  @override
  Widget build(BuildContext context) {
    const choices = <String, String>{
      '': 'Not set',
      'female': 'Female',
      'male': 'Male',
      'non_binary': 'Non-binary',
      'prefer_not_to_say': 'Prefer not to say',
    };
    return AlertDialog(
      title: Text(context.l10n.ui('Gender')),
      contentPadding: const EdgeInsets.symmetric(
        vertical: RetroMetrics.spaceSmall,
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in choices.entries)
              ListTile(
                dense: true,
                title: Text(context.l10n.ui(entry.value)),
                trailing: entry.key == currentValue
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.of(context).pop(entry.key),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.ui('Cancel')),
        ),
      ],
    );
  }
}
