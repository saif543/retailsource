class ApiConfig {
  // Use 10.0.2.2 for Android emulator (maps to host machine localhost)
  // Use localhost for web/desktop
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  // Auth endpoints
  static const String register = '$baseUrl/auth/register';
  static const String login = '$baseUrl/auth/login';
  static const String me = '$baseUrl/auth/me';
}
