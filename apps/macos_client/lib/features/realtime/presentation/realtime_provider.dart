import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/config/app_config.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/realtime/data/websocket_realtime_connection.dart';
import 'package:instant_chat/features/realtime/domain/realtime_connection.dart';

final realtimeConnectionProvider = Provider.autoDispose<RealtimeConnection>((
  ref,
) {
  final session = ref.watch(authControllerProvider).requireValue.session;
  if (session == null) {
    throw StateError('An authenticated session is required.');
  }
  final connection = WebSocketRealtimeConnection(
    uri: AppConfig.realtimeUri,
    accessToken: session.accessToken,
  );
  connection.start();
  ref.onDispose(() => unawaited(connection.close()));
  return connection;
});
