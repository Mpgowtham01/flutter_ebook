import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:epub_view/epub_view.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/reader_provider.dart';
import 'widgets/subscribe_overlay.dart';

class ReaderScreen extends StatefulWidget {
  final String bookId;
  final String bookTitle;
  final bool isOffline;

  const ReaderScreen({
    super.key,
    required this.bookId,
    required this.bookTitle,
    required this.isOffline,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  EpubController? _epubController;
  bool _appBarVisible = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final provider = context.read<ReaderProvider>();
    provider.reset();
    await provider.loadBook(
      bookId: widget.bookId,
      forceOffline: widget.isOffline,
    );
    if (!mounted) return;
    final bytes = provider.epubBytes;
    if (bytes != null) {
      setState(() {
        _epubController = EpubController(
          document: EpubDocument.openData(bytes),
        );
      });
    }
  }

  @override
  void dispose() {
    _epubController?.dispose();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  void _toggleAppBar() => setState(() => _appBarVisible = !_appBarVisible);

  @override
  Widget build(BuildContext context) {
    return Consumer<ReaderProvider>(
      builder: (context, reader, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              _buildBody(reader),
              if (_appBarVisible)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _ReaderAppBar(
                    title: widget.bookTitle,
                    isOffline: reader.isOfflineMode,
                    currentPage: reader.currentPage,
                    totalPages: reader.totalPages,
                    onBack: () => Navigator.pop(context),
                  ),
                ),
              if (reader.previewLimitReached)
                SubscribeOverlay(onClose: () => Navigator.pop(context)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(ReaderProvider reader) {
    switch (reader.state) {
      case ReaderLoadState.loading:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text('Loading book…',
                  style: TextStyle(color: AppColors.ink400)),
            ],
          ),
        );

      case ReaderLoadState.error:
        if (reader.previewLimitReached) return const SizedBox.shrink();
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.error, size: 56),
                const SizedBox(height: 16),
                Text(
                  reader.errorMessage ?? 'Failed to load book.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.ink700),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                ),
              ],
            ),
          ),
        );

      case ReaderLoadState.loaded:
        if (_epubController == null) return const SizedBox.shrink();
        return GestureDetector(
          onTap: _toggleAppBar,
          child: EpubView(
            controller: _epubController!,
            onChapterChanged: (chapter) {
              final pageIndex = chapter?.chapterNumber ?? reader.currentPage;
              context.read<ReaderProvider>().onPageChanged(
                    bookId: widget.bookId,
                    currentPage: pageIndex,
                    totalPages: reader.totalPages,
                    currentChapter: chapter?.chapter?.Title,
                  );
            },
            onDocumentLoaded: (doc) {
              final total = doc.Chapters?.length ?? 0;
              setState(() {});
              context.read<ReaderProvider>().onPageChanged(
                    bookId: widget.bookId,
                    currentPage: 1,
                    totalPages: total,
                  );
            },
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

class _ReaderAppBar extends StatelessWidget {
  final String title;
  final bool isOffline;
  final int currentPage;
  final int totalPages;
  final VoidCallback onBack;

  const _ReaderAppBar({
    required this.title,
    required this.isOffline,
    required this.currentPage,
    required this.totalPages,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.ink900.withOpacity(0.92),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (totalPages > 0)
                      Text(
                        'Chapter $currentPage of $totalPages',
                        style: const TextStyle(
                            color: AppColors.ink400, fontSize: 11),
                      ),
                  ],
                ),
              ),
              if (isOffline)
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: AppColors.info.withOpacity(0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.offline_pin, color: AppColors.info, size: 12),
                      SizedBox(width: 4),
                      Text('Offline',
                          style: TextStyle(
                              color: AppColors.info,
                              fontSize: 11,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
