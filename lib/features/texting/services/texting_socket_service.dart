import '../../../config/env/env.dart';
import '../../../services/websocket_service.dart';
import '../models/api/chat_message_api.dart';

class TextingSocketService {
  TextingSocketService(this._ws, {String? Function()? accessToken})
    : _accessToken = accessToken ?? _noToken;

  final WebSocketService _ws;
  final String? Function() _accessToken;

  static String? _noToken() => null;

  void connect() {
    final token = _accessToken() ?? '';
    final url = '${Env.websocketBaseUrl}/messaging';
    _ws.connect(
      url,
      authToken: token.isEmpty ? null : token,
      path: Env.socketPath,
    );
  }

  void disconnect() {
    _ws.disconnect();
  }

  void joinChat(String chatId) {
    _ws.emit('join_chat', {'chatId': chatId});
  }

  void leaveChat(String chatId) {
    _ws.emit('leave_chat', {'chatId': chatId});
  }

  void Function() onNewMessage(
    void Function(Map<String, dynamic> data) callback,
  ) {
    return _ws.onEvent('message', (data) {
      if (data is Map<String, dynamic>) callback(ChatMessageApi.unwrap(data));
    });
  }

  void Function() onTyping(
    void Function(String chatId, String userId, bool isTyping) callback,
  ) {
    return _ws.onEvent('typing', (data) {
      if (data is! Map<String, dynamic>) return;
      final chatId = data['chatId'] as String?;
      final userId = data['userId'] as String?;
      final isTyping = data['isTyping'] as bool? ?? false;
      if (chatId != null && userId != null) callback(chatId, userId, isTyping);
    });
  }

  void sendTyping(String chatId, {required bool isTyping}) {
    _ws.emit('typing', {'chatId': chatId, 'isTyping': isTyping});
  }
}
