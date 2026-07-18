import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/network/dio_provider.dart';
import 'package:instant_chat/features/profile/data/dio_profile_gateway.dart';
import 'package:instant_chat/features/profile/domain/profile_gateway.dart';

final profileGatewayProvider = Provider<ProfileGateway>((ref) {
  return DioProfileGateway(ref.watch(dioProvider));
});
