import '../../../config/env/env.dart';
import '../../../core/storage/shared_preferences_store.dart';
import '../../../services/websocket_service.dart';

class TextingSocketService {
  TextingSocketService(this._ws);

  final WebSocketService _ws;

  void connect({required void Function() onConnect}) {
    final token = SharedPreferencesStore.getAuthToken() ?? '';
    final url = '${Env.websocketBaseUrl}/messaging';
    _ws.setOnConnectCallback(onConnect);
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

  void onNewMessage(void Function(Map<String, dynamic> data) callback) {
    _ws.onEvent('message', (data) {
      if (data is Map<String, dynamic>) callback(data);
    });
  }

  void onTyping(void Function(String userId, bool isTyping) callback) {
    _ws.onEvent('typing', (data) {
      if (data is! Map<String, dynamic>) return;
      final userId = data['userId'] as String?;
      final isTyping = data['isTyping'] as bool? ?? false;
      if (userId != null) callback(userId, isTyping);
    });
  }

  void sendTyping(String chatId, {required bool isTyping}) {
    _ws.emit('typing', {'chatId': chatId, 'isTyping': isTyping});
  }
}
