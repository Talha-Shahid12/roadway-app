import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class BusListScreen extends StatefulWidget {
  const BusListScreen({super.key});

  @override
  State<BusListScreen> createState() => _BusListScreenState();
}

class _BusListScreenState extends State<BusListScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _emptyStateController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchActive = false;

  String selectedFilter = 'All';
  String sortBy = 'Price';

  // Variables to store API data
  List<BusData> buses = [];
  List<BusData> filteredBuses = [];
  Map<String, dynamic>? searchParams;
  dynamic searchResults;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
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

    // Process the received data after initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processReceivedData();
    });
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
    if (query.isEmpty) {
      setState(() {
        filteredBuses = List.from(buses);
      });
      return;
    }

    final String lowercaseQuery = query.toLowerCase();

    setState(() {
      filteredBuses = buses.where((bus) {
        // Search in pickup location
        final bool matchesPickup =
            bus.pickupLocation.toLowerCase().contains(lowercaseQuery);

        // Search in dropoff location
        final bool matchesDropoff =
            bus.dropoffLocation.toLowerCase().contains(lowercaseQuery);

        // Search in fare (extract numeric value for comparison)
        final bool matchesFare = _searchInFare(bus.fare, lowercaseQuery);

        // Search in service name
        final bool matchesService =
            bus.serviceName.toLowerCase().contains(lowercaseQuery);

        // Search in formatted date
        final bool matchesDate =
            bus.formattedDate.toLowerCase().contains(lowercaseQuery);

        return matchesPickup ||
            matchesDropoff ||
            matchesFare ||
            matchesService ||
            matchesDate;
      }).toList();
    });

    // Trigger empty state animation if no results
    if (filteredBuses.isEmpty && buses.isNotEmpty) {
      _emptyStateController.reset();
      _emptyStateController.forward();
    }
  }

  bool _searchInFare(String fare, String query) {
    // Extract numbers from fare string for numeric comparison
    final RegExp numberRegExp = RegExp(r'\d+');
    final Iterable<RegExpMatch> matches = numberRegExp.allMatches(fare);

    for (final match in matches) {
      final String fareNumber = match.group(0)!;
      if (fareNumber.contains(query)) {
        return true;
      }
    }

    // Also check if the query is a number and compare with fare value
    final double? queryNumber = double.tryParse(query);
    if (queryNumber != null) {
      final String fareNumbers = matches.map((m) => m.group(0)).join();
      final double? fareValue = double.tryParse(fareNumbers);
      if (fareValue != null) {
        // Allow some tolerance in fare search (within 500 PKR range)
        return (fareValue - queryNumber).abs() <= 500;
      }
    }

    return false;
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      filteredBuses = List.from(buses);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (isLoading) {
      _processReceivedData();
    }
  }

  void _processReceivedData() {
    // Get the arguments passed from HomeScreen
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (arguments != null) {
      searchResults = arguments['searchResults'];
      searchParams = arguments['searchParams'];

      print('🔍 Received search results: $searchResults');
      print('🔍 Received search params: $searchParams');

      if (searchResults != null) {
        _convertApiDataToBusList();
      }
    }

    // Always set loading to false and show empty state if no buses
    setState(() {
      isLoading = false;
      filteredBuses = List.from(buses);
      if (buses.isEmpty) {
        _emptyStateController.forward();
      }
    });
  }

  void _convertApiDataToBusList() {
    try {
      buses.clear();

      // Handle the API response structure
      if (searchResults != null) {
        List<dynamic> tripsList = [];

        // Handle SearchSlotsResponse object
        if (searchResults.trips != null && searchResults.trips is List) {
          tripsList = searchResults.trips;
        }
        // Handle direct Map response with 'trips' key
        else if (searchResults is Map &&
            searchResults['trips'] != null &&
            searchResults['trips'] is List) {
          tripsList = searchResults['trips'];
        }

        print('🚌 Processing ${tripsList.length} trips from API');

        // Convert trips to BusData objects
        for (var tripData in tripsList) {
          // Handle both SlotData objects and Map objects
          Map<String, dynamic> slotMap;
          Map<String, dynamic> tripMap;

          if (tripData is Map<String, dynamic>) {
            slotMap = tripData;
            tripMap = tripData['trip'] ?? {};
          } else {
            // If tripData is a SlotData object, convert to Map
            slotMap = {
              'id': tripData.id,
              'tripId': tripData.tripId,
              'totalSeats': tripData.totalSeats,
              'availableSeats': tripData.availableSeats,
              'baseFare': tripData.baseFare,
              'busNumber': tripData.busNumber,
              'date': tripData.date,
              'slotStatus': tripData.slotStatus,
            };

            print(" 📥 SLoteId: ${tripData.id}");
            tripMap = tripData.trip != null
                ? {
                    'pickupLocation': tripData.trip.pickupLocation,
                    'destination': tripData.trip.destination,
                    'departureTime': tripData.trip.departureTime,
                    'arrivalTime': tripData.trip.arrivalTime,
                    'fare': tripData.trip.fare,
                    'busNumber': tripData.trip.busNumber,
                  }
                : {};
          }

          // Only process if we have valid data
          if (slotMap['slotStatus'] == 'Active' ||
              slotMap['slotStatus'] == 'AVAILABLE' ||
              slotMap['availableSeats'] != null) {
            // Extract service name from bus number or use default
            String serviceName = 'Bus Service';
            String busNumber =
                slotMap['busNumber'] ?? tripMap['busNumber'] ?? '';
            if (busNumber.isNotEmpty) {
              // You can customize this logic based on your bus numbering system
              serviceName = 'Faisal Movers';
            }

            // Parse the date from API
            DateTime? travelDate;
            String formattedDate = '';

            try {
              if (slotMap['date'] != null) {
                if (slotMap['date'] is String) {
                  travelDate = DateTime.parse(slotMap['date']);
                } else if (slotMap['date'] is DateTime) {
                  travelDate = slotMap['date'];
                }

                if (travelDate != null) {
                  formattedDate = DateFormat('EEE, MMM dd').format(travelDate);
                }
              }
            } catch (e) {
              print('⚠️ Error parsing date: ${slotMap['date']} - $e');
              // Fallback to search params date if available
              if (searchParams != null && searchParams!['date'] != null) {
                if (searchParams!['date'] is DateTime) {
                  travelDate = searchParams!['date'];
                  formattedDate = DateFormat('EEE, MMM dd').format(travelDate!);
                } else if (searchParams!['formattedDate'] != null) {
                  formattedDate = searchParams!['formattedDate'];
                }
              }
            }

            buses.add(BusData(
              slotId: slotMap['id'],
              tripId: slotMap['tripId'],
              serviceName: serviceName,
              busType: 'AC Bus', // Default since not provided in API
              pickupLocation: searchParams?['from'] ??
                  tripMap['pickupLocation'] ??
                  'Departure',
              dropoffLocation: searchParams?['to'] ??
                  tripMap['destination'] ??
                  'Destination',
              departureTime: tripMap['departureTime'] ?? '10:00 PM',
              arrivalTime: tripMap['arrivalTime'] ?? '6:00 AM',
              fare: _formatFare(
                  slotMap['baseFare'] ?? tripMap['fare'] ?? slotMap['fare']),
              duration: _calculateDuration(
                      tripMap['departureTime'], tripMap['arrivalTime']) ??
                  '8h 00m',
              rating: 4.2, // Default rating since not provided in API
              totalSeats: slotMap['totalSeats'] ?? 40,
              availableSeats: slotMap['availableSeats'] ?? 15,
              amenities: const ["WiFi", "AC", "TV"], // Default amenities
              travelDate: travelDate,
              formattedDate: formattedDate.isNotEmpty
                  ? formattedDate
                  : 'Date not available',
            ));
          }
        }
      }

      print('✅ Successfully converted ${buses.length} buses from API data');
    } catch (e) {
      print('❌ Error converting API data: $e');
      print('❌ Error details: ${e.toString()}');
      print('❌ SearchResults type: ${searchResults.runtimeType}');
      // Don't load fallback data - let it show empty state
    }
  }

  String _formatFare(dynamic fare) {
    if (fare == null) return 'PKR 0';

    try {
      if (fare is String) {
        // If already formatted
        if (fare.contains('PKR') || fare.contains('Rs')) {
          return fare;
        }
        // Try to parse as number
        double amount = double.parse(fare);
        return 'PKR ${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
      } else if (fare is num) {
        return 'PKR ${fare.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
      }
    } catch (e) {
      print('⚠️ Error formatting fare: $e');
    }

    return 'PKR ${fare.toString()}';
  }

  String? _calculateDuration(dynamic departureTime, dynamic arrivalTime) {
    if (departureTime == null || arrivalTime == null) return null;

    try {
      DateTime? depTime;
      DateTime? arrTime;

      // Parse departure time
      if (departureTime is String) {
        depTime = _parseTimeString(departureTime.trim());
      }

      // Parse arrival time
      if (arrivalTime is String) {
        arrTime = _parseTimeString(arrivalTime.trim());
      }

      if (depTime != null && arrTime != null) {
        // If arrival time is earlier than departure time, assume it's next day
        if (arrTime.isBefore(depTime)) {
          arrTime = arrTime.add(const Duration(days: 1));
        }

        Duration duration = arrTime.difference(depTime);
        int hours = duration.inHours;
        int minutes = duration.inMinutes.remainder(60);
        return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
      }
    } catch (e) {
      print('⚠️ Error calculating duration: $e');
      print('⚠️ Departure: $departureTime, Arrival: $arrivalTime');
    }

    return null;
  }

  DateTime? _parseTimeString(String timeString) {
    try {
      // Handle 12-hour format like "01:00 PM" or "09:00 AM"
      if (timeString.toUpperCase().contains('AM') ||
          timeString.toUpperCase().contains('PM')) {
        bool isPM = timeString.toUpperCase().contains('PM');

        // Remove AM/PM and clean the string
        String cleanTime =
            timeString.replaceAll(RegExp(r'[APap][Mm]'), '').trim();

        if (cleanTime.contains(':')) {
          final parts = cleanTime.split(':');
          if (parts.length >= 2) {
            // Clean up the parts to remove any non-numeric characters
            String hourPart = parts[0].replaceAll(RegExp(r'[^0-9]'), '').trim();
            String minutePart =
                parts[1].replaceAll(RegExp(r'[^0-9]'), '').trim();

            if (hourPart.isNotEmpty && minutePart.isNotEmpty) {
              int hour = int.parse(hourPart);
              int minute = int.parse(minutePart);

              // Convert 12-hour to 24-hour format
              if (isPM && hour != 12) {
                hour += 12;
              } else if (!isPM && hour == 12) {
                hour = 0;
              }

              // Validate ranges
              if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
                return DateTime(2023, 1, 1, hour, minute);
              }
            }
          }
        }
      }
      // Handle 24-hour format like "13:00" or "01:30"
      else if (timeString.contains(':')) {
        final parts = timeString.split(':');
        if (parts.length >= 2) {
          String hourPart = parts[0].replaceAll(RegExp(r'[^0-9]'), '').trim();
          String minutePart = parts[1].replaceAll(RegExp(r'[^0-9]'), '').trim();

          if (hourPart.isNotEmpty && minutePart.isNotEmpty) {
            int hour = int.parse(hourPart);
            int minute = int.parse(minutePart);

            if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
              return DateTime(2023, 1, 1, hour, minute);
            }
          }
        }
      }
    } catch (e) {
      print('⚠️ Error parsing time string: $timeString - $e');
    }

    return null;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emptyStateController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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
              // Search icon
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
                style: TextStyle(
                  fontSize: 24.sp,
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
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6C63FF),
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              Text(
                "Try searching for:",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),

              SizedBox(height: 12.h),

              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  children: [
                    _buildSearchTip("• City names (Karachi, Lahore, etc.)"),
                    SizedBox(height: 8.h),
                    _buildSearchTip("• Price ranges (1500, 2000, etc.)"),
                    SizedBox(height: 8.h),
                    _buildSearchTip("• Bus services (Faisal, etc.)"),
                    SizedBox(height: 8.h),
                    _buildSearchTip("• Dates (Aug 03, Fri, etc.)"),
                  ],
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
                  style: TextStyle(
                    fontSize: 16.sp,
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

  Widget _buildSearchTip(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14.sp,
          color: Colors.grey[600],
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildBeautifulEmptyState() {
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
                  Icons.directions_bus_rounded,
                  size: 64.sp,
                  color: const Color(0xFF6C63FF),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                "No Buses Found",
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 12.h),
              if (searchParams != null)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    "${searchParams!['from']} → ${searchParams!['to']}",
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6C63FF),
                    ),
                  ),
                ),
              SizedBox(height: 16.h),
              Text(
                "We couldn't find any buses for your selected route and date. This might be due to:",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  children: [
                    _buildReasonItem("• No available seats on this route."),
                    SizedBox(height: 8.h),
                    _buildReasonItem("• Buses fully booked."),
                    SizedBox(height: 8.h),
                    _buildReasonItem("• Route temporarily unavailable."),
                  ],
                ),
              ),
              SizedBox(height: 32.h),
              Container(
                width: double.infinity,
                height: 56.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: const Color(0xFF6C63FF).withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16.r),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(16.r),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: const Color(0xFF6C63FF),
                          size: 18.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          "Try Different Date",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6C63FF),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReasonItem(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14.sp,
          color: Colors.grey[600],
          height: 1.3,
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
          "Available Buses",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
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
          onPressed: () => Navigator.pop(context),
        ),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF6C63FF),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    "Loading available buses...",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 16.h),

                  // Search route info section
                  if (searchParams != null && buses.isNotEmpty)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 16.w),
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${searchParams!['from']} → ${searchParams!['to']}",
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    searchParams!['date'] != null
                                        ? DateFormat('EEE, MMM dd')
                                            .format(searchParams!['date'])
                                        : searchParams!['formattedDate'] ?? '',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.swap_horiz,
                              color: const Color(0xFF6C63FF),
                              size: 24.sp,
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (buses.isNotEmpty) SizedBox(height: 12.h),

                  // Search and Filter Section (only show if buses exist)
                  if (buses.isNotEmpty)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        margin: EdgeInsets.all(16.w),
                        child: Row(
                          children: [
                            // Search Bar
                            Expanded(
                              child: Container(
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
                                    hintText:
                                        "Search by city, fare, service, date...",
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14.sp,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: _isSearchActive
                                          ? const Color(0xFF6C63FF)
                                          : Colors.grey[400],
                                      size: 20.sp,
                                    ),
                                    suffixIcon:
                                        _searchController.text.isNotEmpty
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
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: const Color(0xFF1A1A1A),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            // Sort Button
                            Container(
                              height: 45.h,
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6C63FF),
                                borderRadius: BorderRadius.circular(12.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6C63FF)
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.sort,
                                    color: Colors.white,
                                    size: 16.sp,
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    sortBy,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Results Info (only show if buses exist)
                  if (buses.isNotEmpty)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${filteredBuses.length} bus${filteredBuses.length == 1 ? '' : 'es'} found",
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF6C63FF).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Text(
                                  "Searching...",
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: const Color(0xFF6C63FF),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                  if (buses.isNotEmpty) SizedBox(height: 8.h),

                  // Bus List, Search Empty State, or No Buses State
                  buses.isEmpty
                      ? _buildBeautifulEmptyState()
                      : filteredBuses.isEmpty &&
                              _searchController.text.isNotEmpty
                          ? _buildSearchEmptyState()
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredBuses.length,
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
                                    child: AestheticBusCard(
                                      busData: filteredBuses[index],
                                      searchQuery: _searchController.text,
                                      onTap: () {
                                        print(
                                            "filteredBuses[$index] - SlotId: ${filteredBuses[index].slotId}, tripId: ${filteredBuses[index].tripId} ");
                                        Navigator.pushNamed(
                                          context,
                                          '/busDetail',
                                          arguments: {
                                            'slotId':
                                                filteredBuses[index].slotId,
                                            'busData': {
                                              'tripId':
                                                  filteredBuses[index].tripId,
                                              'serviceName':
                                                  filteredBuses[index]
                                                      .serviceName,
                                              'departureTime':
                                                  filteredBuses[index]
                                                      .departureTime,
                                              'arrivalTime':
                                                  filteredBuses[index]
                                                      .arrivalTime,
                                              'pickupLocation':
                                                  filteredBuses[index]
                                                      .pickupLocation,
                                              'dropoffLocation':
                                                  filteredBuses[index]
                                                      .dropoffLocation,
                                              'travelDate': filteredBuses[index]
                                                  .travelDate
                                              // Add other fields as needed
                                            },
                                          },
                                        );
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
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
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
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Text(
                "Filter & Sort",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Filter options would go here
          ],
        ),
      ),
    );
  }
}

