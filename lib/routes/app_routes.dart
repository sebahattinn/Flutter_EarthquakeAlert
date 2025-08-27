import 'package:flutter/material.dart';

import '../presentation/screens/home_screen.dart';
import '../presentation/screens/earthquake_list_screen.dart';
import '../presentation/screens/earthquake_detail_screen.dart';
import '../presentation/screens/info_screen.dart';
import '../presentation/screens/settings_screen.dart';
import '../presentation/screens/analytics_screen.dart'; // NEW
import '../presentation/screens/map_screen.dart'; // NEW
import '../presentation/screens/checklist_screen.dart'; // NEW
import '../presentation/screens/splash_screen.dart'; // NEW

import '../data/models/earthquake_model.dart';

class AppRoutes {
  // Core
  static const String splash = '/splash'; // NEW
  static const String home = '/';
  static const String earthquakeList = '/earthquakes';
  static const String earthquakeDetail = '/earthquake-detail';
  static const String info = '/info';
  static const String settings = '/settings';

  // NEW pages
  static const String analytics = '/analytics';
  static const String map = '/map';
  static const String checklist = '/checklist';

  // Basic generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final String? name = settings.name;

    if (name == splash) {
      return MaterialPageRoute(builder: (_) => const SplashScreen());
    } else if (name == home) {
      return MaterialPageRoute(builder: (_) => const HomeScreen());
    } else if (name == earthquakeList) {
      return MaterialPageRoute(builder: (_) => const EarthquakeListScreen());
    } else if (name == earthquakeDetail) {
      final earthquake = settings.arguments as Earthquake;
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

  // Slide transitionlu generator
  static PageRouteBuilder<dynamic> _buildPageRoute({
    required Widget page,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final begin =  Offset(1.0, 0.0);
        final end = Offset.zero;
        final curve = Curves.easeInOut;
        final tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        final offsetAnimation = animation.drive(tween);
        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static Route<dynamic> generateRouteWithTransitions(RouteSettings settings) {
    final String? name = settings.name;

    if (name == splash) {
      return _buildPageRoute(page: const SplashScreen(), settings: settings);
    } else if (name == home) {
      return _buildPageRoute(page: const HomeScreen(), settings: settings);
    } else if (name == earthquakeList) {
      return _buildPageRoute(
          page: const EarthquakeListScreen(), settings: settings);
    } else if (name == earthquakeDetail) {
      final earthquake = settings.arguments as Earthquake;
      return _buildPageRoute(
        page: EarthquakeDetailScreen(earthquake: earthquake),
        settings: settings,
      );
    } else if (name == info) {
      return _buildPageRoute(page: const InfoScreen(), settings: settings);
    } else if (name == settings) {
      return _buildPageRoute(page: const SettingsScreen(), settings: settings);
    } else if (name == analytics) {
      return _buildPageRoute(page: const AnalyticsScreen(), settings: settings);
    } else if (name == map) {
      return _buildPageRoute(page: const MapScreen(), settings: settings);
    } else if (name == checklist) {
      return _buildPageRoute(page: const ChecklistScreen(), settings: settings);
    } else {
      return _notFoundPage();
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
        context, routeName, (route) => false,
        arguments: arguments);
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
