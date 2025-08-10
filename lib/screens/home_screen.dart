import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:roadway/Services/StorageService.dart';
import 'package:roadway/routes/app_routes.dart';
import 'package:roadway/screens/booking_history_screen.dart';
import 'package:roadway/widgets/custom_side_menu_bar.dart';
// import 'package:roadway/models/route_data.dart'; // Import the centralized RouteData
import '../Services/ApiCalls.dart';
import 'package:google_fonts/google_fonts.dart';

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
  bool _isLoading = false;
  bool _isLoadingRecentSearches = true;
  bool _isLoadingTopTrips = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Data lists
  List<RouteData> _popularRoutes = [];
  List<RouteData> _recentSearches = [];
  List<RouteData> _topTrips = [];

  @override
  void initState() {
    super.initState();
    // Set status bar to transparent
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 0),
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

    // Load data
    _loadPopularRoutes();
    _loadRecentSearches();
    _loadTopTrips();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  // Load top trips from API
  Future<void> _loadTopTrips() async {
    setState(() {
      _isLoadingTopTrips = true;
    });

    try {
      print('🚌 Loading top trips from API...');
      final response = await ApiCalls.getTopTrips();

      if (response.success && response.data != null) {
        final topTripsRoutes =
            response.data!.map((trip) => trip.toRouteData()).toList();

        print('✅ Successfully loaded ${topTripsRoutes.length} top trips');

        if (mounted) {
          setState(() {
            _topTrips = topTripsRoutes;
            _isLoadingTopTrips = false;
          });
        }
      } else {
        print('❌ Failed to load top trips: ${response.message}');
        _loadFallbackTopTrips();
      }
    } catch (e) {
      print('❌ Error loading top trips: $e');
      _loadFallbackTopTrips();
    }
  }

  String _getTimeBasedGreeting() {
    final hour = 12; //DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return "Good Morning ☀️";
    } else if (hour >= 12 && hour < 17) {
      return "Good Afternoon 🌤️";
    } else {
      return "Good Evening 🌙";
    }
  }

  // Fallback method with static data
  void _loadFallbackTopTrips() {
    if (mounted) {
      setState(() {
        _topTrips = [
          RouteData(
            from: "Lahore",
            to: "Peshawar",
            price: "PKR 3,000",
            duration: "12h 0m",
          ),
          RouteData(
            from: "Lahore",
            to: "Karachi",
            price: "PKR 1,100",
            duration: "8h 0m",
          ),
          RouteData(
            from: "Multan",
            to: "Lahore",
            price: "PKR 1,300",
            duration: "13h 0m",
          ),
          RouteData(
            from: "Lahore",
            to: "Faisalabad",
            price: "PKR 1,550",
            duration: "14h 0m",
          ),
        ];
        _isLoadingTopTrips = false;
      });
    }
  }

  // Load popular routes
  void _loadPopularRoutes() {
    setState(() {
      _popularRoutes = [
        RouteData(
          from: "Karachi",
          to: "Lahore",
          price: "PKR 1,500",
          duration: "8h 30m",
        ),
        RouteData(
          from: "Lahore",
          to: "Islamabad",
          price: "PKR 1,200",
          duration: "4h 45m",
        ),
        RouteData(
          from: "Karachi",
          to: "Multan",
          price: "PKR 1,800",
          duration: "6h 15m",
        ),
        RouteData(
          from: "Faisalabad",
          to: "Rawalpindi",
          price: "PKR 1,000",
          duration: "3h 20m",
        ),
      ];
    });
  }

  // Load recent searches from storage
  Future<void> _loadRecentSearches() async {
    setState(() {
      _isLoadingRecentSearches = true;
    });
    try {
      final recentSearches = await StorageService.getRecentSearches();
      print('📱 Loaded ${recentSearches.length} recent searches from storage');
      if (mounted) {
        setState(() {
          _recentSearches = recentSearches;
          _isLoadingRecentSearches = false;
        });
      }
    } catch (e) {
      print('❌ Error loading recent searches: $e');
      if (mounted) {
        setState(() {
          _recentSearches = [];
          _isLoadingRecentSearches = false;
        });
      }
    }
  }

  // Save search to recent searches
  Future<void> _saveToRecentSearches(
      String from, String to, DateTime date) async {
    try {
      final newSearch = RouteData.forRecentSearch(
        from: from,
        to: to,
        searchDate: date,
      );
      await StorageService.addRecentSearch(newSearch);
      print('💾 Saved recent search: $from → $to');
      await _loadRecentSearches();
    } catch (e) {
      print('❌ Error saving recent search: $e');
    }
  }

  // Clear all recent searches
  Future<void> _clearRecentSearches() async {
    try {
      await StorageService.clearRecentSearches();
      await _loadRecentSearches();
      _showSuccessDialog('Recent searches cleared successfully!');
    } catch (e) {
      print('❌ Error clearing recent searches: $e');
      _showErrorDialog('Failed to clear recent searches');
    }
  }

  // Navigate to bus list with route data
  Future<void> _navigateWithRouteData(RouteData route,
      {DateTime? customDate}) async {
    final searchDate = customDate ??
        route.searchDate ??
        DateTime.now().add(const Duration(days: 1));

    setState(() {
      _isLoading = true;
    });

    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(searchDate);
      print('🔍 Searching for: ${route.from} → ${route.to} on $formattedDate');

      final response = await ApiCalls.searchSlots(
        from: route.from,
        to: route.to,
        dateInput: formattedDate,
      );

      if (response.success && response.data != null) {
        _showSuccessDialog('Search completed successfully!');
        await _saveToRecentSearches(route.from, route.to, searchDate);
        Navigator.pushNamed(
          context,
          '/busList',
          arguments: {
            'searchResults': response.data,
            'searchParams': {
              'from': route.from,
              'to': route.to,
              'date': searchDate,
              'formattedDate': formattedDate,
            }
          },
        );
      } else {
        _showErrorDialog(response.message);
      }
    } catch (e) {
      print('❌ Unexpected error during search: $e');
      _showErrorDialog(
          'An unexpected error occurred. Please check your internet connection and try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Handle search function
  Future<void> _handleSearch() async {
    final validationError = _validateSearchForm();
    if (validationError != null) {
      _showErrorDialog(validationError);
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      print(
          '🔍 Manual search: ${_fromController.text.trim()} → ${_toController.text.trim()} on $formattedDate');

      final response = await ApiCalls.searchSlots(
        from: _fromController.text.trim(),
        to: _toController.text.trim(),
        dateInput: formattedDate,
      );

      if (response.success && response.data != null) {
        _showSuccessDialog('Search completed successfully!');
        print("Here are the Slots data : ${response.data}");

        await _saveToRecentSearches(
          _fromController.text.trim(),
          _toController.text.trim(),
          _selectedDate!,
        );

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
        _showErrorDialog(response.message);
      }
    } catch (e) {
      print('❌ Unexpected error during search: $e');
      _showErrorDialog(
          'An unexpected error occurred. Please check your internet connection and try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showGlobalLoader =
        _isLoading || _isLoadingRecentSearches || _isLoadingTopTrips;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      drawer: CustomSideMenuBar(
        onItemSelected: (index) {
          print('Menu item selected: $index');
        },
      ),
      body: Stack(
        // Use Stack to layer content and the loader
        children: [
          AnimatedBuilder(
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
                              _buildSectionTitle("Top Trips"),
                              _buildTopTripsSection(),
                              SizedBox(height: 16.h),
                              _buildRecentSearchesSection(),
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
          if (showGlobalLoader) // Conditionally display the loader overlay
            Positioned.fill(
              child: Container(
                color: const Color.fromARGB(255, 255, 255, 255)
                    .withOpacity(0.5), // Semi-transparent background
                child: Center(
                  child: Image.asset(
                    'assets/images/loader1.gif',
                    width: 100.w,
                    height: 100.h,
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // Build top trips section
  Widget _buildTopTripsSection() {
    // Remove individual loader for this section as we have a global one
    if (_topTrips.isEmpty && !_isLoadingTopTrips) {
      // Only show "No top trips" if not loading
      return SizedBox(
        height: 120.h,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.directions_bus_rounded,
                size: 32.sp,
                color: Colors.grey[400],
              ),
              SizedBox(height: 8.h),
              Text(
                "No top trips available",
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }
    // If loading, the global loader will cover this.
    // If not loading and not empty, display the list.
    if (_topTrips.isNotEmpty) {
      return SizedBox(
        height: 120.h,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          itemCount: _topTrips.length,
          itemBuilder: (context, index) {
            final route = _topTrips[index];
            return GestureDetector(
              onTap: () async {
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
                          primary: const Color(0xFF6C63FF),
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
                  _navigateWithRouteData(route, customDate: pickedDate);
                }
              },
              child: Container(
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
                            const Color(0xFFFF6B6B).withOpacity(0.8),
                            const Color(0xFFFF8E8E).withOpacity(0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16.r),
                          bottomLeft: Radius.circular(16.r),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.trending_up_rounded,
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
                              "${route.from} → ${route.to}",
                              style: GoogleFonts.poppins(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2D3748),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              route.price,
                              style: GoogleFonts.poppins(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFFF6B6B),
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B6B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                route.duration,
                                style: GoogleFonts.poppins(
                                  fontSize: 8.sp,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFFF6B6B),
                                ),
                              ),
                            ),
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
      );
    }
    return const SizedBox.shrink(); // Return empty widget if loading or empty
  }

  // Enhanced recent searches section with loading state
  Widget _buildRecentSearchesSection() {
    // Remove individual loader for this section as we have a global one
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent Searches",
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2D3748),
                ),
              ),
              if (_recentSearches.isNotEmpty && !_isLoadingRecentSearches)
                GestureDetector(
                  onTap: _clearRecentSearches,
                  child: Text(
                    "Clear All",
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.red[600],
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_recentSearches.isNotEmpty && !_isLoadingRecentSearches)
          _buildRoutesSection(_recentSearches, isPopular: false)
        else if (_recentSearches.isEmpty &&
            !_isLoadingRecentSearches) // Only show "No recent searches" if not loading
          SizedBox(
            height: 120.h,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 32.sp,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "No recent searches",
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          const SizedBox.shrink(), // Return empty widget if loading
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        left: 24.w,
        right: 24.w,
        top: MediaQuery.of(context).padding.top + 16.h,
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
              // Add drawer button on the left
              // In your _buildHeader method, replace the GestureDetector with:
              Builder(
                builder: (context) => GestureDetector(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: Container(
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
                      Icons.menu_rounded,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                ),
              ),
              // Center content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _getTimeBasedGreeting(),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "Book your next journey",
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // Notification button on the right
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
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 15.sp,
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
            _buildSearchButton(),
          ],
        ),
      ),
    );
  }

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
            child: Row(
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
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF9C88FF),
                    fontSize: 13.sp,
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
        enabled: !_isLoading,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 13.sp,
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
          hintStyle: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.8),
            fontSize: 13.sp,
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
        enabled: !_isLoading,
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
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 13.sp,
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
          hintStyle: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.8),
            fontSize: 13.sp,
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
            style: GoogleFonts.poppins(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2D3748),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutesSection(List<RouteData> routes,
      {required bool isPopular}) {
    if (routes.isEmpty) {
      return SizedBox(
        height: 120.h,
        child: Center(
          child: Text(
            isPopular ? "No popular routes available" : "No recent searches",
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 120.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        itemCount: routes.length,
        itemBuilder: (context, index) {
          final route = routes[index];
          return GestureDetector(
            onTap: () async {
              if (isPopular) {
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
                          primary: const Color(0xFF6C63FF),
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
                  _navigateWithRouteData(route, customDate: pickedDate);
                }
              } else {
                final searchDate = route.searchDate ??
                    DateTime.now().add(const Duration(days: 1));
                _navigateWithRouteData(route, customDate: searchDate);
              }
            },
            child: Container(
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
                        isPopular
                            ? Icons.directions_bus_rounded
                            : Icons.history_rounded,
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
                            "${route.from} → ${route.to}",
                            style: GoogleFonts.poppins(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2D3748),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            route.price,
                            style: GoogleFonts.poppins(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: isPopular
                                  ? const Color(0xFFFF6B6B)
                                  : const Color(0xFF6C63FF),
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
                              route.duration,
                              style: GoogleFonts.poppins(
                                fontSize: 8.sp,
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
          _bottomNavItem(Icons.campaign_rounded, 2),
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
        if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const BookingsHistoryScreen(),
            ),
          );
        } else if (index == 2) {
          Navigator.pushNamed(context, AppRoutes.announcements);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        }
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
