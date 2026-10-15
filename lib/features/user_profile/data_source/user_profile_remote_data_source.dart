import '../../../config/constants/endpoints.dart';
import '../../../core/network/client.dart';
import '../models/user_profile.dart';

abstract class UserProfileRemoteDataSource {
  Future<UserProfile> fetchProfile(String userId);
  Future<void> setBlocked(String userId, {required bool blocked});
  Future<void> setMuted(String userId, {required bool muted});
}

class UserProfileRemoteDataSourceImpl implements UserProfileRemoteDataSource {
  UserProfileRemoteDataSourceImpl(this.client);

  final BaseApiClients client;

  @override
  Future<UserProfile> fetchProfile(String userId) async {
    final results = await Future.wait<dynamic>([
      client.get(Endpoints.userById(userId)),
      _userIds(Endpoints.blockedUsers),
      _userIds(Endpoints.mutedUsers),
    ]);
    return UserProfile.fromResponse(
      results[0],
      isBlocked: (results[1] as Set<String>).contains(userId),
      isMuted: (results[2] as Set<String>).contains(userId),
    );
  }

  @override
  Future<void> setBlocked(String userId, {required bool blocked}) =>
      _toggle(Endpoints.blockedUsers, userId, on: blocked);

  @override
  Future<void> setMuted(String userId, {required bool muted}) =>
      _toggle(Endpoints.mutedUsers, userId, on: muted);

  Future<void> _toggle(String endpoint, String userId, {required bool on}) => on
      ? client.post(endpoint, body: {'userId': userId})
      : client.delete('$endpoint/$userId');

  Future<Set<String>> _userIds(String endpoint) async {
    final dynamic response = await client.get(endpoint);
    final data = response is Map<String, dynamic> ? response['data'] : null;
    final ids = data is Map<String, dynamic> ? data['userIds'] : null;
    return ids is List ? ids.whereType<String>().toSet() : const {};
  }
}
