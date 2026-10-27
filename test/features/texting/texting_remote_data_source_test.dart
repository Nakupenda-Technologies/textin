import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:textin/core/network/client.dart';
import 'package:textin/features/texting/data_source/texting_remote_data_source.dart';

TextingRemoteDataSourceImpl _dataSource(Object body) =>
    TextingRemoteDataSourceImpl(
      BaseApiClients(
        baseUrl: 'https://api.test',
        client: MockClient((_) async => http.Response(jsonEncode(body), 200)),
      ),
    );

void main() {
  test('reads the following list from its users field', () async {
    final dataSource = _dataSource({
      'success': true,
      'data': {
        'users': [
          {'id': 'u2', 'username': 'ada', 'displayName': 'Ada Obi'},
        ],
        'nextCursor': null,
      },
    });

    final users = await dataSource.fetchFollowingUsers('me');

    expect(users.map((u) => u.username), ['ada']);
  });

  test('starting a chat reads a response without the other user', () async {
    final dataSource = _dataSource({
      'id': 'chat_1',
      'createdAt': '2026-10-27T10:00:00.000Z',
    });

    final chat = await dataSource.startOrGetChat(otherUserId: 'u2');

    expect(chat.id, 'chat_1');
  });
}
