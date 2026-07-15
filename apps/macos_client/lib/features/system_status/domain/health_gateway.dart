import 'package:instant_chat/features/system_status/domain/service_health.dart';

abstract interface class HealthGateway {
  Future<ServiceHealth> fetch();
}
