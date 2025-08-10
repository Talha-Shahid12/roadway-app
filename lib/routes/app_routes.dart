import 'package:flutter/material.dart';
import 'package:roadway/screens/announcement_screen.dart';
import 'package:roadway/screens/home_screen.dart';
import 'package:roadway/screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';

import '../screens/bus_list_screen.dart';
import '../screens/bus_detail_screen.dart';
import '../screens/booking_summary_screen.dart';
import '../screens/booking_success_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String busList = '/busList';
  static const String busDetail = '/busDetail';
  static const String bookingSummary = '/bookingSummary';
  static const String success = '/success';
  static const String splash = '/splash';
  static const String announcements = '/announcements';

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => SimpleSplashScreen(),
    login: (context) => const LoginScreen(),
    signup: (context) => const SignUpScreen(),
    home: (context) => const HomeScreen(),
    busList: (context) => const BusListScreen(),
    busDetail: (context) => const BusDetailScreen(),
    bookingSummary: (context) => const BookingSummaryScreen(),
    success: (context) => const BookingSuccessScreen(),
    announcements: (context) => const AnnouncementsScreen(),
  };
}
