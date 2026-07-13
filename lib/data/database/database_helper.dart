import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'ebook_mobile.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE offline_books (
        book_id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        category TEXT NOT NULL,
        cover_url TEXT,
        file_path TEXT NOT NULL,
        xor_key_hex TEXT NOT NULL,
        downloaded_at INTEGER NOT NULL,
        expires_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE reading_progress (
        book_id TEXT PRIMARY KEY,
        current_page INTEGER NOT NULL DEFAULT 1,
        total_pages INTEGER NOT NULL DEFAULT 0,
        percentage REAL NOT NULL DEFAULT 0,
        current_chapter TEXT,
        last_read_at INTEGER NOT NULL
      )
    ''');
  }

  // Offline books
  Future<void> upsertOfflineBook(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('offline_books', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllOfflineBooks() async {
    final db = await database;
    return db.query('offline_books', orderBy: 'downloaded_at DESC');
  }

  Future<Map<String, dynamic>?> getOfflineBook(String bookId) async {
    final db = await database;
    final results = await db.query('offline_books',
        where: 'book_id = ?', whereArgs: [bookId]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> deleteOfflineBook(String bookId) async {
    final db = await database;
    await db.delete('offline_books', where: 'book_id = ?', whereArgs: [bookId]);
  }

  Future<void> deleteExpiredBooks() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.delete('offline_books', where: 'expires_at < ?', whereArgs: [now]);
  }

  // Local reading progress
  Future<void> upsertLocalProgress({
    required String bookId,
    required int currentPage,
    required int totalPages,
    required double percentage,
    String? currentChapter,
  }) async {
    final db = await database;
    await db.insert(
      'reading_progress',
      {
        'book_id': bookId,
        'current_page': currentPage,
        'total_pages': totalPages,
        'percentage': percentage,
        'current_chapter': currentChapter,
        'last_read_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getLocalProgress(String bookId) async {
    final db = await database;
    final results = await db.query('reading_progress',
        where: 'book_id = ?', whereArgs: [bookId]);
    return results.isNotEmpty ? results.first : null;
  }
}
