class OfflineBookModel {
  final String bookId;
  final String title;
  final String author;
  final String category;
  final String? coverUrl;
  final String filePath;
  final String xorKeyHex;
  final DateTime downloadedAt;
  final DateTime expiresAt;

  const OfflineBookModel({
    required this.bookId,
    required this.title,
    required this.author,
    required this.category,
    this.coverUrl,
    required this.filePath,
    required this.xorKeyHex,
    required this.downloadedAt,
    required this.expiresAt,
  });

  bool get isExpired => expiresAt.isBefore(DateTime.now());

  factory OfflineBookModel.fromMap(Map<String, dynamic> map) {
    return OfflineBookModel(
      bookId: map['book_id'] as String,
      title: map['title'] as String,
      author: map['author'] as String,
      category: map['category'] as String,
      coverUrl: map['cover_url'] as String?,
      filePath: map['file_path'] as String,
      xorKeyHex: map['xor_key_hex'] as String,
      downloadedAt: DateTime.fromMillisecondsSinceEpoch(map['downloaded_at'] as int),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(map['expires_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'book_id': bookId,
      'title': title,
      'author': author,
      'category': category,
      'cover_url': coverUrl,
      'file_path': filePath,
      'xor_key_hex': xorKeyHex,
      'downloaded_at': downloadedAt.millisecondsSinceEpoch,
      'expires_at': expiresAt.millisecondsSinceEpoch,
    };
  }
}
