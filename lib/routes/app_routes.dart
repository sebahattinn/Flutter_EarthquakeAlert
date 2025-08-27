import 'package:flutter/material.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/earthquake_list_screen.dart';
import '../presentation/screens/earthquake_detail_screen.dart';
import '../presentation/screens/info_screen.dart';
import '../presentation/screens/settings_screen.dart';
import '../data/models/earthquake_model.dart';

class AppRoutes {
  static const String home = '/';
  static const String earthquakeList = '/earthquakes';
  static const String earthquakeDetail = '/earthquake-detail';
  static const String info = '/info';
  static const String settings = '/settings';

  // Dart 3 uyumlu: switch-case yerine if-else kullanıldı
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final String? name = settings.name;

    if (name == home) {
      return MaterialPageRoute(builder: (_) => const HomeScreen());
    } else if (name == earthquakeList) {
      return MaterialPageRoute(builder: (_) => const EarthquakeListScreen());
    } else if (name == earthquakeDetail) {
      final earthquake = settings.arguments as Earthquake;
      return MaterialPageRoute(
          builder: (_) => EarthquakeDetailScreen(earthquake: earthquake));
    } else if (name == info) {
      return MaterialPageRoute(builder: (_) => const InfoScreen());
    } else if (name == settings) {
      return MaterialPageRoute(builder: (_) => const SettingsScreen());
    } else {
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Hata'),
            backgroundColor: const Color(0xFFE63946),
            foregroundColor: Colors.white,
          ),
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Color(0xFFE63946),
                ),
                SizedBox(height: 16),
                Text(
                  'Sayfa bulunamadı',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Aradığınız sayfa mevcut değil',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  // Custom page transition
  static PageRouteBuilder<dynamic> _buildPageRoute({
    required Widget page,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final begin = Offset(1.0, 0.0);
        final end = Offset.zero;
        final curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  // Generate route with custom transitions
  static Route<dynamic> generateRouteWithTransitions(RouteSettings settings) {
    final String? name = settings.name;

    if (name == home) {
      return _buildPageRoute(page: const HomeScreen(), settings: settings);
    } else if (name == earthquakeList) {
      return _buildPageRoute(
          page: const EarthquakeListScreen(), settings: settings);
    } else if (name == earthquakeDetail) {
      final earthquake = settings.arguments as Earthquake;
      return _buildPageRoute(
          page: EarthquakeDetailScreen(earthquake: earthquake),
          settings: settings);
    } else if (name == info) {
      return _buildPageRoute(page: const InfoScreen(), settings: settings);
    } else if (name == settings) {
      return _buildPageRoute(page: const SettingsScreen(), settings: settings);
    } else {
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Hata'),
            backgroundColor: const Color(0xFFE63946),
            foregroundColor: Colors.white,
          ),
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Color(0xFFE63946),
                ),
                SizedBox(height: 16),
                Text(
                  'Sayfa bulunamadı',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Aradığınız sayfa mevcut değil',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  // Navigation helpers
  static Future<T?> navigateTo<T>(BuildContext context, String routeName,
      {Object? arguments}) {
    return Navigator.pushNamed<T>(context, routeName, arguments: arguments);
  }

  static Future<T?> navigateAndReplace<T>(
      BuildContext context, String routeName,
      {Object? arguments}) {
    return Navigator.pushReplacementNamed<T, T>(context, routeName,
        arguments: arguments);
  }

  static Future<T?> navigateAndRemoveAll<T>(
      BuildContext context, String routeName,
      {Object? arguments}) {
    return Navigator.pushNamedAndRemoveUntil<T>(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  static void goBack<T>(BuildContext context, [T? result]) {
    Navigator.pop<T>(context, result);
  }

  static bool canGoBack(BuildContext context) {
    return Navigator.canPop(context);
  }
}
