class ApiEndpoints {
  // Real device: use actual machine IP (10.0.2.2 is emulator-only)
  static const String baseUrl = 'http://192.168.1.32:5000/api';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';
  static const String meStats = '/auth/me/stats';

  // Books
  static const String books = '/books';
  static String bookById(String id) => '/books/$id';

  // Reader
  static String bookAccess(String id) => '/reader/$id/access';
  static String saveProgress(String id) => '/reader/$id/progress';
  static String getProgress(String id) => '/reader/$id/progress';
  static String downloadToken(String id) => '/reader/$id/download-token';
  static String downloadBook(String id) => '/reader/$id/download';

  // Subscriptions
  static const String subscription = '/subscriptions/me';

  // Health
  static const String health = '/health';
}
