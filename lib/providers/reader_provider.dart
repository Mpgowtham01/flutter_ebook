import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../data/models/access_result_model.dart';
import '../data/services/api_service.dart';
import '../data/services/offline_service.dart';
import '../data/database/database_helper.dart';

enum ReaderLoadState { idle, loading, loaded, error }

class ReaderProvider extends ChangeNotifier {
  final _api = ApiService();
  final _offline = OfflineService();
  final _db = DatabaseHelper();

  ReaderLoadState _state = ReaderLoadState.idle;
  Uint8List? _epubBytes;
  AccessResultModel? _access;
  String? _errorMessage;
  bool _isOfflineMode = false;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _previewLimitReached = false;

  ReaderLoadState get state => _state;
  Uint8List? get epubBytes => _epubBytes;
  AccessResultModel? get access => _access;
  String? get errorMessage => _errorMessage;
  bool get isOfflineMode => _isOfflineMode;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get previewLimitReached => _previewLimitReached;

  Future<void> loadBook({required String bookId, required bool forceOffline}) async {
    _state = ReaderLoadState.loading;
    _epubBytes = null;
    _access = null;
    _errorMessage = null;
    _previewLimitReached = false;
    notifyListeners();

    if (forceOffline) {
      await _loadOffline(bookId);
      return;
    }

    try {
      _access = await _api.checkAccess(bookId);
      if (_access!.isDenied) {
        _errorMessage = _access!.reason ?? 'Access denied';
        _state = ReaderLoadState.error;
        notifyListeners();
        return;
      }
      if (_access!.isPreview && (_access!.remaining ?? 1) <= 0) {
        _previewLimitReached = true;
        _state = ReaderLoadState.error;
        notifyListeners();
        return;
      }
      final dio = Dio();
      final response = await dio.get(
        _access!.signedUrl!,
        options: Options(responseType: ResponseType.bytes),
      );
      _epubBytes = Uint8List.fromList(response.data as List<int>);
      _isOfflineMode = false;
      _state = ReaderLoadState.loaded;
      notifyListeners();
    } catch (e) {
      final offlineBook = await _offline.getBook(bookId);
      if (offlineBook != null) {
        await _loadOffline(bookId);
      } else {
        _errorMessage = 'No internet connection and book is not downloaded.';
        _state = ReaderLoadState.error;
        notifyListeners();
      }
    }
  }

  Future<void> _loadOffline(String bookId) async {
    try {
      _epubBytes = await _offline.getDecryptedBytes(bookId);
      _isOfflineMode = true;
      _state = ReaderLoadState.loaded;
      final progress = await _db.getLocalProgress(bookId);
      if (progress != null) {
        _currentPage = progress['current_page'] as int;
        _totalPages = progress['total_pages'] as int;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _state = ReaderLoadState.error;
    }
    notifyListeners();
  }

  Future<void> onPageChanged({
    required String bookId,
    required int currentPage,
    required int totalPages,
    String? currentChapter,
  }) async {
    _currentPage = currentPage;
    _totalPages = totalPages;
    if (_isOfflineMode) {
      await _db.upsertLocalProgress(
        bookId: bookId,
        currentPage: currentPage,
        totalPages: totalPages,
        percentage: totalPages > 0 ? (currentPage / totalPages * 100) : 0,
        currentChapter: currentChapter,
      );
      return;
    }
    try {
      await _api.saveProgress(bookId,
          currentPage: currentPage,
          totalPages: totalPages,
          currentChapter: currentChapter,
          pagesConsumedDelta: 1);
    } catch (_) {}
  }

  void reset() {
    _state = ReaderLoadState.idle;
    _epubBytes = null;
    _access = null;
    _errorMessage = null;
    _isOfflineMode = false;
    _currentPage = 1;
    _totalPages = 0;
    _previewLimitReached = false;
  }
}
