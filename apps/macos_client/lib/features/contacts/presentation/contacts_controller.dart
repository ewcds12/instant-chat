import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/network/api_failure.dart';
import 'package:instant_chat/core/network/dio_provider.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/contacts/data/dio_contact_gateway.dart';
import 'package:instant_chat/features/contacts/domain/contact.dart';
import 'package:instant_chat/features/contacts/domain/contact_gateway.dart';
import 'package:instant_chat/features/contacts/domain/contact_request.dart';
import 'package:instant_chat/features/realtime/presentation/realtime_provider.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

final contactGatewayProvider = Provider<ContactGateway>((ref) {
  return DioContactGateway(ref.watch(dioProvider));
});

final contactRecoveryIntervalProvider = Provider<Duration?>((ref) {
  return const Duration(seconds: 2);
});

final contactsControllerProvider =
    AsyncNotifierProvider.autoDispose<ContactsController, ContactsState>(
      ContactsController.new,
    );

final selectedContactUserIdProvider =
    NotifierProvider.autoDispose<SelectedContactUserId, String?>(
      SelectedContactUserId.new,
    );

class SelectedContactUserId extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? userId) {
    state = userId;
  }
}

class ContactsState {
  const ContactsState({
    required this.contacts,
    required this.incoming,
    required this.outgoing,
    this.searchResult,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final List<Contact> contacts;
  final List<ContactRequest> incoming;
  final List<ContactRequest> outgoing;
  final PublicUser? searchResult;
  final bool isSubmitting;
  final String? errorMessage;

  ContactsState copyWith({
    List<Contact>? contacts,
    List<ContactRequest>? incoming,
    List<ContactRequest>? outgoing,
    PublicUser? searchResult,
    bool clearSearch = false,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ContactsState(
      contacts: contacts ?? this.contacts,
      incoming: incoming ?? this.incoming,
      outgoing: outgoing ?? this.outgoing,
      searchResult: clearSearch ? null : searchResult ?? this.searchResult,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class ContactsController extends AsyncNotifier<ContactsState> {
  ContactGateway get _gateway => ref.read(contactGatewayProvider);
  StreamSubscription<PublicUser>? _profileSubscription;
  Future<void>? _silentRefresh;
  Timer? _recoveryTimer;

  String get _accessToken {
    final session = ref.read(authControllerProvider).requireValue.session;
    if (session == null) {
      throw StateError('An authenticated session is required.');
    }
    return session.accessToken;
  }

  @override
  Future<ContactsState> build() {
    if (_profileSubscription == null) {
      _profileSubscription = ref
          .read(realtimeConnectionProvider)
          .profiles
          .listen(_onRealtimeProfile);
      final interval = ref.read(contactRecoveryIntervalProvider);
      if (interval != null) {
        _recoveryTimer = Timer.periodic(
          interval,
          (_) => unawaited(refreshSilently()),
        );
      }
      ref.onDispose(_closeRealtimeRecovery);
    }
    return _load();
  }

  Future<void> refreshSilently() {
    final inFlight = _silentRefresh;
    if (inFlight != null) {
      return inFlight;
    }
    final current = state.asData?.value;
    if (current == null || current.isSubmitting) {
      return Future.value();
    }
    final refresh = _refreshSnapshot(current);
    _silentRefresh = refresh.whenComplete(() => _silentRefresh = null);
    return _silentRefresh!;
  }

  Future<void> search(String username) async {
    final current = state.requireValue;
    state = AsyncData(current.copyWith(isSubmitting: true, clearError: true));
    try {
      final user = await _gateway.searchUser(
        accessToken: _accessToken,
        username: username.trim().toLowerCase(),
      );
      state = AsyncData(
        current.copyWith(searchResult: user, isSubmitting: false),
      );
    } on ApiFailure catch (failure) {
      _setFailure(current, failure.message);
    } on FormatException {
      _setFailure(current, 'The server returned an invalid response.');
    }
  }

  Future<void> sendSearchResult() async {
    final current = state.requireValue;
    final result = current.searchResult;
    if (result == null) {
      return;
    }
    await _mutate(
      () => _gateway.sendRequest(
        accessToken: _accessToken,
        username: result.username,
      ),
    );
  }

  Future<bool> accept(String requestId) async {
    final current = state.requireValue;
    state = AsyncData(current.copyWith(isSubmitting: true, clearError: true));
    try {
      await _gateway.acceptRequest(
        accessToken: _accessToken,
        requestId: requestId,
      );
      state = AsyncData(await _load());
      return true;
    } on ApiFailure catch (failure) {
      _setFailure(current, failure.message);
    } on FormatException {
      _setFailure(current, 'The server returned an invalid response.');
    }
    return false;
  }

  Future<void> reject(String requestId) {
    return _mutate(
      () => _gateway.rejectRequest(
        accessToken: _accessToken,
        requestId: requestId,
      ),
    );
  }

  Future<void> cancel(String requestId) {
    return _mutate(
      () => _gateway.cancelRequest(
        accessToken: _accessToken,
        requestId: requestId,
      ),
    );
  }

  Future<bool> remove(String userId) async {
    final current = state.requireValue;
    state = AsyncData(current.copyWith(isSubmitting: true, clearError: true));
    try {
      await _gateway.removeContact(accessToken: _accessToken, userId: userId);
      state = AsyncData(await _load());
      return true;
    } on ApiFailure catch (failure) {
      _setFailure(current, failure.message);
    } on FormatException {
      _setFailure(current, 'The server returned an invalid response.');
    }
    return false;
  }

  Future<bool> setRemark(String userId, String remark) async {
    final current = state.requireValue;
    state = AsyncData(current.copyWith(isSubmitting: true, clearError: true));
    try {
      await _gateway.setRemark(
        accessToken: _accessToken,
        userId: userId,
        remark: remark,
      );
      state = AsyncData(await _load());
      return true;
    } on ApiFailure catch (failure) {
      _setFailure(current, failure.message);
    } on FormatException {
      _setFailure(current, 'The server returned an invalid response.');
    }
    return false;
  }

  Future<ContactsState> _load() async {
    final contacts = await _gateway.listContacts(_accessToken);
    final requests = await _gateway.listRequests(_accessToken);
    return ContactsState(
      contacts: contacts,
      incoming: requests.incoming,
      outgoing: requests.outgoing,
    );
  }

  Future<void> _refreshSnapshot(ContactsState current) async {
    try {
      final refreshed = await _load();
      final latest = state.asData?.value;
      if (!ref.mounted || latest == null || latest.isSubmitting) {
        return;
      }
      state = AsyncData(refreshed.copyWith(searchResult: latest.searchResult));
    } on ApiFailure {
      // Keep the visible snapshot intact for a background navigation refresh.
    } on FormatException {
      // Keep the visible snapshot intact for a background navigation refresh.
    }
  }

  Future<void> _mutate(Future<Object?> Function() action) async {
    final current = state.requireValue;
    state = AsyncData(current.copyWith(isSubmitting: true, clearError: true));
    try {
      await action();
      state = AsyncData(await _load());
    } on ApiFailure catch (failure) {
      _setFailure(current, failure.message);
    } on FormatException {
      _setFailure(current, 'The server returned an invalid response.');
    }
  }

  void _setFailure(ContactsState current, String message) {
    state = AsyncData(
      current.copyWith(isSubmitting: false, errorMessage: message),
    );
  }

  void _onRealtimeProfile(PublicUser profile) {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }
    state = AsyncData(
      current.copyWith(
        contacts: current.contacts
            .map(
              (contact) => contact.user.id == profile.id
                  ? Contact(
                      relationshipId: contact.relationshipId,
                      user: profile,
                      remark: contact.remark,
                      connectedAt: contact.connectedAt,
                    )
                  : contact,
            )
            .toList(growable: false),
        incoming: current.incoming
            .map(
              (request) => request.user.id == profile.id
                  ? ContactRequest(
                      id: request.id,
                      user: profile,
                      createdAt: request.createdAt,
                      updatedAt: request.updatedAt,
                    )
                  : request,
            )
            .toList(growable: false),
        outgoing: current.outgoing
            .map(
              (request) => request.user.id == profile.id
                  ? ContactRequest(
                      id: request.id,
                      user: profile,
                      createdAt: request.createdAt,
                      updatedAt: request.updatedAt,
                    )
                  : request,
            )
            .toList(growable: false),
        searchResult: current.searchResult?.id == profile.id
            ? profile
            : current.searchResult,
      ),
    );
  }

  void _closeRealtimeRecovery() {
    _recoveryTimer?.cancel();
    unawaited(_profileSubscription?.cancel());
  }
}
