import 'package:flutter/material.dart';

import '../presentation/screens/home_screen.dart';
import '../presentation/screens/earthquake_list_screen.dart';
import '../presentation/screens/earthquake_detail_screen.dart';
import '../presentation/screens/info_screen.dart';
import '../presentation/screens/settings_screen.dart';
import '../presentation/screens/analytics_screen.dart';
import '../presentation/screens/map_screen.dart';
import '../presentation/screens/checklist_screen.dart';
import '../presentation/screens/splash_screen.dart';

import '../data/models/earthquake_model.dart';

class AppRoutes {
  // Core
  static const String splash = '/splash';
  static const String home = '/';
  static const String earthquakeList = '/earthquakes';
  static const String earthquakeDetail = '/earthquake-detail';
  static const String info = '/info';
  static const String settings = '/settings';

  // NEW pages
  static const String analytics = '/analytics';
  static const String map = '/map';
  static const String checklist = '/checklist';

  // ------- Basic generator -------
  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    final String? name = routeSettings.name;

    if (name == splash) {
      return MaterialPageRoute(builder: (_) => const SplashScreen());
    } else if (name == home) {
      return MaterialPageRoute(builder: (_) => const HomeScreen());
    } else if (name == earthquakeList) {
      return MaterialPageRoute(builder: (_) => const EarthquakeListScreen());
    } else if (name == earthquakeDetail) {
      final earthquake = routeSettings.arguments as Earthquake;
      return MaterialPageRoute(
        builder: (_) => EarthquakeDetailScreen(earthquake: earthquake),
      );
    } else if (name == info) {
      return MaterialPageRoute(builder: (_) => const InfoScreen());
    } else if (name == settings) {
      return MaterialPageRoute(builder: (_) => const SettingsScreen());
    } else if (name == analytics) {
      return MaterialPageRoute(builder: (_) => const AnalyticsScreen());
    } else if (name == map) {
      return MaterialPageRoute(builder: (_) => const MapScreen());
    } else if (name == checklist) {
      return MaterialPageRoute(builder: (_) => const ChecklistScreen());
    } else {
      return _notFoundPage();
    }
  }

  // ------- Slide transition'lı generator -------
  static PageRouteBuilder<dynamic> _buildPageRoute({
    required Widget page,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        final tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        final offsetAnimation = animation.drive(tween);
        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static Route<dynamic> generateRouteWithTransitions(
    RouteSettings routeSettings,
  ) {
    final String? name = routeSettings.name;

    if (name == splash) {
      return _buildPageRoute(
        page: const SplashScreen(),
        settings: routeSettings,
      );
    } else if (name == home) {
      return _buildPageRoute(
        page: const HomeScreen(),
        settings: routeSettings,
      );
    } else if (name == earthquakeList) {
      return _buildPageRoute(
        page: const EarthquakeListScreen(),
        settings: routeSettings,
      );
    } else if (name == earthquakeDetail) {
      final earthquake = routeSettings.arguments as Earthquake;
      return _buildPageRoute(
        page: EarthquakeDetailScreen(earthquake: earthquake),
        settings: routeSettings,
      );
    } else if (name == info) {
      return _buildPageRoute(
        page: const InfoScreen(),
        settings: routeSettings,
      );
    } else if (name == settings) {
      return _buildPageRoute(
        page: const SettingsScreen(),
        settings: routeSettings,
      );
    } else if (name == analytics) {
      return _buildPageRoute(
        page: const AnalyticsScreen(),
        settings: routeSettings,
      );
    } else if (name == map) {
      return _buildPageRoute(
        page: const MapScreen(),
        settings: routeSettings,
      );
    } else if (name == checklist) {
      return _buildPageRoute(
        page: const ChecklistScreen(),
        settings: routeSettings,
      );
    } else {
      return _notFoundPage();
    }
  }

  // ------- Navigation helpers -------
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

  static bool canGoBack(BuildContext context) => Navigator.canPop(context);

  static MaterialPageRoute<dynamic> _notFoundPage() {
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
              Icon(Icons.error_outline, size: 64, color: Color(0xFFE63946)),
              SizedBox(height: 16),
              Text('Sayfa bulunamadı',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Aradığınız sayfa mevcut değil',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
