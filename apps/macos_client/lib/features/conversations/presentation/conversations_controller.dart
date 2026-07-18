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
import 'package:instant_chat/features/users/domain/public_user.dart';

final conversationGatewayProvider = Provider<ConversationGateway>((ref) {
  return DioConversationGateway(ref.watch(dioProvider));
});

final conversationRecoveryIntervalProvider = Provider<Duration?>((ref) {
  return const Duration(seconds: 2);
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
  StreamSubscription<PublicUser>? _profileSubscription;
  StreamSubscription<int>? _connectionSubscription;
  Timer? _recoveryTimer;
  var _eventGeneration = 0;
  var _isSynchronizing = false;
  var _pendingSynchronization = false;

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
      final realtime = ref.read(realtimeConnectionProvider);
      _messageSubscription = realtime.messages.listen(_onRealtimeMessage);
      _profileSubscription = realtime.profiles.listen(_onRealtimeProfile);
      _connectionSubscription = realtime.connections.listen(
        (_) => _queueSynchronization(),
      );
      final interval = ref.read(conversationRecoveryIntervalProvider);
      if (interval != null) {
        _recoveryTimer = Timer.periodic(
          interval,
          (_) => _queueSynchronization(),
        );
      }
      ref.onDispose(_closeRealtimeRecovery);
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

  void recordMessage(Message message) {
    _onRealtimeMessage(message);
  }

  void _onRealtimeMessage(Message message) {
    final current = state.asData?.value;
    if (current == null) {
      _pendingSynchronization = true;
      return;
    }
    final index = current.conversations.indexWhere(
      (conversation) => conversation.id == message.conversationId,
    );
    if (index < 0) {
      _queueSynchronization();
      return;
    }
    final userID = ref
        .read(authControllerProvider)
        .requireValue
        .session
        ?.user
        .id;
    final conversation = current.conversations[index];
    if (_isStale(message, conversation.lastMessage)) {
      return;
    }
    final unreadCount = message.sender.id == userID
        ? conversation.unreadCount
        : conversation.unreadCount + 1;
    final updated = conversation.copyWith(
      updatedAt: message.createdAt,
      unreadCount: unreadCount,
      lastMessage: ConversationLastMessage(
        sequence: message.sequence,
        kind: message.kind.wireName,
        body: message.body,
        fileName: message.file?.filename ?? '',
      ),
    );
    final conversations = [...current.conversations]..removeAt(index);
    conversations.insert(0, updated);
    _eventGeneration++;
    state = AsyncData(current.copyWith(conversations: conversations));
  }

  void _onRealtimeProfile(PublicUser profile) {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }
    final conversations = current.conversations
        .map(
          (conversation) => conversation.peer.id == profile.id
              ? conversation.copyWith(peer: profile)
              : conversation,
        )
        .toList(growable: false);
    state = AsyncData(current.copyWith(conversations: conversations));
  }

  void _queueSynchronization() {
    if (!ref.mounted) {
      return;
    }
    final current = state.asData?.value;
    if (current == null || current.isSubmitting || _isSynchronizing) {
      _pendingSynchronization = true;
      return;
    }
    _isSynchronizing = true;
    _pendingSynchronization = false;
    unawaited(_synchronize(current, _eventGeneration));
  }

  Future<void> _synchronize(ConversationsState current, int generation) async {
    try {
      final conversations = await _gateway.list(_accessToken);
      if (!ref.mounted || generation != _eventGeneration) {
        _pendingSynchronization = true;
        return;
      }
      state = AsyncData(current.copyWith(conversations: conversations));
    } on ApiFailure {
      // The next fallback check retries a transient synchronization failure.
    } on FormatException {
      // The next fallback check retries an invalid synchronization response.
    } finally {
      _isSynchronizing = false;
      if (_pendingSynchronization) {
        _queueSynchronization();
      }
    }
  }

  bool _isStale(Message message, ConversationLastMessage? lastMessage) {
    if (lastMessage == null) {
      return false;
    }
    return BigInt.parse(message.sequence) <= BigInt.parse(lastMessage.sequence);
  }

  void _closeRealtimeRecovery() {
    _recoveryTimer?.cancel();
    unawaited(_messageSubscription?.cancel());
    unawaited(_profileSubscription?.cancel());
    unawaited(_connectionSubscription?.cancel());
  }

  void _setFailure(ConversationsState current, String message) {
    state = AsyncData(
      current.copyWith(isSubmitting: false, errorMessage: message),
    );
  }
}
