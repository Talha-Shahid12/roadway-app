import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:roadway/screens/booking_history_screen.dart';
import '../Services/ApiCalls.dart'; // Import your API service
// import '../theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  DateTime? _selectedDate;
  int _selectedIndex = 0;
  bool _isLoading = false; // Added loading state

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Set status bar to transparent
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  // Validation function for search form
  String? _validateSearchForm() {
    final from = _fromController.text.trim();
    final to = _toController.text.trim();

    if (from.isEmpty) {
      return 'Please enter departure location';
    }

    if (to.isEmpty) {
      return 'Please enter destination location';
    }

    if (from.toLowerCase() == to.toLowerCase()) {
      return 'Departure and destination cannot be the same';
    }

    if (_selectedDate == null) {
      return 'Please select a travel date';
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
                style: TextStyle(
                  fontSize: 14.sp,
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
  void _showSuccessDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 20.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14.sp,
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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Handle search function
  Future<void> _handleSearch() async {
    // Validate form
    final validationError = _validateSearchForm();
    if (validationError != null) {
      _showErrorDialog(validationError);
      return;
    }

    // Hide keyboard
    FocusScope.of(context).unfocus();

    // Set loading state
    setState(() {
      _isLoading = true;
    });

    try {
      // Format date for API (assuming API expects YYYY-MM-DD format)
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);

      // You might need to get token from secure storage if required
      // String? token = await getStoredToken(); // Implement this if needed

      // Make API call
      final response = await ApiCalls.searchSlots(
        from: _fromController.text.trim(),
        to: _toController.text.trim(),
        dateInput: formattedDate,
        // token: token, // Include if your API requires authentication
      );

      // Handle response
      if (response.success && response.data != null) {
        // Check response code from API

        _showSuccessDialog('Search completed successfully!');
        print(
            "Here are the Slots data : ${response.data}"); // You can print the data here
        // Navigate to bus list screen with search results
        // You can pass the search results and search parameters
        Navigator.pushNamed(
          context,
          '/busList',
          arguments: {
            'searchResults': response.data,
            'searchParams': {
              'from': _fromController.text.trim(),
              'to': _toController.text.trim(),
              'date': _selectedDate,
              'formattedDate': formattedDate,
            }
          },
        );
      } else {
        // Handle API error
        _showErrorDialog(response.message);
      }
    } catch (e) {
      // Handle unexpected errors
      print('❌ Unexpected error during search: $e');
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
      backgroundColor: const Color(0xFFF8FFFE),
      // Remove extendBodyBehindAppBar if you had it
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: 12.h),
                          _buildSearchCard(),
                          SizedBox(height: 20.h),
                          _buildSectionTitle("Popular Routes"),
                          _buildRoutesSection(),
                          SizedBox(height: 16.h),
                          _buildSectionTitle("Recent Searches"),
                          _buildRoutesSection(),
                          SizedBox(height: 60.h),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHeader() {
    return Container(
      // Add top padding to account for status bar
      padding: EdgeInsets.only(
        left: 24.w,
        right: 24.w,
        top: MediaQuery.of(context).padding.top +
            16.h, // Status bar height + extra padding
        bottom: 32.h,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6C63FF),
            const Color(0xFF9C88FF),
            const Color(0xFFB794FF)
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32.r),
          bottomRight: Radius.circular(32.r),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hi, Talha! 👋",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "Book your next journey",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF9C88FF), const Color(0xFFB794FF)],
          ),
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB794FF).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Locations",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 20.h),
            _buildSearchField(
                Icons.my_location_rounded, "From", _fromController, true),
            SizedBox(height: 16.h),
            _buildSearchField(
                Icons.location_on_rounded, "To", _toController, false),
            SizedBox(height: 16.h),
            _buildDatePicker(),
            SizedBox(height: 24.h),
            // Enhanced Search Button with loading state
            _buildSearchButton(),
          ],
        ),
      ),
    );
  }

  // New enhanced search button with loading state
  Widget _buildSearchButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: 54.h,
      decoration: BoxDecoration(
        color: _isLoading ? Colors.white.withOpacity(0.7) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: _isLoading
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: _isLoading ? null : _handleSearch,
          child: Center(
            child: _isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFF9C88FF),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        "Searching...",
                        style: TextStyle(
                          color: const Color(0xFF9C88FF),
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: const Color(0xFF9C88FF),
                        size: 24.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        "Search",
                        style: TextStyle(
                          color: const Color(0xFF9C88FF),
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(IconData icon, String hint,
      TextEditingController controller, bool isFrom) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        enabled: !_isLoading, // Disable when loading
        style: TextStyle(
          color: Colors.white,
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          prefixIcon: Container(
            margin: EdgeInsets.all(12.w),
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 16.sp,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: TextField(
        readOnly: true,
        enabled: !_isLoading, // Disable when loading
        onTap: _isLoading
            ? null
            : () async {
                DateTime now = DateTime.now();
                DateTime tomorrow = now.add(const Duration(days: 1));
                DateTime oneWeekLater = now.add(const Duration(days: 7));

                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: tomorrow,
                  firstDate: tomorrow,
                  lastDate: oneWeekLater,
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: const Color(0xFFFF6B6B),
                          onPrimary: Colors.white,
                          surface: Colors.white,
                          onSurface: Colors.black,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (pickedDate != null) {
                  setState(() {
                    _selectedDate = pickedDate;
                  });
                }
              },
        style: TextStyle(
          color: Colors.white,
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          prefixIcon: Container(
            margin: EdgeInsets.all(12.w),
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
          hintText: _selectedDate != null
              ? DateFormat("MMM dd, yyyy").format(_selectedDate!)
              : "Select Date",
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 16.sp,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2D3748),
            ),
          ),
          // Text(
          //   "View all",
          //   style: TextStyle(
          //     fontSize: 14.sp,
          //     fontWeight: FontWeight.w500,
          //     color: const Color(0xFF6C63FF),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildRoutesSection() {
    return SizedBox(
      height: 120.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        itemCount: 4,
        itemBuilder: (context, index) {
          final routes = [
            {
              "from": "Karachi",
              "to": "Lahore",
              "price": "PKR 1,500",
              "duration": "8h 30m"
            },
            {
              "from": "Lahore",
              "to": "Islamabad",
              "price": "PKR 1,200",
              "duration": "4h 45m"
            },
            {
              "from": "Karachi",
              "to": "Multan",
              "price": "PKR 1,800",
              "duration": "6h 15m"
            },
            {
              "from": "Faisalabad",
              "to": "Rawalpindi",
              "price": "PKR 1,000",
              "duration": "3h 20m"
            },
          ];

          return Container(
            width: 180.w,
            height: 120.h,
            margin: EdgeInsets.only(right: 16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50.w,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF6C63FF).withOpacity(0.8),
                        const Color(0xFF9C88FF).withOpacity(0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.r),
                      bottomLeft: Radius.circular(16.r),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.directions_bus_rounded,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(10.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${routes[index]["from"]} → ${routes[index]["to"]}",
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2D3748),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          "${routes[index]["price"]}",
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFF6B6B),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            routes[index]["duration"]!,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6C63FF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      margin: EdgeInsets.only(bottom: 20.h, left: 24.w, right: 24.w),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      height: 70.h,
      decoration: BoxDecoration(
        // gradient: LinearGradient(
        //   colors: [
        //     const Color(0xFF6C63FF).withOpacity(0.8),
        //     const Color(0xFF9C88FF).withOpacity(0.6),
        //   ],
        // ),
        color: const Color(0xFF6C63FF).withOpacity(0.8),
        borderRadius: BorderRadius.circular(35.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9C88FF).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _bottomNavItem(Icons.home_rounded, 0),
          _bottomNavItem(Icons.confirmation_number_rounded, 1),
          _bottomNavItem(Icons.person_rounded, 2),
        ],
      ),
    );
  }

  Widget _bottomNavItem(IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });

        // Navigate to BookingsHistoryScreen when middle icon (index 1) is clicked
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BookingsHistoryScreen(),
            ),
          );
        }
        // Add other navigation logic here if needed
        // if (index == 0) {
        //   // Navigate to Home
        // }
        // if (index == 2) {
        //   // Navigate to Profile
        // }
      },
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
          size: 26.sp,
        ),
      ),
    );
  }
}
