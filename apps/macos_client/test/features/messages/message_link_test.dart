import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/features/messages/domain/message_link.dart';

void main() {
  test('finds web link ranges and excludes trailing punctuation', () {
    const text =
        'Open https://example.com/docs, then http://instant.chat/path?q=1! '
        'Ignore ftp://example.com and https://.';

    final links = findMessageLinks(text);

    expect(links.map((link) => link.uri.toString()), [
      'https://example.com/docs',
      'http://instant.chat/path?q=1',
    ]);
    expect(
      links.map((link) => text.substring(link.start, link.end)),
      links.map((link) => link.uri.toString()),
    );
  });
}
