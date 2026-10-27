import '../../../config/constants/endpoints.dart';
import '../../../core/network/client.dart';
import '../models/live_whisper.dart';
import '../models/my_whisper.dart';

abstract class WhispersRemoteDataSource {
  Future<List<LiveWhisper>> fetchLiveWhispers();
  Future<List<MyWhisper>> fetchMyWhispers();
  Future<void> createWhisper({
    required String title,
    required bool isPrivate,
    DateTime? scheduledAt,
  });
}

class WhispersRemoteDataSourceImpl implements WhispersRemoteDataSource {
  WhispersRemoteDataSourceImpl(this.client);

  final BaseApiClients client;

  @override
  Future<List<LiveWhisper>> fetchLiveWhispers() async {
    final dynamic response = await client.get(
      Endpoints.liveWhispers,
      queryParameters: {'limit': '50'},
    );
    return LiveWhisper.listFromResponse(response);
  }

  @override
  Future<List<MyWhisper>> fetchMyWhispers() async {
    final dynamic response = await client.get(
      Endpoints.myWhispers,
      queryParameters: {'limit': '50'},
    );
    return MyWhisper.listFromResponse(response);
  }

  @override
  Future<void> createWhisper({
    required String title,
    required bool isPrivate,
    DateTime? scheduledAt,
  }) async {
    await client.post(
      Endpoints.whispers,
      body: {
        'title': title,
        'visibility': isPrivate ? 'private' : 'public',
        'scheduledAt': ?scheduledAt?.toUtc().toIso8601String(),
      },
    );
  }
}
