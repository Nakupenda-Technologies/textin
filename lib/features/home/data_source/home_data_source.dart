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
    return const UserProfile(
      id: '1',
      name: 'Textin User',
      status: 'Hey there! I am using Textin.',
    );
  }
}