// Enhanced AestheticBusCard with search highlighting and date display
class AestheticBusCard extends StatelessWidget {
  final BusData busData;
  final VoidCallback onTap;
  final String searchQuery;

  const AestheticBusCard({
    super.key,
    required this.busData,
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
    final List<String> parts =
        text.split(RegExp(lowerQuery, caseSensitive: false));

    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        spans.add(TextSpan(text: parts[i], style: style));
      }

      if (i < parts.length - 1) {
        final int startIndex = lowerText.indexOf(
            lowerQuery,
            spans.fold<int>(
                0, (prev, span) => prev + (span.text?.length ?? 0)));
        if (startIndex >= 0) {
          final String matchedText =
              text.substring(startIndex, startIndex + searchQuery.length);
          spans.add(TextSpan(
            text: matchedText,
            style: style.copyWith(
              backgroundColor: const Color(0xFF6C63FF).withOpacity(0.2),
              color: const Color(0xFF6C63FF),
              fontWeight: FontWeight.w700,
            ),
          ));
        }
      }
    }

    return RichText(text: TextSpan(children: spans));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: searchQuery.isNotEmpty && _isSearchMatch()
            ? Border.all(
                color: const Color(0xFF6C63FF).withOpacity(0.3), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.r),
          splashColor: const Color(0xFF6C63FF).withOpacity(0.1),
          highlightColor: const Color(0xFF6C63FF).withOpacity(0.05),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with service name, date badge, and fare
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Expanded(
                              //   child: _buildHighlightedText(
                              //     busData.serviceName,
                              //     TextStyle(
                              //       fontSize: 16.sp,
                              //       fontWeight: FontWeight.w700,
                              //       color: const Color(0xFF1A1A1A),
                              //     ),
                              //   ),
                              // ),
                              // Date Badge - prominently displayed
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12.w, vertical: 6.h),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF6C63FF),
                                      const Color(0xFF9C88FF),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6C63FF)
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      color: Colors.white,
                                      size: 12.sp,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      busData.formattedDate,
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildHighlightedText(
                          busData.fare,
                          TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF00C853),
                          ),
                        ),
                        Text(
                          "per person",
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 20.h),

                // Route with animated timeline
                Row(
                  children: [
                    // Departure
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            busData.departureTime,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          _buildHighlightedText(
                            busData.pickupLocation,
                            TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Journey visualization
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8.w,
                                height: 8.w,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00C853),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 2.h,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF00C853),
                                        const Color(0xFF6C63FF),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 8.w,
                                height: 8.w,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6C63FF),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            busData.duration,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Arrival
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            busData.arrivalTime,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          _buildHighlightedText(
                            busData.dropoffLocation,
                            TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // Amenities and seat info
                Row(
                  children: [
                    // Amenities
                    Expanded(
                      child: Wrap(
                        spacing: 6.w,
                        children: busData.amenities.take(3).map((amenity) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              amenity,
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6C63FF),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Seat availability
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: busData.availableSeats < 5
                            ? Colors.red.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.event_seat,
                            color: busData.availableSeats < 5
                                ? Colors.red[600]
                                : Colors.green[600],
                            size: 14.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            "${busData.availableSeats} left",
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: busData.availableSeats < 5
                                  ? Colors.red[600]
                                  : Colors.green[600],
                            ),
                          ),
                        ],
                      ),
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

  bool _isSearchMatch() {
    if (searchQuery.isEmpty) return false;

    final String query = searchQuery.toLowerCase();
    return busData.serviceName.toLowerCase().contains(query) ||
        busData.pickupLocation.toLowerCase().contains(query) ||
        busData.dropoffLocation.toLowerCase().contains(query) ||
        busData.fare.toLowerCase().contains(query) ||
        busData.formattedDate.toLowerCase().contains(query);
  }
}

class BusData {
  final String slotId;
  final String tripId;
  final String serviceName;
  final String busType;
  final String pickupLocation;
  final String dropoffLocation;
  final String departureTime;
  final String arrivalTime;
  final String fare;
  final String duration;
  final double rating;
  final int totalSeats;
  final int availableSeats;
  final List<String> amenities;
  final DateTime? travelDate; // Added date field
  final String formattedDate; // Added formatted date for display

  const BusData({
    required this.slotId,
    required this.tripId,
    required this.serviceName,
    required this.busType,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.departureTime,
    required this.arrivalTime,
    required this.fare,
    required this.duration,
    required this.rating,
    required this.totalSeats,
    required this.availableSeats,
    required this.amenities,
    this.travelDate,
    required this.formattedDate,
  });
}
