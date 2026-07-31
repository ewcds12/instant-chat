import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:instant_chat/features/messages/domain/message_link.dart';

class MessageLinkText extends StatefulWidget {
  const MessageLinkText({
    required this.text,
    required this.style,
    required this.linkStyle,
    required this.onOpenLink,
    super.key,
  });

  final String text;
  final TextStyle style;
  final TextStyle linkStyle;
  final Future<void> Function(Uri link) onOpenLink;

  @override
  State<MessageLinkText> createState() => _MessageLinkTextState();
}

class _MessageLinkTextState extends State<MessageLinkText> {
  var _links = <MessageLink>[];
  var _recognizers = <TapGestureRecognizer>[];

  @override
  void initState() {
    super.initState();
    _updateLinks();
  }

  @override
  void didUpdateWidget(covariant MessageLinkText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _updateLinks();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_links.isEmpty) {
      return Text(widget.text, style: widget.style);
    }
    return Text.rich(TextSpan(children: _buildSpans()), style: widget.style);
  }

  List<InlineSpan> _buildSpans() {
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (var index = 0; index < _links.length; index++) {
      final link = _links[index];
      if (link.start > cursor) {
        spans.add(TextSpan(text: widget.text.substring(cursor, link.start)));
      }
      spans.add(
        TextSpan(
          text: widget.text.substring(link.start, link.end),
          style: widget.linkStyle,
          recognizer: _recognizers[index],
          mouseCursor: SystemMouseCursors.click,
        ),
      );
      cursor = link.end;
    }
    if (cursor < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(cursor)));
    }
    return spans;
  }

  void _updateLinks() {
    _disposeRecognizers();
    _links = findMessageLinks(widget.text);
    _recognizers = [
      for (final link in _links)
        TapGestureRecognizer()
          ..onTap = () => unawaited(widget.onOpenLink(link.uri)),
    ];
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
  }
}
