import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedConversationIdProvider =
    NotifierProvider.autoDispose<SelectedConversationId, String?>(
      SelectedConversationId.new,
    );

class SelectedConversationId extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? conversationId) {
    state = conversationId;
  }
}
