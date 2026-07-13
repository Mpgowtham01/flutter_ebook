import 'package:flutter/foundation.dart';
import '../data/models/book_model.dart';
import '../data/models/offline_book_model.dart';
import '../data/services/api_service.dart';
import '../data/services/offline_service.dart';

class BooksProvider extends ChangeNotifier {
  final _api = ApiService();
  final _offline = OfflineService();

  List<BookModel> _books = [];
  List<OfflineBookModel> _offlineBooks = [];
  bool _loading = false;
  bool _offlineLoading = false;
  String? _error;

  // Download state per book: null = not downloading, 0.0-1.0 = progress
  final Map<String, double?> _downloadProgress = {};
  final Set<String> _downloadedIds = {};

  List<BookModel> get books => _books;
  List<OfflineBookModel> get offlineBooks => _offlineBooks;
  bool get loading => _loading;
  bool get offlineLoading => _offlineLoading;
  String? get error => _error;

  double? downloadProgressOf(String bookId) => _downloadProgress[bookId];
  bool isDownloaded(String bookId) => _downloadedIds.contains(bookId);
  bool isDownloading(String bookId) =>
      _downloadProgress.containsKey(bookId) &&
      _downloadProgress[bookId] != null;

  Future<void> fetchBooks() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _books = await _api.getBooks();
      await _syncDownloadedSet();
    } catch (e) {
      _error = _api.friendlyError(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchOfflineBooks() async {
    _offlineLoading = true;
    notifyListeners();
    try {
      await _offline.purgeExpired();
      _offlineBooks = await _offline.getAllBooks();
      _syncDownloadedSet();
    } finally {
      _offlineLoading = false;
      notifyListeners();
    }
  }

  Future<void> _syncDownloadedSet() async {
    final all = await _offline.getAllBooks();
    _downloadedIds
      ..clear()
      ..addAll(all.map((b) => b.bookId));
  }

  Future<void> downloadBook(BookModel book, String userId) async {
    if (isDownloading(book.id)) return;

    _downloadProgress[book.id] = 0.0;
    notifyListeners();
    print('Starting download for book ${book.id}');
    try {
      final token = await _api.getDownloadToken(book.id);
      print('Download token for book ${book.id}: $token');
      final bytes = await _api.downloadEncryptedEpub(
        book.id,
        token,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            _downloadProgress[book.id] = received / total;
            notifyListeners();
          }
        },
      );
      await _offline.saveBook(
        book: book,
        encryptedBytes: bytes,
        downloadToken: token,
        userId: userId,
      );
      _downloadedIds.add(book.id);
      _downloadProgress.remove(book.id);
      await fetchOfflineBooks();
    } catch (e) {
      _downloadProgress.remove(book.id);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteOfflineBook(String bookId) async {
    await _offline.deleteBook(bookId);
    _downloadedIds.remove(bookId);
    _offlineBooks.removeWhere((b) => b.bookId == bookId);
    notifyListeners();
  }
}
