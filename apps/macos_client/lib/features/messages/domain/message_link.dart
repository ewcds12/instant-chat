class MessageLink {
  const MessageLink({
    required this.uri,
    required this.start,
    required this.end,
  });

  final Uri uri;
  final int start;
  final int end;
}

List<MessageLink> findMessageLinks(String text) {
  final links = <MessageLink>[];
  final matches = RegExp(
    r'https?://[^\s<>()]+',
    caseSensitive: false,
  ).allMatches(text);
  for (final match in matches) {
    final value = _stripTrailingPunctuation(match.group(0)!);
    final uri = Uri.tryParse(value);
    if (uri != null &&
        uri.host.isNotEmpty &&
        (uri.scheme == 'http' || uri.scheme == 'https')) {
      links.add(
        MessageLink(
          uri: uri,
          start: match.start,
          end: match.start + value.length,
        ),
      );
    }
  }
  return links;
}

String _stripTrailingPunctuation(String value) {
  return value.replaceFirst(RegExp(r'''[.,!?;:\]\}'"]+$'''), '');
}
