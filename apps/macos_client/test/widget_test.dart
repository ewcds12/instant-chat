import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:instant_chat/app/instant_chat_app.dart';
import 'package:instant_chat/features/system_status/domain/service_health.dart';
import 'package:instant_chat/features/system_status/presentation/system_status_provider.dart';

void main() {
  testWidgets('shows online when API and database are healthy', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          serviceHealthProvider.overrideWith(
            (ref) async => ServiceHealth(
              status: 'healthy',
              service: 'instant-chat-api',
              database: 'healthy',
              checkedAt: DateTime.utc(2026, 7, 15, 12),
            ),
          ),
        ],
        child: const InstantChatApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ONLINE'), findsOneWidget);
    expect(
      find.textContaining('API and MySQL are operational'),
      findsOneWidget,
    );
    final pageContext = tester.element(find.text('ONLINE'));
    expect(Localizations.localeOf(pageContext), const Locale('en', 'US'));
  });

  testWidgets('shows offline when API request fails', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          serviceHealthProvider.overrideWith(
            (ref) => Future<ServiceHealth>.error(StateError('offline')),
          ),
        ],
        child: const InstantChatApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('OFFLINE'), findsOneWidget);
    expect(find.text('RETRY CONNECTION'), findsOneWidget);
  });
}
