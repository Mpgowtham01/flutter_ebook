import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/library/library_screen.dart';
import 'screens/reader/reader_screen.dart';
import 'screens/profile/profile_screen.dart';

class EbookApp extends StatelessWidget {
  const EbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ebook',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return _route(const SplashScreen());
          case '/login':
            return _route(const LoginScreen());
          case '/register':
            return _route(const RegisterScreen());
          case '/library':
            return _route(const LibraryScreen());
          case '/profile':
            return _route(const ProfileScreen());
          case '/reader':
            final args = settings.arguments as Map<String, dynamic>;
            return _route(ReaderScreen(
              bookId: args['bookId'] as String,
              bookTitle: args['bookTitle'] as String,
              isOffline: args['isOffline'] as bool? ?? false,
            ));
          default:
            return _route(const SplashScreen());
        }
      },
    );
  }

  PageRoute _route(Widget page) => MaterialPageRoute(builder: (_) => page);
}
