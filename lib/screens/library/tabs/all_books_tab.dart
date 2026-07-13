import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/book_model.dart';
import '../../../providers/books_provider.dart';
import '../../../widgets/book_card.dart';

class AllBooksTab extends StatefulWidget {
  const AllBooksTab({super.key});

  @override
  State<AllBooksTab> createState() => _AllBooksTabState();
}

class _AllBooksTabState extends State<AllBooksTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BooksProvider>().fetchBooks();
    });
  }

  Map<String, List<BookModel>> _groupByCategory(List<BookModel> books) {
    final Map<String, List<BookModel>> grouped = {};
    for (final book in books) {
      final cat = book.category.isNotEmpty ? book.category : 'Other';
      grouped.putIfAbsent(cat, () => []).add(book);
    }
    print('');
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<BooksProvider>(
      builder: (context, books, _) {
        if (books.loading) return const _ShimmerList();

        if (books.error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_outlined,
                      color: AppColors.ink100, size: 56),
                  const SizedBox(height: 16),
                  Text(books.error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: books.fetchBooks,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (books.books.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.library_books_outlined,
                    color: AppColors.ink100, size: 64),
                SizedBox(height: 16),
                Text('No books available yet.',
                    style: TextStyle(color: AppColors.ink400)),
              ],
            ),
          );
        }

        final grouped = _groupByCategory(books.books);
        final categories = grouped.keys.toList()..sort();

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: books.fetchBooks,
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: categories.length,
            itemBuilder: (context, i) {
              final category = categories[i];
              final categoryBooks = grouped[category]!;
              return _CategorySection(
                category: category,
                books: categoryBooks,
              );
            },
          ),
        );
      },
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String category;
  final List<BookModel> books;

  const _CategorySection({required this.category, required this.books});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                category,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink900,
                    ),
              ),
              const SizedBox(width: 8),
              Text(
                '${books.length} ${books.length == 1 ? 'book' : 'books'}',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: AppColors.ink400,
                    ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: books.length,
            itemBuilder: (context, i) {
              final book = books[i];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 140,
                  child: BookCard(
                    book: book,
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/reader',
                      arguments: {
                        'bookId': book.id,
                        'bookTitle': book.title,
                        'isOffline': false,
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.ink50,
      highlightColor: Colors.white,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: List.generate(2, (_) => _shimmerSection()),
      ),
    );
  }

  Widget _shimmerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Container(
            width: 120,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 3,
            itemBuilder: (_, __) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                width: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
