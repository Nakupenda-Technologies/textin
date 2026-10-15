import '../../../config/constants/endpoints.dart';
import '../../../core/errors/failure.dart';
import '../../../core/network/client.dart';
import '../models/listed_user.dart';
import '../models/user_settings.dart';

enum UserListKind { blocked, muted }

abstract class SettingsRemoteDataSource {
  Future<UserSettings> fetchSettings();
  Future<UserSettings> updateSettings(UserSettings settings);
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> changes);
  Future<String> uploadProfilePicture(String filePath, String contentType);
  Future<void> requestEmailChange(String newEmail);
  Future<void> confirmEmailChange(String newEmail, String code);
  Future<void> changePassword(String currentPassword, String newPassword);
  Future<void> deactivateAccount();
  Future<void> deleteAccount(String? password);
  Future<List<ListedUser>> fetchUsers(UserListKind kind);
  Future<void> removeUser(UserListKind kind, String userId);
}

class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  SettingsRemoteDataSourceImpl(this.client);

  final BaseApiClients client;

  String _listEndpoint(UserListKind kind) => switch (kind) {
    UserListKind.blocked => Endpoints.blockedUsers,
    UserListKind.muted => Endpoints.mutedUsers,
  };

  @override
  Future<UserSettings> fetchSettings() async =>
      UserSettings.fromResponse(await client.get(Endpoints.settings));

  @override
  Future<UserSettings> updateSettings(UserSettings settings) async =>
      UserSettings.fromResponse(
        await client.patch(Endpoints.settings, body: settings.toJson()),
      );

  @override
  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> changes,
  ) async {
    final dynamic response = await client.put(Endpoints.me, body: changes);
    final data = response is Map<String, dynamic> ? response['data'] : null;
    return data is Map<String, dynamic> ? data : const {};
  }

  @override
  Future<String> uploadProfilePicture(
    String filePath,
    String contentType,
  ) async {
    final dynamic response = await client.upload(
      Endpoints.profilePictureUpload,
      field: 'file',
      filePath: filePath,
      contentType: contentType,
    );
    final data = response is Map<String, dynamic> ? response['data'] : null;
    final url = data is Map<String, dynamic> ? data['url'] : null;
    if (url is String && url.isNotEmpty) return url;
    throw const ServerFailure('The upload did not return a picture URL');
  }

  @override
  Future<void> requestEmailChange(String newEmail) =>
      client.post(Endpoints.emailChangeRequest, body: {'newEmail': newEmail});

  @override
  Future<void> confirmEmailChange(String newEmail, String code) => client.post(
    Endpoints.emailChangeConfirm,
    body: {'newEmail': newEmail, 'code': code},
  );

  @override
  Future<void> changePassword(String currentPassword, String newPassword) =>
      client.put(
        Endpoints.changePassword,
        body: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );

  @override
  Future<void> deactivateAccount() => client.post(Endpoints.deactivateAccount);

  @override
  Future<void> deleteAccount(String? password) => client.post(
    Endpoints.deleteAccount,
    body: {if (password != null && password.isNotEmpty) 'password': password},
  );

  @override
  Future<List<ListedUser>> fetchUsers(UserListKind kind) async {
    final dynamic response = await client.get(_listEndpoint(kind));
    final data = response is Map<String, dynamic> ? response['data'] : null;
    final ids = data is Map<String, dynamic> ? data['userIds'] : null;
    if (ids is! List) return const [];

    return Future.wait(
      ids.whereType<String>().map(
        (id) async => ListedUser.fromResponse(
          id,
          await client.get(Endpoints.userById(id)),
        ),
      ),
    );
  }

  @override
  Future<void> removeUser(UserListKind kind, String userId) =>
      client.delete('${_listEndpoint(kind)}/$userId');
}
