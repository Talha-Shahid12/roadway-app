import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:roadway/Services/NotificationService.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
      options: FirebaseOptions(
    apiKey: '',
    appId: '',
    messagingSenderId: '',
    projectId: '',
    storageBucket: '',
  ));

  FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  // Initialize notification service
  FirebaseNotificationService().initialize();

  runApp(const RoadwayApp());
}

class RoadwayApp extends StatelessWidget {
  const RoadwayApp({super.key});

  // Create a global navigator key
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    // Assign the navigator key to the notification service
    FirebaseNotificationService.navigatorKey = navigatorKey;

    return ScreenUtilInit(
      designSize: const Size(375, 812), // Based on iPhone X size
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Roadway',
          theme: AppTheme.lightTheme,
          navigatorKey: navigatorKey, // Add this line
          initialRoute: AppRoutes.splash,
          routes: AppRoutes.routes,
          // Optional: Handle unknown routes
          onUnknownRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => const Scaffold(
                body: Center(child: Text('Page not found')),
              ),
            );
          },
        );
      },
    );
  }
}
