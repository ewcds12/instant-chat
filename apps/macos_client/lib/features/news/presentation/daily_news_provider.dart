import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/network/dio_provider.dart';
import 'package:instant_chat/features/news/data/dio_daily_news_gateway.dart';
import 'package:instant_chat/features/news/domain/daily_brief.dart';
import 'package:instant_chat/features/news/domain/daily_news_gateway.dart';

final dailyNewsGatewayProvider = Provider<DailyNewsGateway>((ref) {
  return DioDailyNewsGateway(ref.watch(dioProvider));
});

final dailyBriefProvider = FutureProvider.autoDispose
    .family<DailyBrief, String>(
      (ref, accessToken) =>
          ref.watch(dailyNewsGatewayProvider).fetch(accessToken),
    );
