import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/app/instant_chat_app.dart';

void main() {
  runApp(const ProviderScope(child: InstantChatApp()));
}
