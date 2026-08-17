import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/posts/domain/public_post.dart';
import 'package:instant_chat/features/posts/presentation/post_image_grid.dart';

void main() {
  testWidgets('single post image is compact and keeps its full content', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: RetroTheme.data,
        home: Scaffold(
          body: const SizedBox(
            width: 600,
            child: PostImageGrid(images: [_singleImage], accessToken: 'token'),
          ),
        ),
      ),
    );

    expect(find.byType(AspectRatio), findsNothing);
    final frame = tester.widget<ConstrainedBox>(
      find.byKey(const Key('post-single-image-frame')),
    );
    expect(
      frame.constraints.maxWidth,
      600 * RetroMetrics.exploreSingleImageWidthFactor,
    );
    expect(frame.constraints.minWidth, frame.constraints.maxWidth);
    expect(
      frame.constraints.maxHeight,
      RetroMetrics.exploreSingleImageMaxHeight,
    );
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.fit, BoxFit.contain);
    expect(image.width, double.infinity);
    final material = tester.widget<Material>(
      find.descendant(
        of: find.byKey(const Key('post-image-0')),
        matching: find.byType(Material),
      ),
    );
    expect(material.type, MaterialType.transparency);
  });

  testWidgets('two post images render side by side', (tester) async {
    await _pumpImages(tester, 2);

    final first = tester.getRect(find.byKey(const Key('post-image-0')));
    final second = tester.getRect(find.byKey(const Key('post-image-1')));
    _expectClose(first.top, second.top);
    _expectClose(first.bottom, second.bottom);
    expect(first.right, lessThan(second.left));
    expect(
      tester.getSize(find.byKey(const Key('post-multi-image-frame'))).height,
      RetroMetrics.exploreDoubleImageHeight,
    );
  });

  testWidgets('three post images use one large and two stacked tiles', (
    tester,
  ) async {
    await _pumpImages(tester, 3);

    final first = tester.getRect(find.byKey(const Key('post-image-0')));
    final second = tester.getRect(find.byKey(const Key('post-image-1')));
    final third = tester.getRect(find.byKey(const Key('post-image-2')));
    _expectClose(first.top, second.top);
    _expectClose(first.bottom, third.bottom);
    _expectClose(second.left, third.left);
    expect(second.bottom, lessThan(third.top));
  });

  testWidgets('four post images render as a two by two mosaic', (tester) async {
    await _pumpImages(tester, 4);

    final first = tester.getRect(find.byKey(const Key('post-image-0')));
    final second = tester.getRect(find.byKey(const Key('post-image-1')));
    final third = tester.getRect(find.byKey(const Key('post-image-2')));
    final fourth = tester.getRect(find.byKey(const Key('post-image-3')));
    _expectClose(first.top, second.top);
    _expectClose(third.top, fourth.top);
    _expectClose(first.left, third.left);
    _expectClose(second.left, fourth.left);
    expect(first.bottom, lessThan(third.top));
  });

  testWidgets('photo viewer navigates between post images', (tester) async {
    String? downloadedImageId;
    await _pumpImages(
      tester,
      3,
      onDownloadImage: (image) async => downloadedImageId = image.id,
    );

    await tester.tap(find.byKey(const Key('post-image-0')));
    await tester.pumpAndSettle();
    expect(find.text('1 of 3'), findsOneWidget);
    expect(find.byKey(const Key('message-image-preview')), findsOneWidget);
    expect(find.byKey(const Key('message-image-preview-prev')), findsOneWidget);
    expect(find.byKey(const Key('message-image-preview-next')), findsOneWidget);

    await tester.tap(find.byKey(const Key('message-image-preview-next')));
    await tester.pumpAndSettle();
    expect(find.text('2 of 3'), findsOneWidget);

    await tester.tap(find.byKey(const Key('message-image-preview-download')));
    await tester.pump();
    expect(downloadedImageId, 'image-1');

    await tester.tap(find.byKey(const Key('message-image-preview-next')));
    await tester.pumpAndSettle();
    expect(find.text('3 of 3'), findsOneWidget);

    await tester.tap(find.byKey(const Key('message-image-preview-prev')));
    await tester.pumpAndSettle();
    expect(find.text('2 of 3'), findsOneWidget);
  });
}

Future<void> _pumpImages(
  WidgetTester tester,
  int count, {
  Future<void> Function(PublicPostImage image)? onDownloadImage,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: RetroTheme.data,
      home: Scaffold(
        body: SizedBox(
          width: 600,
          child: PostImageGrid(
            images: _images.take(count).toList(growable: false),
            accessToken: 'token',
            onDownloadImage: onDownloadImage,
          ),
        ),
      ),
    ),
  );
}

void _expectClose(double actual, double expected) {
  expect(actual, moreOrLessEquals(expected, epsilon: 0.1));
}

final _images = List.generate(
  4,
  (index) => PublicPostImage(
    id: 'image-$index',
    position: index,
    contentType: 'image/jpeg',
    byteSize: 1024,
    url: '/api/v1/uploads/image-$index',
  ),
);

const _singleImage = PublicPostImage(
  id: 'single-image',
  position: 0,
  contentType: 'image/jpeg',
  byteSize: 1024,
  url: '/api/v1/uploads/single-image',
);
