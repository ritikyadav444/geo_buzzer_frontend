class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  static const String signup = '/auth/signup';
  static const String verifyOtp = '/auth/verify-otp';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';

  static const String connectionRequest = '/connections/request';
  static const String connections = '/connections';

  static const String alarms = '/alarms';
  static const String myAlarms = '/alarms/mine';
  static const String targetingMe = '/alarms/targeting-me';
}
