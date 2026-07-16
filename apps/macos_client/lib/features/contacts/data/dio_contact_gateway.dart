import 'package:dio/dio.dart';
import 'package:instant_chat/core/network/api_response.dart';
import 'package:instant_chat/features/contacts/domain/contact.dart';
import 'package:instant_chat/features/contacts/domain/contact_gateway.dart';
import 'package:instant_chat/features/contacts/domain/contact_request.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

class DioContactGateway implements ContactGateway {
  const DioContactGateway(this._dio);

  final Dio _dio;

  @override
  Future<PublicUser> searchUser({
    required String accessToken,
    required String username,
  }) async {
    final response = await apiRequest(
      () => _dio.get<Object?>(
        '/api/v1/users/search',
        queryParameters: {'username': username},
        options: _options(accessToken),
      ),
    );
    expectStatus(response, {200});
    final user = responseObject(response.data)['user'];
    return PublicUser.fromJson(_requiredObject(user, 'user'));
  }

  @override
  Future<ContactRequest> sendRequest({
    required String accessToken,
    required String username,
  }) async {
    final response = await apiRequest(
      () => _dio.post<Object?>(
        '/api/v1/contact-requests',
        data: {'username': username},
        options: _options(accessToken),
      ),
    );
    expectStatus(response, {201});
    return ContactRequest.fromJson(responseObject(response.data));
  }

  @override
  Future<ContactRequestLists> listRequests(String accessToken) async {
    final response = await apiRequest(
      () => _dio.get<Object?>(
        '/api/v1/contact-requests',
        options: _options(accessToken),
      ),
    );
    expectStatus(response, {200});
    final body = responseObject(response.data);
    return ContactRequestLists(
      incoming: _requests(body, 'incoming'),
      outgoing: _requests(body, 'outgoing'),
    );
  }

  @override
  Future<Contact> acceptRequest({
    required String accessToken,
    required String requestId,
  }) async {
    final response = await apiRequest(
      () => _dio.post<Object?>(
        '/api/v1/contact-requests/$requestId/accept',
        options: _options(accessToken),
      ),
    );
    expectStatus(response, {200});
    return Contact.fromJson(responseObject(response.data));
  }

  @override
  Future<void> rejectRequest({
    required String accessToken,
    required String requestId,
  }) async {
    final response = await apiRequest(
      () => _dio.post<Object?>(
        '/api/v1/contact-requests/$requestId/reject',
        options: _options(accessToken),
      ),
    );
    expectStatus(response, {204});
  }

  @override
  Future<List<Contact>> listContacts(String accessToken) async {
    final response = await apiRequest(
      () =>
          _dio.get<Object?>('/api/v1/contacts', options: _options(accessToken)),
    );
    expectStatus(response, {200});
    final body = responseObject(response.data);
    return requiredList(body, 'contacts')
        .map((item) => Contact.fromJson(_requiredObject(item, 'contact')))
        .toList(growable: false);
  }

  @override
  Future<void> removeContact({
    required String accessToken,
    required String userId,
  }) async {
    final response = await apiRequest(
      () => _dio.delete<Object?>(
        '/api/v1/contacts/$userId',
        options: _options(accessToken),
      ),
    );
    expectStatus(response, {204});
  }

  Options _options(String token) =>
      Options(headers: bearerAuthorization(token));

  List<ContactRequest> _requests(Map<String, Object?> body, String key) {
    return requiredList(body, key)
        .map((item) => ContactRequest.fromJson(_requiredObject(item, key)))
        .toList(growable: false);
  }
}

Map<String, Object?> _requiredObject(Object? value, String name) {
  if (value is! Map<Object?, Object?>) {
    throw FormatException('$name must be a JSON object');
  }
  return stringKeyedObject(value);
}
