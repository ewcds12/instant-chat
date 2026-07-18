import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/profile/presentation/profile_feedback.dart';

void main() {
  testWidgets('renders the success feedback inside the profile panel', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: RetroTheme.data,
        home: const Dialog(
          child: ProfileFeedback(message: 'Profile updated.', isError: false),
        ),
      ),
    );

    expect(find.byKey(const Key('profile-feedback')), findsOneWidget);
    expect(find.text('Profile updated.'), findsOneWidget);

    final feedback = tester.widget<DecoratedBox>(
      find.byKey(const Key('profile-feedback')),
    );
    final decoration = feedback.decoration as BoxDecoration;
    expect(decoration.color, RetroTheme.data.colorScheme.inverseSurface);
  });
}
