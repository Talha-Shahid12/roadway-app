import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roadway/screens/booking_history_screen.dart'; // Assuming this path is correct
import 'package:roadway/screens/home_screen.dart'; // Import your HomeScreen

// Define AppRoutes for consistent navigation, if not already defined elsewhere
class AppRoutes {
  static const String home = '/';
  static const String announcements = '/announcements';
  static const String bookingsHistory = '/bookingsHistory';
  // Add other routes as needed
}

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _emptyStateController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  // Search and filter functionality
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchActive = false;
  String selectedCategory = 'All';

  // Announcements data
  List<AnnouncementData> announcements = [];
  List<AnnouncementData> filteredAnnouncements = [];
  bool isLoading = false;

  // Categories for filtering
  final List<String> categories = [
    'All',
    'Service Updates',
    'Route Changes',
    'Promotions',
    'Maintenance',
    'Safety'
  ];

  // Current selected index for bottom navigation bar
  int _selectedIndex = 2; // Assuming Announcements is the 3rd tab (index 2)

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _emptyStateController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _emptyStateController,
      curve: Curves.elasticOut,
    ));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _emptyStateController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();

    // Listen to search input changes
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);

    // Load sample data
    _loadAnnouncements();
  }

  void _onSearchChanged() {
    _performSearch(_searchController.text);
  }

  void _onSearchFocusChanged() {
    setState(() {
      _isSearchActive = _searchFocusNode.hasFocus;
    });
  }

  void _performSearch(String query) {
    List<AnnouncementData> baseList = selectedCategory == 'All'
        ? announcements
        : announcements
            .where((announcement) => announcement.category == selectedCategory)
            .toList();

    if (query.isEmpty) {
      setState(() {
        filteredAnnouncements = List.from(baseList);
      });
      return;
    }

    final String lowercaseQuery = query.toLowerCase();
    setState(() {
      filteredAnnouncements = baseList.where((announcement) {
        final bool matchesTitle =
            announcement.title.toLowerCase().contains(lowercaseQuery);
        final bool matchesContent =
            announcement.content.toLowerCase().contains(lowercaseQuery);
        final bool matchesOperator =
            announcement.operatorName.toLowerCase().contains(lowercaseQuery);
        final bool matchesCategory =
            announcement.category.toLowerCase().contains(lowercaseQuery);
        return matchesTitle ||
            matchesContent ||
            matchesOperator ||
            matchesCategory;
      }).toList();
    });

    // Trigger empty state animation if no results
    if (filteredAnnouncements.isEmpty && announcements.isNotEmpty) {
      _emptyStateController.reset();
      _emptyStateController.forward();
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    _filterByCategory(selectedCategory);
  }

  void _filterByCategory(String category) {
    setState(() {
      selectedCategory = category;
      if (category == 'All') {
        filteredAnnouncements = List.from(announcements);
      } else {
        filteredAnnouncements = announcements
            .where((announcement) => announcement.category == category)
            .toList();
      }
    });
    // Re-apply search if there's a query
    if (_searchController.text.isNotEmpty) {
      _performSearch(_searchController.text);
    }
  }

  void _loadAnnouncements() {
    setState(() {
      isLoading = true;
    });
    // Simulate API loading delay
    Future.delayed(const Duration(milliseconds: 800), () {
      // Sample data - replace with actual API call
      announcements = [
        AnnouncementData(
          id: '1',
          title: 'New Route: Karachi to Hyderabad',
          content:
              'We\'re excited to announce a new direct route from Karachi to Hyderabad with comfortable AC buses. Daily departures starting from 6:00 AM.',
          operatorName: 'Faisal Movers',
          category: 'Service Updates',
          priority: AnnouncementPriority.high,
          publishedDate: DateTime.now().subtract(const Duration(hours: 2)),
          isRead: false,
          imageUrl: null,
        ),
        AnnouncementData(
          id: '2',
          title: 'Route Maintenance Notice',
          content:
              'Due to road construction on M2 highway, there might be delays of 30-45 minutes for Lahore-Islamabad route on weekdays.',
          operatorName: 'Daewoo Express',
          category: 'Maintenance',
          priority: AnnouncementPriority.medium,
          publishedDate: DateTime.now().subtract(const Duration(hours: 5)),
          isRead: true,
        ),
        AnnouncementData(
          id: '3',
          title: '🎉 Special Discount: 20% Off!',
          content:
              'Book your tickets now and get 20% discount on all routes. Offer valid until the end of this month. Use code: SAVE20',
          operatorName: 'Skyways',
          category: 'Promotions',
          priority: AnnouncementPriority.high,
          publishedDate: DateTime.now().subtract(const Duration(days: 1)),
          isRead: false,
        ),
        AnnouncementData(
          id: '4',
          title: 'Enhanced Safety Protocols',
          content:
              'We have implemented new safety measures including regular sanitization, temperature checks, and mandatory masks for all passengers.',
          operatorName: 'Bilal Travels',
          category: 'Safety',
          priority: AnnouncementPriority.medium,
          publishedDate: DateTime.now().subtract(const Duration(days: 2)),
          isRead: true,
        ),
        AnnouncementData(
          id: '5',
          title: 'Schedule Change: Morning Departures',
          content:
              'Starting next week, morning departure times for Karachi-Lahore route will be shifted 30 minutes earlier to avoid traffic congestion.',
          operatorName: 'Faisal Movers',
          category: 'Route Changes',
          priority: AnnouncementPriority.low,
          publishedDate: DateTime.now().subtract(const Duration(days: 3)),
          isRead: false,
        ),
        AnnouncementData(
          id: '6',
          title: 'WiFi Service Now Available',
          content:
              'Enjoy complimentary high-speed WiFi on all our premium coaches. Stay connected throughout your journey.',
          operatorName: 'Daewoo Express',
          category: 'Service Updates',
          priority: AnnouncementPriority.low,
          publishedDate: DateTime.now().subtract(const Duration(days: 5)),
          isRead: true,
        ),
      ];
      // Sort by date (newest first) and then by priority
      announcements.sort((a, b) {
        int priorityComparison = b.priority.index.compareTo(a.priority.index);
        if (priorityComparison != 0) return priorityComparison;
        return b.publishedDate.compareTo(a.publishedDate);
      });
      filteredAnnouncements = List.from(announcements);
      setState(() {
        isLoading = false;
      });
      if (announcements.isNotEmpty) {
        _animationController.forward();
      } else {
        _emptyStateController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emptyStateController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Widget _buildEmptyState() {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
          padding: EdgeInsets.all(32.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                const Color(0xFFF8FAFF),
              ],
            ),
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF6C63FF).withOpacity(0.1),
                      const Color(0xFF9C88FF).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(60.r),
                ),
                child: Icon(
                  Icons.campaign_rounded,
                  size: 64.sp,
                  color: const Color(0xFF6C63FF),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                "No Announcements",
                style: GoogleFonts.poppins(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                "There are no announcements to show right now. Check back later for updates from bus operators.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: _loadAnnouncements,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: Text(
                  "Refresh",
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchEmptyState() {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
          padding: EdgeInsets.all(32.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                const Color(0xFFF8FAFF),
              ],
            ),
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF6C63FF).withOpacity(0.1),
                      const Color(0xFF9C88FF).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(60.r),
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 64.sp,
                  color: const Color(0xFF6C63FF),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                "No Results Found",
                style: GoogleFonts.poppins(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  '"${_searchController.text}"',
                  style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6C63FF),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                "Try searching for operator names, announcement titles, or categories.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: _clearSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: Text(
                  "Clear Search",
                  style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Text(
          "Announcements",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: Colors.white,
            size: 20.sp,
          ),
          onPressed: () => {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              ),
            )
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Colors.white,
              size: 24.sp,
            ),
            onPressed: _loadAnnouncements,
          ),
        ],
        flexibleSpace: Container(
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
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32.r),
              bottomRight: Radius.circular(32.r),
            ),
          ),
        ),
      ),
      body: isLoading
          ? Center(
              child: Image.asset(
                'assets/images/loader1.gif',
                width: 100.w,
                height: 100.h,
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 16.h),
                  // Search Bar
                  if (announcements.isNotEmpty)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 16.w),
                        height: 45.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          border: _isSearchActive
                              ? Border.all(
                                  color: const Color(0xFF6C63FF),
                                  width: 2,
                                )
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          decoration: InputDecoration(
                            hintText: "Search announcements...",
                            hintStyle: GoogleFonts.poppins(
                              color: Colors.grey[400],
                              fontSize: 12.sp,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: _isSearchActive
                                  ? const Color(0xFF6C63FF)
                                  : Colors.grey[400],
                              size: 20.sp,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: Colors.grey[400],
                                      size: 18.sp,
                                    ),
                                    onPressed: _clearSearch,
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 12.h),
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                    ),
                  if (announcements.isNotEmpty) SizedBox(height: 16.h),
                  // Category Filter
                  if (announcements.isNotEmpty)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        height: 40.h,
                        margin: EdgeInsets.only(left: 16.w),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            final isSelected = selectedCategory == category;
                            return GestureDetector(
                              onTap: () => _filterByCategory(category),
                              child: Container(
                                margin: EdgeInsets.only(right: 12.w),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16.w, vertical: 8.h),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF6C63FF)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20.r),
                                  border: isSelected
                                      ? null
                                      : Border.all(
                                          color: Colors.grey[300]!,
                                          width: 1,
                                        ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF6C63FF)
                                                .withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  category,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  if (announcements.isNotEmpty) SizedBox(height: 16.h),
                  // Results Info
                  if (announcements.isNotEmpty)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${filteredAnnouncements.length} announcement${filteredAnnouncements.length == 1 ? '' : 's'}",
                              style: GoogleFonts.poppins(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (filteredAnnouncements
                                .where((a) => !a.isRead)
                                .isNotEmpty)
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF00C853).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Text(
                                  "${filteredAnnouncements.where((a) => !a.isRead).length} new",
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.sp,
                                    color: const Color(0xFF00C853),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  if (announcements.isNotEmpty) SizedBox(height: 8.h),
                  // Announcements List or Empty States
                  announcements.isEmpty
                      ? _buildEmptyState()
                      : filteredAnnouncements.isEmpty &&
                              _searchController.text.isNotEmpty
                          ? _buildSearchEmptyState()
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredAnnouncements.length,
                              itemBuilder: (context, index) {
                                return FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: Offset(0, 0.3),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(
                                      parent: _animationController,
                                      curve: Interval(
                                        (index * 0.1).clamp(0.0, 1.0),
                                        ((index * 0.1) + 0.3).clamp(0.0, 1.0),
                                        curve: Curves.easeOutCubic,
                                      ),
                                    )),
                                    child: AnnouncementCard(
                                      announcement:
                                          filteredAnnouncements[index],
                                      searchQuery: _searchController.text,
                                      onTap: () {
                                        // Mark as read when tapped
                                        setState(() {
                                          filteredAnnouncements[index] =
                                              filteredAnnouncements[index]
                                                  .copyWith(isRead: true);
                                          // Also update in main list
                                          final mainIndex =
                                              announcements.indexWhere((a) =>
                                                  a.id ==
                                                  filteredAnnouncements[index]
                                                      .id);
                                          if (mainIndex != -1) {
                                            announcements[mainIndex] =
                                                announcements[mainIndex]
                                                    .copyWith(isRead: true);
                                          }
                                        });
                                        // Navigate to detailed view
                                        _showAnnouncementDetails(
                                            filteredAnnouncements[index]);
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  void _showAnnouncementDetails(AnnouncementData announcement) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.only(top: 12.h),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with priority and category
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(announcement.priority)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            announcement.category,
                            style: GoogleFonts.poppins(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: _getPriorityColor(announcement.priority),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(announcement.priority),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            announcement.priority.name.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    // Title
                    Text(
                      announcement.title,
                      style: GoogleFonts.poppins(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    // Operator and date
                    Row(
                      children: [
                        Icon(
                          Icons.business,
                          size: 16.sp,
                          color: Colors.grey[500],
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          announcement.operatorName,
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6C63FF),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.access_time,
                          size: 16.sp,
                          color: Colors.grey[500],
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          _getRelativeTime(announcement.publishedDate),
                          style: GoogleFonts.poppins(
                            fontSize: 11.sp,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    // Content
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        announcement.content,
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          color: const Color(0xFF1A1A1A),
                          height: 1.5,
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    // Close button
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          "Close",
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
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
  }

  Color _getPriorityColor(AnnouncementPriority priority) {
    switch (priority) {
      case AnnouncementPriority.high:
        return const Color(0xFFFF5722);
      case AnnouncementPriority.medium:
        return const Color(0xFFFF9800);
      case AnnouncementPriority.low:
        return const Color(0xFF4CAF50);
    }
  }

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(dateTime);
    }
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
          _bottomNavItem(Icons.campaign_rounded,
              2), // Changed to campaign_rounded for announcements
        ],
      ),
    );
  }

  Widget _bottomNavItem(IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        if (_selectedIndex == index) {
          // Do nothing if already on the selected tab
          return;
        }
        setState(() {
          _selectedIndex = index;
        });
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
          );
        } else if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const BookingsHistoryScreen(),
            ),
          );
        } else if (index == 2) {
          // Already on AnnouncementsScreen, no need to navigate
          // If you want to refresh the screen, you could call _loadAnnouncements()
          // _loadAnnouncements();
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

// Data models
enum AnnouncementPriority { high, medium, low }

class AnnouncementData {
  final String id;
  final String title;
  final String content;
  final String operatorName;
  final String category;
  final AnnouncementPriority priority;
  final DateTime publishedDate;
  final bool isRead;
  final String? imageUrl;

  const AnnouncementData({
    required this.id,
    required this.title,
    required this.content,
    required this.operatorName,
    required this.category,
    required this.priority,
    required this.publishedDate,
    required this.isRead,
    this.imageUrl,
  });

  AnnouncementData copyWith({
    String? id,
    String? title,
    String? content,
    String? operatorName,
    String? category,
    AnnouncementPriority? priority,
    DateTime? publishedDate,
    bool? isRead,
    String? imageUrl,
  }) {
    return AnnouncementData(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      operatorName: operatorName ?? this.operatorName,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      publishedDate: publishedDate ?? this.publishedDate,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class AnnouncementCard extends StatelessWidget {
  final AnnouncementData announcement;
  final VoidCallback onTap;
  final String searchQuery;

  const AnnouncementCard({
    super.key,
    required this.announcement,
    required this.onTap,
    this.searchQuery = '',
  });

  // Helper method to highlight search terms
  Widget _buildHighlightedText(String text, TextStyle style) {
    if (searchQuery.isEmpty) {
      return Text(text, style: style);
    }
    final String lowerText = text.toLowerCase();
    final String lowerQuery = searchQuery.toLowerCase();
    if (!lowerText.contains(lowerQuery)) {
      return Text(text, style: style);
    }

    final List<TextSpan> spans = [];
    int currentMatchIndex = 0;

    // Split the text by the search query (case-insensitive)
    final RegExp exp = RegExp(lowerQuery, caseSensitive: false);
    text.splitMapJoin(
      exp,
      onMatch: (Match m) {
        final String matchedText = text.substring(m.start, m.end);
        spans.add(
          TextSpan(
            text: matchedText,
            style: style.copyWith(
              backgroundColor: const Color(0xFF6C63FF).withOpacity(0.2),
              color: const Color(0xFF6C63FF),
              fontWeight: FontWeight.w700,
            ),
          ),
        );
        return matchedText;
      },
      onNonMatch: (String nonMatch) {
        spans.add(TextSpan(text: nonMatch, style: style));
        return nonMatch;
      },
    );

    return RichText(text: TextSpan(children: spans));
  }

  Color _getPriorityColor(AnnouncementPriority priority) {
    switch (priority) {
      case AnnouncementPriority.high:
        return const Color(0xFFFF5722);
      case AnnouncementPriority.medium:
        return const Color(0xFFFF9800);
      case AnnouncementPriority.low:
        return const Color(0xFF4CAF50);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'service updates':
        return Icons.update;
      case 'route changes':
        return Icons.route;
      case 'promotions':
        return Icons.local_offer;
      case 'maintenance':
        return Icons.build;
      case 'safety':
        return Icons.security;
      default:
        return Icons.campaign;
    }
  }

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: !announcement.isRead
            ? Border.all(
                color:
                    _getPriorityColor(announcement.priority).withOpacity(0.3),
                width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(announcement.isRead ? 0.05 : 0.08),
            blurRadius: announcement.isRead ? 8 : 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          splashColor:
              _getPriorityColor(announcement.priority).withOpacity(0.1),
          highlightColor:
              _getPriorityColor(announcement.priority).withOpacity(0.05),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with unread indicator, category, and priority
                Row(
                  children: [
                    // Unread indicator
                    if (!announcement.isRead)
                      Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: BoxDecoration(
                          color: _getPriorityColor(announcement.priority),
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (!announcement.isRead) SizedBox(width: 8.w),
                    // Category icon and name
                    Icon(
                      _getCategoryIcon(announcement.category),
                      size: 16.sp,
                      color: _getPriorityColor(announcement.priority),
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        announcement.category,
                        style: GoogleFonts.poppins(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: _getPriorityColor(announcement.priority),
                        ),
                      ),
                    ),
                    // Priority badge
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(announcement.priority),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        announcement.priority.name.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 8.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                // Title
                _buildHighlightedText(
                  announcement.title,
                  GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: announcement.isRead
                        ? Colors.grey[700]
                        : const Color(0xFF1A1A1A),
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 8.h),
                // Content preview (first 2 lines)
                _buildHighlightedText(
                  announcement.content.length > 100
                      ? '${announcement.content.substring(0, 100)}...'
                      : announcement.content,
                  GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: announcement.isRead
                        ? Colors.grey[500]
                        : Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 12.h),
                // Footer with operator and time
                Row(
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.business,
                            size: 12.sp,
                            color: const Color(0xFF6C63FF),
                          ),
                          SizedBox(width: 4.w),
                          _buildHighlightedText(
                            announcement.operatorName,
                            GoogleFonts.poppins(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6C63FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Time
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12.sp,
                          color: Colors.grey[400],
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          _getRelativeTime(announcement.publishedDate),
                          style: GoogleFonts.poppins(
                            fontSize: 10.sp,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
