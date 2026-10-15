import '../../../config/constants/endpoints.dart';
import '../../../core/network/client.dart';
import '../models/live_whisper.dart';

abstract class WhispersRemoteDataSource {
  Future<List<LiveWhisper>> fetchLiveWhispers();
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
}
