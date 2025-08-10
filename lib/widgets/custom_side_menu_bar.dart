import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roadway/routes/app_routes.dart';
import 'package:roadway/screens/booking_history_screen.dart';
// Add these classes at the bottom of your home_screen.dart file

class CustomSideMenuBar extends StatefulWidget {
  final Function(int)? onItemSelected;

  const CustomSideMenuBar({super.key, this.onItemSelected});

  @override
  State<CustomSideMenuBar> createState() => _CustomSideMenuBarState();
}

class _CustomSideMenuBarState extends State<CustomSideMenuBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).animate(_animationController),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Drawer(
              backgroundColor: Colors.transparent,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF6C63FF),
                      const Color(0xFF9C88FF),
                      const Color(0xFFB794FF),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      _buildMenuHeader(),
                      Expanded(child: _buildMenuItems()),
                      _buildMenuFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuHeader() {
    return Container(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          // Profile Avatar
          Container(
            width: 80.w,
            height: 80.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                'T',
                style: GoogleFonts.poppins(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Hi, Talha! 👋',
            style: GoogleFonts.poppins(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'talha@example.com',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems() {
    final menuItems = [
      MenuItemData(
        icon: Icons.home_rounded,
        title: 'Home',
        subtitle: 'Search & book buses',
        route: AppRoutes.home,
        index: 0,
      ),
      MenuItemData(
        icon: Icons.confirmation_number_rounded,
        title: 'My Bookings',
        subtitle: 'View booking history',
        route: null,
        index: 1,
        isBookingHistory: true,
      ),
      MenuItemData(
        icon: Icons.campaign_rounded,
        title: 'Announcements',
        subtitle: 'Latest updates',
        route: AppRoutes.announcements,
        index: 2,
      ),
      MenuItemData(
        icon: Icons.person_outline_rounded,
        title: 'Profile',
        subtitle: 'Manage your account',
        route: '/profile',
        index: 3,
      ),
      MenuItemData(
        icon: Icons.support_agent_rounded,
        title: 'Support',
        subtitle: 'Get help',
        route: '/support',
        index: 4,
      ),
    ];

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        final isSelected = _selectedIndex == item.index;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.only(bottom: 8.h),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16.r),
            child: InkWell(
              borderRadius: BorderRadius.circular(16.r),
              onTap: () => _handleMenuTap(item),
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16.r),
                  border: isSelected
                      ? Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.2)
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        item.icon,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            item.subtitle,
                            style: GoogleFonts.poppins(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white.withOpacity(0.5),
                      size: 14.sp,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuFooter() {
    return Container(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          // Logout Button
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16.r),
            child: InkWell(
              borderRadius: BorderRadius.circular(16.r),
              onTap: () => _showLogoutDialog(),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Color(0xFFEEE0E0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: Color.fromARGB(255, 189, 62, 62).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: const Color.fromARGB(255, 248, 222, 222),
                      size: 20.sp,
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Logout',
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFEEE0E0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          // Version Info
          Text(
            'Version 1.0.0',
            style: GoogleFonts.poppins(
              fontSize: 10.sp,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuTap(MenuItemData item) {
    setState(() {
      _selectedIndex = item.index;
    });

    // Close the drawer
    Navigator.of(context).pop();

    // Handle navigation
    if (item.isBookingHistory) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const BookingsHistoryScreen(),
        ),
      );
    } else if (item.route != null) {
      Navigator.pushReplacementNamed(context, item.route!);
    }

    // Call the callback if provided
    if (widget.onItemSelected != null) {
      widget.onItemSelected!(item.index);
    }
  }

  void _showLogoutDialog() {
    Navigator.of(context).pop(); // Close drawer first

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: Colors.red[600],
                    size: 32.sp,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Logout',
                  style: GoogleFonts.poppins(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Are you sure you want to logout?',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            side: BorderSide(
                              color: Colors.grey[300]!,
                            ),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Add your logout logic here
                          _performLogout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          'Logout',
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _performLogout() {
    // Add your logout logic here
    // For example: clear storage, navigate to login screen, etc.
    print('🚪 User logged out');

    // Example navigation to login screen
    // Navigator.pushNamedAndRemoveUntil(
    //   context,
    //   '/login',
    //   (route) => false,
    // );
  }
}

class MenuItemData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? route;
  final int index;
  final bool isBookingHistory;

  MenuItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.route,
    required this.index,
    this.isBookingHistory = false,
  });
}
