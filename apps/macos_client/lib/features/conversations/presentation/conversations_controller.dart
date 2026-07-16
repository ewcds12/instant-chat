import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/network/api_failure.dart';
import 'package:instant_chat/core/network/dio_provider.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/conversations/data/dio_conversation_gateway.dart';
import 'package:instant_chat/features/conversations/domain/conversation.dart';
import 'package:instant_chat/features/conversations/domain/conversation_gateway.dart';

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
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ConversationsState(
      conversations: conversations,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class ConversationsController extends AsyncNotifier<ConversationsState> {
  ConversationGateway get _gateway => ref.read(conversationGatewayProvider);

  String get _accessToken {
    final session = ref.read(authControllerProvider).requireValue.session;
    if (session == null) {
      throw StateError('An authenticated session is required.');
    }
    return session.accessToken;
  }

  @override
  Future<ConversationsState> build() async {
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

  void _setFailure(ConversationsState current, String message) {
    state = AsyncData(
      current.copyWith(isSubmitting: false, errorMessage: message),
    );
  }
}
