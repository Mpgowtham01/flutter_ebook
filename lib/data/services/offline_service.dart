import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../database/database_helper.dart';
import '../models/offline_book_model.dart';
import '../models/book_model.dart';
import '../../core/utils/xor_encryption.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  final _db = DatabaseHelper();

  Future<Directory> get _booksDir async {
    final docDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docDir.path, 'books'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<void> saveBook({
    required BookModel book,
    required List<int> encryptedBytes,
    required String downloadToken,
    required String userId,
  }) async {
    final dir = await _booksDir;
    final filePath = p.join(dir.path, '${book.id}.ebk');

    // Write encrypted bytes to private app directory
    await File(filePath).writeAsBytes(encryptedBytes);

    // Derive and store XOR key (never store the raw token)
    final keyBytes = XorEncryption.deriveKey(downloadToken, userId);
    final keyHex = keyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    final downloadedAt = DateTime.now();
    final expiresAt = downloadedAt.add(const Duration(days: 7));

    await _db.upsertOfflineBook(OfflineBookModel(
      bookId: book.id,
      title: book.title,
      author: book.author,
      category: book.category,
      coverUrl: book.coverUrl,
      filePath: filePath,
      xorKeyHex: keyHex,
      downloadedAt: downloadedAt,
      expiresAt: expiresAt,
    ).toMap());
  }

  Future<List<OfflineBookModel>> getAllBooks() async {
    await _db.deleteExpiredBooks();
    final maps = await _db.getAllOfflineBooks();
    return maps.map(OfflineBookModel.fromMap).toList();
  }

  Future<OfflineBookModel?> getBook(String bookId) async {
    final map = await _db.getOfflineBook(bookId);
    if (map == null) return null;
    final book = OfflineBookModel.fromMap(map);
    if (book.isExpired) {
      await deleteBook(bookId);
      return null;
    }
    return book;
  }

  Future<bool> isDownloaded(String bookId) async {
    final book = await getBook(bookId);
    return book != null;
  }

  Future<Uint8List> getDecryptedBytes(String bookId) async {
    final book = await getBook(bookId);
    if (book == null) throw Exception('Book not found offline or has expired.');

    final file = File(book.filePath);
    if (!await file.exists()) {
      await _db.deleteOfflineBook(bookId);
      throw Exception('Offline file missing. Please re-download.');
    }

    final encrypted = await file.readAsBytes();
    final keyBytes = Uint8List.fromList(
      List.generate(32, (i) {
        final hex = book.xorKeyHex.substring(i * 2, i * 2 + 2);
        return int.parse(hex, radix: 16);
      }),
    );
    return XorEncryption.decrypt(encrypted, keyBytes);
  }

  Future<void> deleteBook(String bookId) async {
    final map = await _db.getOfflineBook(bookId);
    if (map != null) {
      final filePath = map['file_path'] as String;
      final file = File(filePath);
      if (await file.exists()) await file.delete();
    }
    await _db.deleteOfflineBook(bookId);
  }

  Future<void> purgeExpired() async {
    final all = await _db.getAllOfflineBooks();
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final map in all) {
      final expiresAt = map['expires_at'] as int;
      if (expiresAt < now) {
        final filePath = map['file_path'] as String;
        final file = File(filePath);
        if (await file.exists()) await file.delete();
      }
    }
    await _db.deleteExpiredBooks();
  }
}
