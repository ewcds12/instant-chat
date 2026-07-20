import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.clientMessageId,
    required this.sequence,
    required this.kind,
    required this.body,
    required this.image,
    this.file,
    this.recalledAt,
    required this.createdAt,
  });

  final String id;
  final String conversationId;
  final PublicUser sender;
  final String clientMessageId;
  final String sequence;
  final MessageKind kind;
  final String body;
  final MessageImage? image;
  final MessageFile? file;
  final DateTime? recalledAt;
  final DateTime createdAt;

  factory Message.fromJson(Map<String, Object?> json) {
    final senderValue = json['sender'];
    if (senderValue is! Map<Object?, Object?>) {
      throw const FormatException('sender must be a JSON object');
    }
    return Message(
      id: requiredString(json, 'id'),
      conversationId: requiredString(json, 'conversation_id'),
      sender: PublicUser.fromJson(_stringKeyed(senderValue)),
      clientMessageId: requiredString(json, 'client_message_id'),
      sequence: requiredString(json, 'sequence'),
      kind: MessageKind.fromWire(json['kind']),
      body: _requiredBody(json),
      image: MessageImage.fromJsonOrNull(json['image']),
      file: MessageFile.fromJsonOrNull(json['file']),
      recalledAt: _optionalDateTime(json, 'recalled_at'),
      createdAt: requiredDateTime(json, 'created_at'),
    );
  }

  Message recalled(DateTime timestamp) => Message(
    id: id,
    conversationId: conversationId,
    sender: sender,
    clientMessageId: clientMessageId,
    sequence: sequence,
    kind: kind,
    body: '',
    image: null,
    file: null,
    recalledAt: timestamp,
    createdAt: createdAt,
  );
}

class MessageRecall {
  const MessageRecall({
    required this.conversationId,
    required this.messageId,
    required this.recalledAt,
  });

  final String conversationId;
  final String messageId;
  final DateTime recalledAt;
}

enum MessageKind {
  text('text'),
  image('image'),
  file('file');

  const MessageKind(this.wireName);

  final String wireName;

  static MessageKind fromWire(Object? value) {
    if (value == null) {
      return MessageKind.text;
    }
    if (value is! String) {
      throw const FormatException('kind must be a string');
    }
    return switch (value) {
      'text' => MessageKind.text,
      'image' => MessageKind.image,
      'file' => MessageKind.file,
      _ => throw const FormatException('kind is not supported'),
    };
  }
}

class MessageImage {
  const MessageImage({
    required this.id,
    required this.url,
    required this.contentType,
    required this.byteSize,
  });

  final String id;
  final String url;
  final String contentType;
  final int byteSize;

  static MessageImage? fromJsonOrNull(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is! Map<Object?, Object?>) {
      throw const FormatException('image must be a JSON object or null');
    }
    final json = _stringKeyed(value);
    final byteSize = json['byte_size'];
    if (byteSize is! int) {
      throw const FormatException('byte_size must be an integer');
    }
    return MessageImage(
      id: requiredString(json, 'id'),
      url: requiredString(json, 'url'),
      contentType: requiredString(json, 'content_type'),
      byteSize: byteSize,
    );
  }
}

class MessageFile {
  const MessageFile({
    required this.id,
    required this.url,
    required this.filename,
    required this.contentType,
    required this.byteSize,
  });

  final String id;
  final String url;
  final String filename;
  final String contentType;
  final int byteSize;

  static MessageFile? fromJsonOrNull(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is! Map<Object?, Object?>) {
      throw const FormatException('file must be a JSON object or null');
    }
    final json = _stringKeyed(value);
    final byteSize = json['byte_size'];
    if (byteSize is! int) {
      throw const FormatException('byte_size must be an integer');
    }
    return MessageFile(
      id: requiredString(json, 'id'),
      url: requiredString(json, 'url'),
      filename: requiredString(json, 'filename'),
      contentType: requiredString(json, 'content_type'),
      byteSize: byteSize,
    );
  }
}

String _requiredBody(Map<String, Object?> json) {
  final value = json['body'];
  if (value is! String) {
    throw const FormatException('body must be a string');
  }
  return value;
}

DateTime? _optionalDateTime(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! String || value.isEmpty) {
    throw FormatException('$key must be an RFC 3339 timestamp or null');
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw FormatException('$key must be an RFC 3339 timestamp or null');
  }
  return parsed.toUtc();
}

Map<String, Object?> _stringKeyed(Map<Object?, Object?> value) {
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key case final String key) {
      result[key] = entry.value;
    } else {
      throw const FormatException('JSON object keys must be strings');
    }
  }
  return result;
}
