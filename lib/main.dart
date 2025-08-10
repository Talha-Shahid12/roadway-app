import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart'; // Add this import

void main() {
  runApp(const RoadwayApp());
}

class RoadwayApp extends StatelessWidget {
  const RoadwayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // Based on iPhone X size
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Roadway',
          theme: AppTheme.lightTheme,
          initialRoute: AppRoutes.splash, // Change from login to splash
          routes: AppRoutes.routes,
        );
      },
    );
  }
}
