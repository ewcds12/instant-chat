import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/network/api_failure.dart';
import 'package:instant_chat/core/network/dio_provider.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/conversations/data/dio_conversation_gateway.dart';
import 'package:instant_chat/features/conversations/domain/conversation.dart';
import 'package:instant_chat/features/conversations/domain/conversation_gateway.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/realtime/presentation/realtime_provider.dart';

final conversationGatewayProvider = Provider<ConversationGateway>((ref) {
  return DioConversationGateway(ref.watch(dioProvider));
});

final conversationsControllerProvider =
    AsyncNotifierProvider.autoDispose<
      ConversationsController,
      ConversationsState
    >(ConversationsController.new);

class ConversationsState {
  const ConversationsState({
    required this.conversations,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final List<Conversation> conversations;
  final bool isSubmitting;
  final String? errorMessage;

  ConversationsState copyWith({
    List<Conversation>? conversations,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ConversationsState(
      conversations: conversations ?? this.conversations,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class ConversationsController extends AsyncNotifier<ConversationsState> {
  ConversationGateway get _gateway => ref.read(conversationGatewayProvider);
  StreamSubscription<Message>? _messageSubscription;

  String get _accessToken {
    final session = ref.read(authControllerProvider).requireValue.session;
    if (session == null) {
      throw StateError('An authenticated session is required.');
    }
    return session.accessToken;
  }

  @override
  Future<ConversationsState> build() async {
    if (_messageSubscription == null) {
      _messageSubscription = ref
          .read(realtimeConnectionProvider)
          .messages
          .listen(_onRealtimeMessage);
      ref.onDispose(() => unawaited(_messageSubscription?.cancel()));
    }
    return ConversationsState(conversations: await _gateway.list(_accessToken));
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  Future<void> create(String contactUserId) async {
    final current = state.requireValue;
    state = AsyncData(current.copyWith(isSubmitting: true, clearError: true));
    try {
      await _gateway.createDirect(
        accessToken: _accessToken,
        contactUserId: contactUserId,
      );
      state = AsyncData(
        ConversationsState(conversations: await _gateway.list(_accessToken)),
      );
    } on ApiFailure catch (failure) {
      _setFailure(current, failure.message);
    } on FormatException {
      _setFailure(current, 'The server returned an invalid response.');
    }
  }

  Future<bool> markRead(String conversationId, String sequence) async {
    try {
      await _gateway.markRead(
        accessToken: _accessToken,
        conversationId: conversationId,
        sequence: sequence,
      );
      if (!ref.mounted) {
        return false;
      }
      final current = state.asData?.value;
      if (current != null) {
        state = AsyncData(
          current.copyWith(
            conversations: current.conversations
                .map(
                  (conversation) => conversation.id == conversationId
                      ? conversation.copyWith(unreadCount: 0)
                      : conversation,
                )
                .toList(growable: false),
          ),
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  void _onRealtimeMessage(Message message) {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }
    final index = current.conversations.indexWhere(
      (conversation) => conversation.id == message.conversationId,
    );
    if (index < 0) {
      return;
    }
    final userID = ref
        .read(authControllerProvider)
        .requireValue
        .session
        ?.user
        .id;
    final conversation = current.conversations[index];
    final unreadCount = message.sender.id == userID
        ? conversation.unreadCount
        : conversation.unreadCount + 1;
    final updated = conversation.copyWith(
      updatedAt: message.createdAt,
      unreadCount: unreadCount,
    );
    final conversations = [...current.conversations]..removeAt(index);
    conversations.insert(0, updated);
    state = AsyncData(current.copyWith(conversations: conversations));
  }

  void _setFailure(ConversationsState current, String message) {
    state = AsyncData(
      current.copyWith(isSubmitting: false, errorMessage: message),
    );
  }
}
