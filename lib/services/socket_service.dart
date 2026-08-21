import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;

  void Function(Map<String, dynamic>)? onAlarmCreated;
  void Function(Map<String, dynamic>)? onAlarmTriggered;
  void Function(Map<String, dynamic>)? onAlarmCancelled;
  void Function(Map<String, dynamic>)? onConnectionRequested;
  void Function(Map<String, dynamic>)? onConnectionAccepted;

  void connect(String baseUrl, String token) {
    _socket?.disconnect();

    _socket = io.io(
      baseUrl.replaceAll('/api', ''),
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .build(),
    );

    _socket!.on('alarm:created', (data) => onAlarmCreated?.call(Map<String, dynamic>.from(data)));
    _socket!.on('alarm:triggered', (data) => onAlarmTriggered?.call(Map<String, dynamic>.from(data)));
    _socket!.on('alarm:cancelled', (data) => onAlarmCancelled?.call(Map<String, dynamic>.from(data)));
    _socket!.on('connection:requested', (data) => onConnectionRequested?.call(Map<String, dynamic>.from(data)));
    _socket!.on('connection:accepted', (data) => onConnectionAccepted?.call(Map<String, dynamic>.from(data)));

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
