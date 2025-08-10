import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../Services/ApiCalls.dart';
import 'package:google_fonts/google_fonts.dart';

class BusDetailScreen extends StatefulWidget {
  const BusDetailScreen({super.key});

  @override
  State<BusDetailScreen> createState() => _BusDetailScreenState();
}

class _BusDetailScreenState extends State<BusDetailScreen>
    with TickerProviderStateMixin {
  // Changed from List<int> to Map<int, String> to store seat number and gender
  Map<int, String> selectedSeats =
      {}; // seat number -> gender ('male' or 'female')
  List<Map<String, dynamic>> seatStatusData = [];

  // User data - you should get this from your user session/storage
  String? currentUserGender; // 'male' or 'female' - get from user session
  bool isLoading = true;
  String? slotId;
  Map<String, dynamic>? busData;
  double baseFare = 0;
  String? errorMessage; // Add this to store error messages

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _scaleController.forward();

    // TODO: Get current user gender from your user session/storage
    currentUserGender = 'female'; // Temporary - replace with actual user gender
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get arguments from ModalRoute
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (arguments != null) {
      print("Arguments received: $arguments");
      slotId = arguments['slotId'] as String?;
      busData = arguments['busData'] as Map<String, dynamic>?;
      print("SlotId in details screen :: $slotId");
    } else {
      print("Arguments are null");
    }

    // Move the seat data loading here to ensure context is ready
    if (isLoading && mounted) {
      _loadSeatData();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _loadSeatData() async {
    if (slotId == null) {
      setState(() {
        errorMessage = 'Slot ID is required';
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiCalls.getSlotData(slotId: slotId!);

      if (response.success && response.data != null) {
        if (response.responseCode == "00") {
          setState(() {
            // Convert SeatStatus objects to Map<String, dynamic> for compatibility
            seatStatusData = response.data!.slot.seatStatus
                .map((seatStatus) => {
                      'seatNumber': seatStatus.seatNumber,
                      'status': seatStatus.status,
                      'gender': seatStatus.gender,
                      'bookedBy': seatStatus.bookedBy,
                      'bookingId': seatStatus.bookingId,
                      'bookedAt': seatStatus.bookedAt,
                      '_id': seatStatus.id,
                    })
                .toList();

            baseFare = response.data!.slot.baseFare;
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = response.message;
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = response.message;
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading seat data: $e');
      setState(() {
        errorMessage = 'Failed to load seat data. Please try again.';
        isLoading = false;
      });
    }
  }

  Color getSeatColor(Map<String, dynamic> seat) {
    String status = seat['status'] ?? 'Available';
    String? gender = seat['gender'];
    int seatNumber = seat['seatNumber'] ?? 0;

    // Check if this seat is selected by user
    if (selectedSeats.containsKey(seatNumber)) {
      String selectedGender = selectedSeats[seatNumber]!;
      if (selectedGender == 'female') {
        return const Color.fromARGB(255, 31, 48, 230); // Blue for females
      } else if (selectedGender == 'male') {
        return const Color(0xFFFF9800); // Orange for males
      }
    }

    switch (status) {
      case 'Available':
        return const Color(0xFFF5F7FA);
      case 'Booked':
        if (gender == 'female') {
          return const Color.fromARGB(255, 31, 48, 230); // Blue for females
        } else if (gender == 'male') {
          return const Color(0xFFFF9800); // Orange for males
        } else {
          return const Color(0xFFFF5252); // Red for unknown gender
        }
      default:
        return const Color(0xFFF5F7FA);
    }
  }

  Color getSeatBorderColor(Map<String, dynamic> seat) {
    String status = seat['status'] ?? 'Available';
    String? gender = seat['gender'];
    int seatNumber = seat['seatNumber'] ?? 0;

    // Check if this seat is selected by user
    if (selectedSeats.containsKey(seatNumber)) {
      String selectedGender = selectedSeats[seatNumber]!;
      if (selectedGender == 'female') {
        return const Color.fromARGB(255, 30, 81, 233);
      } else if (selectedGender == 'male') {
        return const Color(0xFFFF9800);
      }
    }

    switch (status) {
      case 'Available':
        return Colors.grey[300]!;
      case 'Booked':
        if (gender == 'female') {
          return const Color.fromARGB(255, 30, 81, 233);
        } else if (gender == 'male') {
          return const Color(0xFFFF9800);
        } else {
          return const Color(0xFFFF5252);
        }
      default:
        return Colors.grey[300]!;
    }
  }

  List<int> getAdjacentSeats(int seatNumber) {
    List<int> adjacent = [];

    // For seats 1-44 (regular 4-seat rows)
    if (seatNumber <= 44) {
      int rowStart = ((seatNumber - 1) ~/ 4) * 4 + 1;

      // Check left seat
      if (seatNumber > rowStart) {
        adjacent.add(seatNumber - 1);
      }

      // Check right seat
      if (seatNumber < rowStart + 3) {
        adjacent.add(seatNumber + 1);
      }

      // For seats in the middle of a row, check across the aisle
      int positionInRow = (seatNumber - 1) % 4;
      if (positionInRow == 1) {
        // Second seat, check third seat
        adjacent.add(seatNumber + 1);
      } else if (positionInRow == 2) {
        // Third seat, check second seat
        adjacent.add(seatNumber - 1);
      }
    }

    return adjacent;
  }

  bool hasOppositeGenderAdjacent(int seatNumber, String selectedGender) {
    List<int> adjacentSeats = getAdjacentSeats(seatNumber);

    for (int adjSeat in adjacentSeats) {
      // Check if adjacent seat is selected by user
      if (selectedSeats.containsKey(adjSeat)) {
        String adjSelectedGender = selectedSeats[adjSeat]!;
        if (adjSelectedGender != selectedGender) {
          return true;
        }
      }

      // Check if adjacent seat is already booked
      Map<String, dynamic>? adjacentSeatData = seatStatusData.firstWhere(
        (seat) => seat['seatNumber'] == adjSeat,
        orElse: () => {},
      );

      if (adjacentSeatData.isNotEmpty &&
          adjacentSeatData['status'] == 'Booked' &&
          adjacentSeatData['gender'] != null &&
          adjacentSeatData['gender'] != selectedGender) {
        return true;
      }
    }

    return false;
  }

  Future<bool> _showRelativeDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.family_restroom,
                    color: AppColors.primary,
                    size: 28.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      "Family Member?",
                      style: GoogleFonts.poppins(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A202C),
                      ),
                    ),
                  ),
                ],
              ),
              content: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Text(
                  "The adjacent seat is booked by a person of opposite gender. Are you traveling as family members or relatives?",
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  ),
                  child: Text(
                    "No",
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    "Yes, We're Family",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return; // Check if widget is still mounted
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

  Future<void> toggleSeat(int seatNumber) async {
    Map<String, dynamic>? seatData = seatStatusData.firstWhere(
      (seat) => seat['seatNumber'] == seatNumber,
      orElse: () => {},
    );

    if (seatData.isEmpty || seatData['status'] == 'Booked') {
      return;
    }

    String? nextGender;

    // Determine next state in cycle: unselected -> male -> female -> unselected
    if (!selectedSeats.containsKey(seatNumber)) {
      // Currently unselected, select as male
      nextGender = 'male';
    } else {
      String currentGender = selectedSeats[seatNumber]!;
      if (currentGender == 'male') {
        // Currently male, change to female
        nextGender = 'female';
      } else {
        // Currently female, unselect
        nextGender = null;
      }
    }

    // If unselecting, just remove from map
    if (nextGender == null) {
      setState(() {
        selectedSeats.remove(seatNumber);
      });
      return;
    }

    // Check for opposite gender adjacent seats
    if (hasOppositeGenderAdjacent(seatNumber, nextGender)) {
      bool isFamily = await _showRelativeDialog();
      if (!isFamily) {
        _showErrorSnackBar(
            'Cannot book this seat as $nextGender. Adjacent seat is occupied by opposite gender and you are not family members.');
        return;
      }
    }

    setState(() {
      selectedSeats[seatNumber] = nextGender!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Select Your Seats",
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
          ? Container(
              color: const Color.fromARGB(255, 174, 183, 193)
                  .withOpacity(0.3), // Background opacity
              child: Center(
                child: Image.asset(
                  'assets/images/loader1.gif',
                  width: 150.w,
                  height: 150.h,
                ),
              ),
            )
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      errorMessage!.contains("Avaliable")
                          ? Icon(
                              Icons.no_transfer_outlined,
                              size: 64.w,
                              color: Colors.red[400],
                            )
                          : Icon(
                              Icons.error_outline,
                              size: 64.w,
                              color: Colors.red[400],
                            ),
                      SizedBox(height: 16.h),
                      Text(
                        errorMessage!.contains("Avaliable")
                            ? "Error"
                            : "Sorry", //688dd652fb525bb85362dc57
                        style: GoogleFonts.poppins(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[600],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        errorMessage!,
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24.h),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            errorMessage = null;
                            isLoading = true;
                          });
                          _loadSeatData();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(
                              horizontal: 32.w, vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          "Retry",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(20.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Beautiful Bus Details Card
                          Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Departure",
                                        style: GoogleFonts.poppins(
                                          fontSize: 10.sp,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        busData?['departureTime'] ?? "N/A",
                                        style: GoogleFonts.poppins(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1A202C),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.all(8.w),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward_rounded,
                                    color: AppColors.primary,
                                    size: 20.w,
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "Arrival",
                                        style: GoogleFonts.poppins(
                                          fontSize: 10.sp,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        busData?['arrivalTime'] ?? "N/A",
                                        style: GoogleFonts.poppins(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1A202C),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 32.h),

                          // Elegant Seat Legend
                          Text(
                            "Choose Your Seats",
                            style: GoogleFonts.poppins(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1A202C),
                              letterSpacing: -0.5,
                            ),
                          ),

                          SizedBox(height: 8.h),

                          Text(
                            "Tap seats to cycle: Male → Female → Unselect",
                            style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          SizedBox(height: 20.h),

                          // Updated legend with gender colors
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _SeatLegendItem(
                                    color: const Color(0xFFF5F7FA),
                                    label: "Available",
                                    icon: Icons.event_seat_rounded,
                                    borderColor: Colors.grey[300]!,
                                  ),
                                  _SeatLegendItem(
                                    color: const Color(0xFFFF9800),
                                    label: "Male",
                                    icon: Icons.male_rounded,
                                    borderColor: const Color(0xFFFF9800),
                                  ),
                                  _SeatLegendItem(
                                    color:
                                        const Color.fromARGB(255, 71, 30, 233),
                                    label: "Female",
                                    icon: Icons.female_rounded,
                                    borderColor: const Color(0xFFE91E63),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          SizedBox(height: 32.h),

                          // Stunning Bus Layout
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(24.w),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white,
                                  const Color(0xFFFAFBFC),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 30,
                                  offset: const Offset(0, 12),
                                  spreadRadius: 0,
                                ),
                              ],
                              border: Border.all(
                                color: Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                // Seats Layout
                                Column(
                                  children: List.generate(12, (rowIndex) {
                                    if (rowIndex == 11) {
                                      // Last seat (seat 45)
                                      Map<String, dynamic> seat45 =
                                          seatStatusData.firstWhere(
                                        (seat) => seat['seatNumber'] == 45,
                                        orElse: () => {
                                          'seatNumber': 45,
                                          'status': 'Available'
                                        },
                                      );

                                      return Padding(
                                        padding: EdgeInsets.only(bottom: 12.h),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            _SeatWidget(
                                              seatData: seat45,
                                              selectedGender: selectedSeats[45],
                                              onTap: () => toggleSeat(45),
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    return Padding(
                                      padding: EdgeInsets.only(bottom: 12.h),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          // Left seats
                                          Row(
                                            children: [
                                              _buildSeatFromData(
                                                  rowIndex * 4 + 1),
                                              SizedBox(width: 16.w),
                                              _buildSeatFromData(
                                                  rowIndex * 4 + 2),
                                            ],
                                          ),

                                          // Aisle
                                          Container(
                                            width: 60.w,
                                            height: 2.h,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.grey[300]!,
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                          ),

                                          // Right seats
                                          Row(
                                            children: [
                                              _buildSeatFromData(
                                                  rowIndex * 4 + 3),
                                              SizedBox(width: 16.w),
                                              _buildSeatFromData(
                                                  rowIndex * 4 + 4),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 32.h),

                          // Selected Seats Summary
                          if (selectedSeats.isNotEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(24.w),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF4CAF50).withOpacity(0.1),
                                    const Color(0xFF4CAF50).withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color:
                                      const Color(0xFF4CAF50).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8.w),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4CAF50),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 16.w,
                                        ),
                                      ),
                                      SizedBox(width: 12.w),
                                      Text(
                                        "Selected Seats",
                                        style: GoogleFonts.poppins(
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF2E7D32),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12.h),
                                  // Display selected seats with gender info
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children:
                                        selectedSeats.entries.map((entry) {
                                      int seatNumber = entry.key;
                                      String gender = entry.value;
                                      return Padding(
                                        padding: EdgeInsets.only(bottom: 4.h),
                                        child: Row(
                                          children: [
                                            Icon(
                                              gender == 'male'
                                                  ? Icons.male
                                                  : Icons.female,
                                              color: gender == 'male'
                                                  ? const Color(0xFFFF9800)
                                                  : const Color.fromARGB(
                                                      255, 30, 64, 233),
                                              size: 16.w,
                                            ),
                                            SizedBox(width: 8.w),
                                            Text(
                                              "Seat $seatNumber (${gender.toUpperCase()})",
                                              style: GoogleFonts.poppins(
                                                fontSize: 10.sp,
                                                color: const Color(0xFF2E7D32),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  SizedBox(height: 8.h),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "${selectedSeats.length} seat(s)",
                                        style: GoogleFonts.poppins(
                                          fontSize: 12.sp,
                                          color: const Color(0xFF388E3C),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        "PKR ${(selectedSeats.length * baseFare).toStringAsFixed(0)}",
                                        style: GoogleFonts.poppins(
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF2E7D32),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24.h),
                          ],

                          // Continue Button
                          Container(
                            width: double.infinity,
                            height: 56.h,
                            decoration: BoxDecoration(
                              gradient: selectedSeats.isNotEmpty
                                  ? LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.primary,
                                        AppColors.primary.withOpacity(0.8),
                                      ],
                                    )
                                  : null,
                              color: selectedSeats.isEmpty
                                  ? Colors.grey[300]
                                  : null,
                              borderRadius: BorderRadius.circular(16.r),
                              boxShadow: selectedSeats.isNotEmpty
                                  ? [
                                      BoxShadow(
                                        color:
                                            AppColors.primary.withOpacity(0.4),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                        spreadRadius: 0,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: selectedSeats.isNotEmpty
                                    ? () {
                                        print(
                                            "::::::::::::::::::::: Here are following selected seats ::::::::::::::::::");
                                        print(selectedSeats);
                                        Navigator.pushNamed(
                                          context,
                                          '/bookingSummary',
                                          arguments: {
                                            'selectedSeats':
                                                selectedSeats, // Pass the Map<int, String> directly
                                            'slotId': slotId,
                                            'totalAmount':
                                                selectedSeats.length * baseFare,
                                            'busData': busData,
                                          },
                                        );
                                      }
                                    : null,
                                borderRadius: BorderRadius.circular(16.r),
                                child: Center(
                                  child: Text(
                                    selectedSeats.isEmpty
                                        ? "Select Seats to Continue"
                                        : "Continue to Booking",
                                    style: GoogleFonts.poppins(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w700,
                                      color: selectedSeats.isNotEmpty
                                          ? Colors.white
                                          : Colors.grey[600],
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildSeatFromData(int seatNumber) {
    Map<String, dynamic> seatData = seatStatusData.firstWhere(
      (seat) => seat['seatNumber'] == seatNumber,
      orElse: () => {'seatNumber': seatNumber, 'status': 'Available'},
    );

    return _SeatWidget(
      seatData: seatData,
      selectedGender: selectedSeats[seatNumber],
      onTap: () => toggleSeat(seatNumber),
    );
  }
}

class _SeatLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final IconData icon;
  final Color borderColor;

  const _SeatLegendItem({
    required this.color,
    required this.label,
    required this.icon,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: borderColor.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 18.w,
            color: color == const Color(0xFFF5F7FA)
                ? Colors.grey[700]
                : Colors.white,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}

class _SeatWidget extends StatefulWidget {
  final Map<String, dynamic> seatData;
  final String? selectedGender; // 'male', 'female', or null
  final VoidCallback onTap;

  const _SeatWidget({
    required this.seatData,
    required this.selectedGender,
    required this.onTap,
  });

  @override
  State<_SeatWidget> createState() => _SeatWidgetState();
}

class _SeatWidgetState extends State<_SeatWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get seatColor {
    String status = widget.seatData['status'] ?? 'Available';
    String? gender = widget.seatData['gender'];

    // Check if this seat is selected by user
    if (widget.selectedGender != null) {
      if (widget.selectedGender == 'female') {
        return const Color.fromARGB(255, 31, 48, 230); // Blue for females
      } else if (widget.selectedGender == 'male') {
        return const Color(0xFFFF9800); // Orange for males
      }
    }

    switch (status) {
      case 'Available':
        return const Color(0xFFF5F7FA);
      case 'Booked':
        if (gender == 'female') {
          return const Color.fromARGB(255, 31, 48, 230); // Blue for females
        } else if (gender == 'male') {
          return const Color(0xFFFF9800); // Orange for males
        } else {
          return const Color(0xFFFF5252); // Red for unknown gender
        }
      default:
        return const Color(0xFFF5F7FA);
    }
  }

  Color get borderColor {
    String status = widget.seatData['status'] ?? 'Available';
    String? gender = widget.seatData['gender'];

    // Check if this seat is selected by user
    if (widget.selectedGender != null) {
      if (widget.selectedGender == 'female') {
        return const Color.fromARGB(255, 30, 81, 233);
      } else if (widget.selectedGender == 'male') {
        return const Color(0xFFFF9800);
      }
    }

    switch (status) {
      case 'Available':
        return Colors.grey[300]!;
      case 'Booked':
        if (gender == 'female') {
          return const Color.fromARGB(255, 30, 81, 233);
        } else if (gender == 'male') {
          return const Color(0xFFFF9800);
        } else {
          return const Color(0xFFFF5252);
        }
      default:
        return Colors.grey[300]!;
    }
  }

  bool get isClickable {
    String status = widget.seatData['status'] ?? 'Available';
    return status == 'Available';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: isClickable ? (_) => _controller.forward() : null,
      onTapUp: isClickable ? (_) => _controller.reverse() : null,
      onTapCancel: isClickable ? () => _controller.reverse() : null,
      onTap: isClickable ? widget.onTap : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: seatColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: borderColor,
              width: widget.selectedGender != null ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: borderColor
                    .withOpacity(widget.selectedGender != null ? 0.4 : 0.2),
                blurRadius: widget.selectedGender != null ? 12 : 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: widget.seatData['status'] == 'Booked'
                ? Icon(
                    widget.seatData['gender'] == 'female'
                        ? Icons.female_rounded
                        : widget.seatData['gender'] == 'male'
                            ? Icons.male
                            : Icons.person_rounded,
                    size: 20.w,
                    color: Colors.white,
                  )
                : widget.selectedGender != null
                    ? Icon(
                        widget.selectedGender == 'female'
                            ? Icons.female_rounded
                            : Icons.male_rounded,
                        size: 20.w,
                        color: Colors.white,
                      )
                    : Icon(
                        Icons.event_seat_rounded,
                        size: 20.w,
                        color: Colors.grey[700],
                      ),
          ),
        ),
      ),
    );
  }
}
