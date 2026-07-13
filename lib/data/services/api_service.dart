import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../models/book_model.dart';
import '../models/subscription_model.dart';
import '../models/access_result_model.dart';
import '../../core/constants/api_endpoints.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'ebook_jwt_token';
  static const _userIdKey = 'ebook_user_id';

  void Function()? onUnauthorized;

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getToken();
        print('ApiService: Adding token to request: $token');
        print('Request URL: ${options.uri}');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          onUnauthorized?.call();
        }
        return handler.next(error);
      },
    ));
  }

  // Token management
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<void> saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  Future<String?> getUserId() async {
    return _storage.read(key: _userIdKey);
  }

  Future<void> clearAuth() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Auth
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post(ApiEndpoints.login, data: {
      'email': email,
      'password': password,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    final response = await _dio.post(ApiEndpoints.register, data: {
      'name': name,
      'email': email,
      'password': password,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<UserModel> getMe() async {
    final response = await _dio.get(ApiEndpoints.me);
    return UserModel.fromJson(response.data['user'] ?? response.data);
  }

  // Books
  Future<List<BookModel>> getBooks({String? query, String? category}) async {
    final queryParams = <String, dynamic>{};
    if (query != null && query.isNotEmpty) queryParams['q'] = query;
    if (category != null && category.isNotEmpty)
      queryParams['category'] = category;

    final response = await _dio.get(ApiEndpoints.books,
        queryParameters: queryParams.isNotEmpty ? queryParams : null);

    final data = response.data;
    final List list =
        data is List ? data : (data['books'] ?? data['data'] ?? []);
    return list
        .map((e) => BookModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Reader access
  Future<AccessResultModel> checkAccess(String bookId) async {
    final response = await _dio.get(ApiEndpoints.bookAccess(bookId));
    return AccessResultModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> saveProgress(String bookId,
      {required int currentPage,
      required int totalPages,
      String? currentChapter,
      int pagesConsumedDelta = 0}) async {
    await _dio.post(ApiEndpoints.saveProgress(bookId), data: {
      'currentPage': currentPage,
      'totalPages': totalPages,
      if (currentChapter != null) 'currentChapter': currentChapter,
      'pagesConsumedDelta': pagesConsumedDelta,
    });
  }

  // Download token
  Future<String> getDownloadToken(String bookId) async {
    try {
      final response = await _dio.get(ApiEndpoints.downloadToken(bookId));
      print('response : ${response.statusCode} ${response.statusMessage}');
      final data = response.data;
      return (data['downloadToken'] ?? data['token']) as String;
    }  on DioException catch (e) {

    return (e.message ?? 'Unknown error') as String;
  }  catch (e) {
      print('Error getting download token for book $bookId: $e');
      rethrow;
    }
  }

  // Download encrypted epub (returns raw bytes)
  Future<List<int>> downloadEncryptedEpub(
    String bookId,
    String token, {
    ProgressCallback? onReceiveProgress,
  }) async {
  
    final response = await _dio.get(
      ApiEndpoints.downloadBook(bookId),
      queryParameters: {'bookId': bookId},
      options: Options(responseType: ResponseType.bytes),
      onReceiveProgress: onReceiveProgress,
    );
    print('Downloaded ${response.data} bytes for book $bookId');
    return response.data as List<int>;
  }

  // Subscription
  Future<SubscriptionModel?> getSubscription() async {
    try {
      final response = await _dio.get(ApiEndpoints.subscription);
      final data = response.data;
      if (data == null) return null;
      return SubscriptionModel.fromJson(
          data is Map<String, dynamic> ? data : data['subscription']);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  String friendlyError(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        return data['message'] as String? ??
            data['error'] as String? ??
            'Something went wrong';
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Connection timed out. Check your network.';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Cannot reach server. Check your connection.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
