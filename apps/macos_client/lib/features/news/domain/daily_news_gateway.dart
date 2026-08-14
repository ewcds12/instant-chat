import 'package:instant_chat/features/news/domain/daily_brief.dart';

abstract interface class DailyNewsGateway {
  Future<DailyBrief> fetch(String accessToken);
}
