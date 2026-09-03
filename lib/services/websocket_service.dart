import 'dart:developer';
import 'package:socket_io_client/socket_io_client.dart' as io;

class WebSocketService {
  io.Socket? _socket;
  bool _isConnected = false;
  final Map<String, Function(dynamic)> _eventHandlers = {};
  Function()? _onConnectCallback;

  bool get isConnected => _isConnected;

  void setOnConnectCallback(Function() callback) {
    _onConnectCallback = callback;
  }

  void connect(
    String baseUrl, {
    String? authToken,
    Map<String, dynamic>? query,
    bool reconnect = true,
    String path = '/socket.io',
  }) {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
    }

    final options = io.OptionBuilder()
        .setTransports(['websocket'])
        .setPath(path)
        .enableForceNew()
        .disableAutoConnect()
        .setTimeout(10000);

    if (reconnect) {
      options
          .enableReconnection()
          .setReconnectionAttempts(double.infinity)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(10000);
    } else {
      options.disableReconnection();
    }

    if (authToken?.isNotEmpty == true) {
      options.setAuth({'token': authToken});
    }

    if (query != null && query.isNotEmpty) {
      options.setQuery(query);
    }

    log('[WS] Connecting to $baseUrl (reconnect=$reconnect)');
    _socket = io.io(baseUrl, options.build());
    _setupSocketListeners();
    _socket!.connect();
  }

  void _setupSocketListeners() {
    _socket!.onConnect((_) {
      _isConnected = true;
      log('[WS] Connected');

      _eventHandlers.forEach((event, handler) {
        _socket!.off(event);
        _socket!.on(event, handler);
      });

      _onConnectCallback?.call();
    });

    _socket!.onAny((event, data) {
      log('[WS] RAW EVENT: $event — $data');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      log('[WS] Disconnected — Socket.IO will attempt reconnect');
    });

    _socket!.onConnectError((error) {
      log('[WS] Connection error: $error');
    });

    _socket!.onError((error) {
      log('[WS] Error: $error');
    });
  }

  void onEvent(String event, Function(dynamic) handler) {
    _socket?.off(event);
    _eventHandlers[event] = handler;
    if (_socket != null && _isConnected) {
      _socket!.on(event, handler);
      log('[WS] Listener registered for: $event');
    }
  }

  void emit(String event, dynamic data) {
    if (_socket != null && _isConnected) {
      _socket!.emit(event, data);
      log('[WS] Emitted: $event — $data');
    } else {
      log('[WS] Not connected — cannot emit: $event');
    }
  }

  void off(String event) {
    _socket?.off(event);
    _eventHandlers.remove(event);
  }

  void disconnect() {
    _socket?.disconnect();
    _eventHandlers.clear();
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
