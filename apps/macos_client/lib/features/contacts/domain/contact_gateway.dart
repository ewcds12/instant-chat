import 'package:instant_chat/features/contacts/domain/contact.dart';
import 'package:instant_chat/features/contacts/domain/contact_request.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

abstract interface class ContactGateway {
  Future<PublicUser> searchUser({
    required String accessToken,
    required String username,
  });

  Future<ContactRequest> sendRequest({
    required String accessToken,
    required String username,
  });

  Future<ContactRequestLists> listRequests(String accessToken);

  Future<Contact> acceptRequest({
    required String accessToken,
    required String requestId,
  });

  Future<void> rejectRequest({
    required String accessToken,
    required String requestId,
  });

  Future<List<Contact>> listContacts(String accessToken);

  Future<void> removeContact({
    required String accessToken,
    required String userId,
  });
}
