import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:roadway/Services/UserAuthStorage.dart';
import '../routes/app_routes.dart';

class SimpleSplashScreen extends StatefulWidget {
  @override
  _SimpleSplashScreenState createState() => _SimpleSplashScreenState();
}

class _SimpleSplashScreenState extends State<SimpleSplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 3), () async {
      if (await UserAuthStorage.isUserLoggedIn()) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
        return;
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
        return;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF667eea),
      body: Center(
        child: Image.asset(
          'assets/images/loader.gif',
          width: 500.w,
          height: 500.h,
        ),
      ),
    );
  }
}
