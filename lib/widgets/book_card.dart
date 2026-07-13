import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../data/models/book_model.dart';
import '../providers/books_provider.dart';
import '../providers/auth_provider.dart';

class BookCard extends StatelessWidget {
  final BookModel book;
  final VoidCallback onTap;

  const BookCard({super.key, required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer2<BooksProvider, AuthProvider>(
      builder: (context, books, auth, _) {
        final downloaded = books.isDownloaded(book.id);
        final downloading = books.isDownloading(book.id);
        final progress = books.downloadProgressOf(book.id) ?? 0.0;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.ink100),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover image
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        book.coverUrl != null
                            ? CachedNetworkImage(
                                imageUrl: book.coverUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: AppColors.canvas,
                                  child: const Center(
                                    child: Icon(Icons.book_outlined,
                                        color: AppColors.ink100, size: 40),
                                  ),
                                ),
                                errorWidget: (_, __, ___) =>
                                    _CoverPlaceholder(title: book.title),
                              )
                            : _CoverPlaceholder(title: book.title),

                        // Downloaded badge
                        if (downloaded)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.offline_pin,
                                      color: Colors.white, size: 12),
                                  SizedBox(width: 4),
                                  Text('Saved',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Book info
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink900,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        book.author,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.ink400),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Access badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: book.isFreePreview
                              ? AppColors.primaryLight
                              : AppColors.canvas,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          book.isFreePreview
                              ? 'Free Preview (${book.freePageCount}p)'
                              : 'Subscription',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: book.isFreePreview
                                ? AppColors.primaryDark
                                : AppColors.ink700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Download button / progress
                      if (downloading) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppColors.ink50,
                            color: AppColors.primary,
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.ink400),
                        ),
                      ] else if (!downloaded)
                        SizedBox(
                          width: double.infinity,
                          height: 32,
                          child: OutlinedButton.icon(
                            onPressed: auth.user == null
                                ? null
                                : () async {
                                  print(progress);
                                  
                                    try {
                                      await books.downloadBook(
                                          book, auth.user!.id);
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text(
                                              'Download failed: ${e.toString()}'),
                                        ));
                                      }
                                    }
                                  },
                            icon: const Icon(Icons.download_outlined, size: 14),
                            label: const Text('Download',
                                style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  final String title;
  const _CoverPlaceholder({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.canvas,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book_rounded,
                color: AppColors.ink100, size: 48),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 3,
                style: const TextStyle(
                    color: AppColors.ink400,
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
