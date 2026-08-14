import 'package:dio/dio.dart';
import 'package:instant_chat/core/network/api_response.dart';
import 'package:instant_chat/features/news/domain/daily_brief.dart';
import 'package:instant_chat/features/news/domain/daily_news_gateway.dart';

class DioDailyNewsGateway implements DailyNewsGateway {
  const DioDailyNewsGateway(this._dio);

  final Dio _dio;

  @override
  Future<DailyBrief> fetch(String accessToken) async {
    final response = await apiRequest(
      () => _dio.get<Object?>(
        '/api/v1/news/daily',
        options: Options(headers: bearerAuthorization(accessToken)),
      ),
    );
    expectStatus(response, {200});
    return DailyBrief.fromJson(responseObject(response.data));
  }
}
