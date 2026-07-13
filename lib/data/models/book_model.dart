class BookModel {
  final String id;
  final String title;
  final String author;
  final String category;
  final String description;
  final String? coverUrl;
  final int totalPages;
  final String bookType; // 'free-preview' | 'fully-paid'
  final int freePageCount;
  final String status;
  final double rating;
  final int totalReads;

  const BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.description,
    this.coverUrl,
    required this.totalPages,
    required this.bookType,
    required this.freePageCount,
    required this.status,
    required this.rating,
    required this.totalReads,
  });

  bool get isFreePreview => bookType == 'free-preview';
  bool get isFullyPaid => bookType == 'fully-paid';

  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      id: json['_id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      category: json['category'] as String,
      description: json['description'] as String? ?? '',
      coverUrl: json['coverUrl'] as String?,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      bookType: json['bookType'] as String? ?? 'free-preview',
      freePageCount: (json['freePageCount'] as num?)?.toInt() ?? 20,
      status: json['status'] as String? ?? 'active',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalReads: (json['totalReads'] as num?)?.toInt() ?? 0,
    );
  }
}
