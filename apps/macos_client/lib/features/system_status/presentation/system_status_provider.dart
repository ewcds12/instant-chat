import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/config/app_config.dart';
import 'package:instant_chat/features/system_status/data/dio_health_gateway.dart';
import 'package:instant_chat/features/system_status/domain/health_gateway.dart';
import 'package:instant_chat/features/system_status/domain/service_health.dart';

final healthGatewayProvider = Provider<HealthGateway>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 2),
      receiveTimeout: const Duration(seconds: 2),
      validateStatus: (status) =>
          status != null && status >= 200 && status < 600,
    ),
  );
  ref.onDispose(dio.close);
  return DioHealthGateway(dio);
});

final serviceHealthProvider = FutureProvider.autoDispose<ServiceHealth>((ref) {
  return ref.watch(healthGatewayProvider).fetch();
});
