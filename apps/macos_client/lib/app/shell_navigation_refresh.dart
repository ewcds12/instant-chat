import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/features/contacts/presentation/contacts_controller.dart';
import 'package:instant_chat/features/conversations/presentation/conversations_controller.dart';

void refreshShellPage(WidgetRef ref, int index) {
  switch (index) {
    case 0:
      unawaited(
        ref.read(conversationsControllerProvider.notifier).refreshSilently(),
      );
      return;
    case 1:
    case 2:
      unawaited(
        ref.read(contactsControllerProvider.notifier).refreshSilently(),
      );
      return;
    default:
      return;
  }
}
