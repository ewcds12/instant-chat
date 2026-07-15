import 'package:dio/dio.dart';
import 'package:instant_chat/features/system_status/domain/health_gateway.dart';
import 'package:instant_chat/features/system_status/domain/service_health.dart';

class DioHealthGateway implements HealthGateway {
  const DioHealthGateway(this._dio);

  final Dio _dio;

  @override
  Future<ServiceHealth> fetch() async {
    final response = await _dio.get<Object?>('/api/v1/health');
    final statusCode = response.statusCode;
    if (statusCode != 200 && statusCode != 503) {
      throw StateError('Unexpected health response status: $statusCode');
    }

    final body = response.data;
    if (body is! Map<Object?, Object?>) {
      throw const FormatException('Health response must be a JSON object');
    }

    final json = <String, Object?>{};
    for (final entry in body.entries) {
      final key = entry.key;
      if (key is! String) {
        throw const FormatException('Health response keys must be strings');
      }
      json[key] = entry.value;
    }
    return ServiceHealth.fromJson(json);
  }
}
