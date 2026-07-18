import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/features/realtime/data/websocket_realtime_connection.dart';

void main() {
  test('decodes a versioned message.created event', () {
    final message = decodeRealtimeMessage(
      jsonEncode({
        'event_id': 'message:21',
        'type': 'message.created',
        'version': 1,
        'occurred_at': '2026-07-16T13:00:00Z',
        'payload': {
          'message': {
            'id': '21',
            'conversation_id': '11',
            'sender': {
              'id': '7',
              'username': 'retro_user',
              'display_name': 'Retro User',
              'created_at': '2026-07-16T12:00:00Z',
            },
            'client_message_id': '0123456789abcdef0123456789abcdef',
            'sequence': '4',
            'kind': 'text',
            'body': 'Hello.',
            'image': null,
            'created_at': '2026-07-16T13:00:00Z',
          },
        },
      }),
    );

    expect(message?.id, '21');
    expect(message?.sequence, '4');
  });

  test('rejects an unsupported message.created version', () {
    final raw = jsonEncode({
      'event_id': 'message:21',
      'type': 'message.created',
      'version': 2,
      'occurred_at': '2026-07-16T13:00:00Z',
      'payload': <String, Object?>{},
    });

    expect(() => decodeRealtimeMessage(raw), throwsFormatException);
  });

  test('decodes file metadata from a message.created event', () {
    final message = decodeRealtimeMessage(_messageCreatedEvent(file: true));

    expect(message?.kind.name, 'file');
    expect(message?.body, '');
    expect(message?.file?.filename, 'v1-spec.md');
  });

  test('decodes a profile.updated event', () {
    final profile = decodeRealtimeProfile(
      jsonEncode({
        'event_id': 'profile:7:1',
        'type': 'profile.updated',
        'version': 1,
        'occurred_at': '2026-07-16T13:00:00Z',
        'payload': {
          'user': {
            'id': '7',
            'username': 'retro_user',
            'display_name': 'Retro User',
            'avatar_url': '/api/v1/users/7/avatar?v=1',
            'created_at': '2026-07-16T12:00:00Z',
          },
        },
      }),
    );

    expect(profile?.username, 'retro_user');
    expect(profile?.avatarUrl, '/api/v1/users/7/avatar?v=1');
  });

  test('reconnects after the socket closes and resumes delivery', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var connections = 0;
    String? authorization;
    server.listen((request) async {
      authorization = request.headers.value('authorization');
      final socket = await WebSocketTransformer.upgrade(request);
      socket.listen((_) {});
      connections++;
      if (connections == 1) {
        await socket.close();
        return;
      }
      socket.add(_messageCreatedEvent());
    });
    final connection = WebSocketRealtimeConnection(
      uri: Uri.parse('ws://127.0.0.1:${server.port}/api/v1/realtime'),
      accessToken: 'access-token',
    );
    addTearDown(() async {
      await server.close(force: true);
      await connection.close();
    });

    connection.start();
    final message = await connection.messages.first.timeout(
      const Duration(seconds: 4),
    );

    expect(message.id, '21');
    expect(connections, 2);
    expect(authorization, 'Bearer access-token');
  });
}

String _messageCreatedEvent({bool file = false}) {
  return jsonEncode({
    'event_id': 'message:21',
    'type': 'message.created',
    'version': 1,
    'occurred_at': '2026-07-16T13:00:00Z',
    'payload': {
      'message': {
        'id': '21',
        'conversation_id': '11',
        'sender': {
          'id': '7',
          'username': 'retro_user',
          'display_name': 'Retro User',
          'created_at': '2026-07-16T12:00:00Z',
        },
        'client_message_id': '0123456789abcdef0123456789abcdef',
        'sequence': '4',
        'kind': file ? 'file' : 'text',
        'body': file ? '' : 'Hello.',
        'image': null,
        'file': file
            ? {
                'id': '8',
                'url': '/api/v1/message-files/8',
                'filename': 'v1-spec.md',
                'content_type': 'text/markdown',
                'byte_size': 2048,
              }
            : null,
        'created_at': '2026-07-16T13:00:00Z',
      },
    },
  });
}
