import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/api_config.dart';
import 'config/theme.dart';
import 'models/alarm.dart';
import 'providers/auth_provider.dart';
import 'providers/alarm_provider.dart';
import 'providers/location_provider.dart';
import 'services/socket_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/map/map_screen.dart';
import 'screens/alarms/my_alarms_screen.dart';
import 'screens/incoming/incoming_screen.dart';
import 'screens/connections/connections_screen.dart';
import 'screens/alarm_alert/full_screen_alert.dart';

void main() {
  runApp(const ProviderScope(child: GeoBuzzerApp()));
}

class GeoBuzzerApp extends ConsumerWidget {
  const GeoBuzzerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'GeoBuzzer',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  @override
  void initState() {
    super.initState();
    ref.read(authProvider.notifier).checkAuth();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    if (authState.user != null) {
      return const MainShell();
    }
    return const LoginScreen();
  }
}

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final _socketService = SocketService();
  bool _alertShowing = false;

  final _screens = const [
    MapScreen(),
    MyAlarmsScreen(),
    IncomingScreen(),
    ConnectionsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startServices();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ref.read(geofenceMonitorProvider).stop();
    _socketService.disconnect();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(geofenceMonitorProvider).start();
      ref.read(alarmProvider.notifier).loadTargetingMe();
    } else if (state == AppLifecycleState.paused) {
      ref.read(geofenceMonitorProvider).stop();
    }
  }

  void _startServices() {
    ref.read(alarmProvider.notifier).loadTargetingMe();

    final monitor = ref.read(geofenceMonitorProvider);
    monitor.onAlarmTriggered = _showAlert;
    monitor.start();

    _socketService.onAlarmCreated = (_) => ref.read(alarmProvider.notifier).loadTargetingMe();
    _socketService.onAlarmCancelled = (_) => ref.read(alarmProvider.notifier).loadTargetingMe();
    _socketService.onAlarmTriggered = (_) => ref.read(alarmProvider.notifier).loadMyAlarms();

    final token = ref.read(apiServiceProvider).accessToken;
    if (token != null) {
      _socketService.connect(ApiConfig.baseUrl, token);
    }
  }

  void _showAlert(AlarmModel alarm) {
    if (_alertShowing) return;
    _alertShowing = true;
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => FullScreenAlert(
          alarm: alarm,
          onDismiss: () {
            _alertShowing = false;
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.alarm_outlined), activeIcon: Icon(Icons.alarm), label: 'My Alarms'),
          BottomNavigationBarItem(icon: Icon(Icons.inbox_outlined), activeIcon: Icon(Icons.inbox), label: 'Incoming'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outlined), activeIcon: Icon(Icons.people), label: 'Connections'),
        ],
      ),
    );
  }
}
