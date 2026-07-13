class AccessResultModel {
  final String access; // 'full' | 'preview' | 'denied'
  final String? signedUrl;
  final String? reason;
  final int? freePageCount;
  final int? pagesConsumed;
  final int? remaining;

  const AccessResultModel({
    required this.access,
    this.signedUrl,
    this.reason,
    this.freePageCount,
    this.pagesConsumed,
    this.remaining,
  });

  bool get isFull => access == 'full';
  bool get isPreview => access == 'preview';
  bool get isDenied => access == 'denied';

  factory AccessResultModel.fromJson(Map<String, dynamic> json) {
    return AccessResultModel(
      access: json['access'] as String,
      signedUrl: json['signedUrl'] as String?,
      reason: json['reason'] as String?,
      freePageCount: (json['freePageCount'] as num?)?.toInt(),
      pagesConsumed: (json['pagesConsumed'] as num?)?.toInt(),
      remaining: (json['remaining'] as num?)?.toInt(),
    );
  }
}
