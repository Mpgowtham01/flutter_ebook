import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/constants/app_colors.dart';
import '../data/models/offline_book_model.dart';

class DownloadedBookTile extends StatelessWidget {
  final OfflineBookModel book;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const DownloadedBookTile({
    super.key,
    required this.book,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final daysLeft = book.expiresAt.difference(DateTime.now()).inDays;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.ink100),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Cover thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                height: 72,
                child: book.coverUrl != null
                    ? CachedNetworkImage(
                        imageUrl: book.coverUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            const _SmallPlaceholder(),
                      )
                    : const _SmallPlaceholder(),
              ),
            ),
            const SizedBox(width: 12),

            // Book info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontSize: 14,
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
                        fontSize: 12, color: AppColors.ink400),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.offline_pin,
                          color: AppColors.success, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Available offline',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '· expires in $daysLeft days',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.ink400),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Delete button
            IconButton(
              onPressed: () => _confirmDelete(context),
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.error, size: 20),
              tooltip: 'Remove offline copy',
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Remove offline copy?'),
        content: Text(
            'This will delete the offline copy of "${book.title}". You can re-download it anytime.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: const Text('Remove',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _SmallPlaceholder extends StatelessWidget {
  const _SmallPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.canvas,
      child: const Center(
        child: Icon(Icons.menu_book_rounded, color: AppColors.ink100, size: 24),
      ),
    );
  }
}
