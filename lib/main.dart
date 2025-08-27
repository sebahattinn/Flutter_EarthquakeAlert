import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_colors.dart';
import 'core/services/notification_service.dart';
import 'presentation/providers/earthquake_provider.dart';
import 'routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bildirim servisini başlat (Android 13+ izin & kanal)
  await NotificationService().initialize();

  runApp(const DepremTurkiyeApp());
}

class DepremTurkiyeApp extends StatelessWidget {
  const DepremTurkiyeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EarthquakeProvider()),
      ],
      child: MaterialApp(
        title: 'Deprem Türkiye',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.primary,
          // pubspec'te Montserrat tanımlı değilse bu satırı kaldırabilirsin
          fontFamily: 'Montserrat',
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.light,
          ),
        ),
        initialRoute: AppRoutes.home,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}
