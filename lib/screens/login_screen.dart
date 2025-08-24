import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:roadway/Services/NotificationService.dart';
import 'package:roadway/Services/UserAuthStorage.dart';
import 'package:roadway/routes/app_routes.dart';
import 'package:roadway/screens/forgot_password_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../services/ApiCalls.dart'; // Import your API service
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;
  bool _isLoading = false;

  // Email validation regex
  final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  String? _validateForm() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      return 'Please enter your email address';
    }

    if (!ApiCalls.isValidEmail(email)) {
      return 'Please enter a valid email address';
    }

    if (password.isEmpty) {
      return 'Please enter a password';
    }

    return null;
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Email validation function
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // Password validation function
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 20.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.all(16.w),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Show success dialog
  Future<void> _showSuccessDialog() async {
    final user = await UserAuthStorage.getUserData();
    if (user == null) {
      _showErrorDialog('User data not found. Please try again.');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 20.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                "Welcome back, ${user?.displayName ?? ""}!",
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 116, 164, 246),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.all(16.w),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Handle login function
  Future<void> _handleLogin() async {
    print("attempting to login...");
    // Validate form
    final validationError = _validateForm();
    if (validationError != null) {
      _showErrorDialog(validationError);
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Hide keyboard
    FocusScope.of(context).unfocus();

    // Set loading state
    setState(() {
      _isLoading = true;
    });

    try {
      // Make API call
      final response = await ApiCalls.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Handle response
      if (response.success && response.data != null) {
        // Check response code from API
        if (response.data!.responseCode == "00") {
          // Store token if needed (you can use shared preferences or secure storage)
          // Future<String> fcmToken = FirebaseNotificationService().getToken();
          final String? newFcmToken =
              await FirebaseNotificationService().getToken();
          log("New FCM Token: $newFcmToken");
          final fcmUpdateResponse = await ApiCalls.updateFCMToken(
              email: _emailController.text.trim().toString(),
              fcmToken: newFcmToken!);

          if (fcmUpdateResponse['success'] == true) {
            print('🔔 FCM token updated successfully on the server.');
            String token = response.data!.token;
            print('🎉 Login successful! Token: $token');

            // Show success dialog
            _showSuccessDialog();
            Navigator.pushNamed(context, AppRoutes.home);
          } else {
            _showErrorDialog(fcmUpdateResponse['message'] ??
                'Failed to update FCM token on the server.');
          }
        } else {
          // Handle unsuccessful response code
          _showErrorDialog(response.data!.responseMessage);
        }
      } else {
        // Handle API error
        _showErrorDialog(response.message);
      }
    } catch (e) {
      // Handle unexpected errors
      print('❌ Unexpected error during login: $e');
      _showErrorDialog(
          'An unexpected error occurred. Please check your internet connection and try again.');
    } finally {
      // Reset loading state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.1),
              const Color.fromARGB(255, 146, 147, 204),
              AppColors.primary.withOpacity(0.05),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 60.h),

                        // App Logo with glowing effect
                        Center(
                          child: Image.asset(
                            'assets/images/icon.png',
                            width: 500.w,
                            height: 100.h,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(height: 50.h),

                        // Welcome text with subtle animation
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 1500),
                          tween: Tween(begin: 0.0, end: 1.0),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: Opacity(
                                opacity: value,
                                child: child,
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "Welcome Back 👋",
                                    style: AppTextStyles.headline1.copyWith(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  // TweenAnimationBuilder<double>(
                                  //   duration:
                                  //       const Duration(milliseconds: 2000),
                                  //   tween: Tween(begin: 0.8, end: 1.2),
                                  //   curve: Curves.elasticOut,
                                  //   builder: (context, scale, child) {
                                  //     return Transform.scale(
                                  //       scale: scale,
                                  //       child: const Text("👋",
                                  //           style: TextStyle(fontSize: 28)),
                                  //     );
                                  //   },
                                  // ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                "Login to continue your journey",
                                style: AppTextStyles.body.copyWith(
                                  color: const Color.fromARGB(255, 63, 58, 58),
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 40.h),

                        // Email Field with validation
                        _buildAnimatedTextField(
                          controller: _emailController,
                          label: "Email",
                          icon: Icons.email_outlined,
                          isFocused: _isEmailFocused,
                          onFocusChange: (focused) {
                            setState(() {
                              _isEmailFocused = focused;
                            });
                          },
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                          enabled: !_isLoading,
                        ),

                        SizedBox(height: 20.h),

                        // Password Field with validation
                        _buildAnimatedTextField(
                          controller: _passwordController,
                          label: "Password",
                          icon: Icons.lock_outline,
                          isFocused: _isPasswordFocused,
                          onFocusChange: (focused) {
                            setState(() {
                              _isPasswordFocused = focused;
                            });
                          },
                          obscureText: _obscurePassword,
                          validator: _validatePassword,
                          enabled: !_isLoading,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: _isPasswordFocused
                                  ? AppColors.primary
                                  : Colors.grey[400],
                            ),
                            onPressed: _isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                          ),
                        ),

                        SizedBox(height: 16.h),

                        // Forgot Password with hover effect
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: _isLoading
                                ? null
                                : () {
                                    // Navigate to forgot password flow
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ForgotPasswordEmailScreen(),
                                      ),
                                    );
                                  },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              child: Text(
                                "Forgot Password?",
                                style: GoogleFonts.poppins(
                                  color: _isLoading
                                      ? Colors.grey[400]
                                      : AppColors.primary,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                  decorationColor: _isLoading
                                      ? Colors.grey[400]?.withOpacity(0.3)
                                      : AppColors.primary.withOpacity(0.3),
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 32.h),

                        // Enhanced Login Button with loading state
                        _buildGradientButton(),

                        SizedBox(height: 32.h),

                        // Divider with "OR"
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.grey[300],
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: Text(
                                "OR",
                                style: GoogleFonts.poppins(
                                  color:
                                      const Color.fromARGB(255, 251, 246, 246),
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.grey[300],
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 24.h),

                        // Social Login Buttons
                        Row(
                          children: [
                            Expanded(
                              child: _buildSocialButton(
                                icon: Icons.g_mobiledata,
                                label: "Google",
                                onTap: _isLoading ? () {} : () {},
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: _buildSocialButton(
                                icon: Icons.facebook,
                                label: "Facebook",
                                onTap: _isLoading ? () {} : () {},
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 32.h),

                        // Sign Up Prompt with enhanced styling
                        Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 12.h,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25.r),
                              color: Colors.grey[50],
                              border: Border.all(
                                color: Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _isLoading
                                      ? null
                                      : () {
                                          Navigator.pushNamed(
                                              context, AppRoutes.signup);
                                        },
                                  child: Text(
                                    "Sign Up",
                                    style: GoogleFonts.poppins(
                                      color: _isLoading
                                          ? Colors.grey[400]
                                          : AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.sp,
                                      decoration: TextDecoration.underline,
                                      decorationColor: _isLoading
                                          ? Colors.grey[400]
                                          : AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isFocused,
    required Function(bool) onFocusChange,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Focus(
        onFocusChange: onFocusChange,
        child: TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          enabled: enabled,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: GoogleFonts.poppins(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: enabled ? Colors.black : Colors.grey[500],
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.poppins(
              color: isFocused
                  ? AppColors.primary
                  : enabled
                      ? Colors.grey[500]
                      : Colors.grey[400],
              fontSize: 13.sp,
            ),
            prefixIcon: Icon(
              icon,
              color: isFocused
                  ? AppColors.primary
                  : enabled
                      ? Colors.grey[400]
                      : Colors.grey[300],
              size: 22.sp,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(
                color: Colors.grey[200]!,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(
                color: Colors.grey[200]!,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(
                color: Colors.red[400]!,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(
                color: Colors.red[400]!,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 20.w,
              vertical: 18.h,
            ),
            errorStyle: GoogleFonts.poppins(
              fontSize: 10.sp,
              color: Colors.red[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: 56.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: LinearGradient(
          colors: _isLoading
              ? [Colors.grey[400]!, Colors.grey[400]!]
              : [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.8),
                ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: _isLoading
            ? []
            : [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 0,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: _isLoading ? null : _handleLogin,
          child: Center(
            child: _isLoading
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        "Signing In...",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Login Now",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 50.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: _isLoading ? Colors.grey[100] : Colors.white,
        border: Border.all(
          color: _isLoading ? Colors.grey[200]! : Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: _isLoading
            ? []
            : [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: _isLoading ? null : onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24.sp,
                color: _isLoading ? Colors.grey[400] : Colors.grey[700],
              ),
              SizedBox(width: 8.w),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: _isLoading ? Colors.grey[400] : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
