import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/network/dio_provider.dart';
import 'package:instant_chat/features/system_status/data/dio_health_gateway.dart';
import 'package:instant_chat/features/system_status/domain/health_gateway.dart';
import 'package:instant_chat/features/system_status/domain/service_health.dart';

final healthGatewayProvider = Provider<HealthGateway>((ref) {
  return DioHealthGateway(ref.watch(dioProvider));
});

final serviceHealthProvider = FutureProvider.autoDispose<ServiceHealth>((ref) {
  return ref.watch(healthGatewayProvider).fetch();
});
