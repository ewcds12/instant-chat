import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/posts/domain/public_post.dart';
import 'package:instant_chat/features/posts/presentation/post_image_grid.dart';

void main() {
  testWidgets('single post image keeps its original aspect ratio', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: RetroTheme.data,
        home: const Scaffold(
          body: SizedBox(
            width: 600,
            child: PostImageGrid(images: [_image], accessToken: 'token'),
          ),
        ),
      ),
    );

    expect(find.byType(AspectRatio), findsNothing);
    expect(tester.widget<Image>(find.byType(Image)).fit, BoxFit.fitWidth);
  });
}

const _image = PublicPostImage(
  id: 'image-1',
  position: 0,
  contentType: 'image/jpeg',
  byteSize: 1024,
  url: '/api/v1/uploads/image-1',
);
