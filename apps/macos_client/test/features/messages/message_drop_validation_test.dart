import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/features/messages/presentation/message_drop_validation.dart';

void main() {
  test('recognizes only server-supported image extensions', () {
    expect(messageDropPathIsImage('/tmp/photo.PNG'), isTrue);
    expect(messageDropPathIsImage('/tmp/photo.jpeg'), isTrue);
    expect(messageDropPathIsImage('/tmp/photo.heic'), isFalse);
    expect(messageDropPathIsImage('/tmp/archive.png.zip'), isFalse);
  });

  test('enforces the existing image and file upload limits', () {
    expect(
      messageDropSizeError('/tmp/photo.png', maximumDroppedImageBytes),
      isNull,
    );
    expect(
      messageDropSizeError('/tmp/photo.png', maximumDroppedImageBytes + 1),
      'Images must be 15 MB or smaller.',
    );
    expect(
      messageDropSizeError('/tmp/archive.zip', maximumDroppedFileBytes),
      isNull,
    );
    expect(
      messageDropSizeError('/tmp/archive.zip', maximumDroppedFileBytes + 1),
      'Files must be 2 GB or smaller.',
    );
  });
}
