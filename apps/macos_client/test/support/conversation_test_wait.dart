import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/features/conversations/presentation/conversations_controller.dart';

Future<void> waitForConversationPreview(ProviderContainer container) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (container
            .read(conversationsControllerProvider)
            .requireValue
            .conversations
            .single
            .lastMessage !=
        null) {
      return;
    }
  }
  fail('Timed out waiting for the recovered conversation preview.');
}
