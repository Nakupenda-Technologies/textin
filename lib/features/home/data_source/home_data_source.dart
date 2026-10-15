import '../../../config/constants/endpoints.dart';
import '../../../core/errors/failure.dart';
import '../../../core/network/client.dart';
import '../models/user_profile.dart';

abstract class HomeDataSource {
  Future<UserProfile> fetchUserProfile();
}

class HomeRemoteDataSource implements HomeDataSource {
  HomeRemoteDataSource(this.client);

  final BaseApiClients client;

  @override
  Future<UserProfile> fetchUserProfile() async {
    final dynamic response = await client.get(Endpoints.profile);
    if (response is Map<String, dynamic>) {
      final data = response['data'] ?? response;
      if (data is Map<String, dynamic>) {
        return UserProfile.fromJson(data);
      }
    }
    throw const ServerFailure('Invalid profile response');
  }
}
