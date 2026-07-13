import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/books_provider.dart';
import '../../../widgets/downloaded_book_tile.dart';

class DownloadedTab extends StatefulWidget {
  const DownloadedTab({super.key});

  @override
  State<DownloadedTab> createState() => _DownloadedTabState();
}

class _DownloadedTabState extends State<DownloadedTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BooksProvider>().fetchOfflineBooks();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<BooksProvider>(
      builder: (context, books, _) {
        if (books.offlineLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (books.offlineBooks.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download_outlined,
                      color: AppColors.ink100, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'No downloaded books',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink700),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Download books from the library\nto read them offline.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.ink400, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: books.fetchOfflineBooks,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: books.offlineBooks.length,
            itemBuilder: (context, i) {
              final book = books.offlineBooks[i];
              return DownloadedBookTile(
                book: book,
                onTap: () => Navigator.pushNamed(
                  context,
                  '/reader',
                  arguments: {
                    'bookId': book.bookId,
                    'bookTitle': book.title,
                    'isOffline': true,
                  },
                ),
                onDelete: () async {
                  await books.deleteOfflineBook(book.bookId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Offline copy removed.')),
                    );
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}
