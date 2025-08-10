import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../Services/ApiCalls.dart'; // Import your API service

class BookingSummaryScreen extends StatefulWidget {
  const BookingSummaryScreen({super.key});

  @override
  State<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  bool _isLoading = false;

  String _formatSeatNumbers(Map<int, String> selectedSeats) {
    List<int> seatNumbers = selectedSeats.keys.toList();
    seatNumbers.sort();
    return seatNumbers.join(', ');
  }

  String _formatSeatGenders(Map<int, String> selectedSeats) {
    Map<String, int> genderCount = {};
    selectedSeats.values.forEach((gender) {
      genderCount[gender] = (genderCount[gender] ?? 0) + 1;
    });

    List<String> genderInfo = [];
    if (genderCount['male'] != null) {
      genderInfo.add('${genderCount['male']} Male');
    }
    if (genderCount['female'] != null) {
      genderInfo.add('${genderCount['female']} Female');
    }

    return genderInfo.join(', ');
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
  void _showSuccessDialog() {
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
                "Booking Created Successfully!",
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
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Handle booking confirmation
  Future<void> _handleBookingConfirmation({
    required Map<int, String> selectedSeats,
    required String slotId,
    required double totalAmount,
    required Map<String, dynamic> busData,
  }) async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    // Set loading state
    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare booking data
      final bookingData = {
        "tripId": busData['tripId']?.toString() ?? "",
        "email":
            "talhashahidarain@gmail.com", // You might want to get this from user session
        "travelDate": busData[
            "travelDate"], // You might want to get this from busData or pass it as parameter
        "seatNumberDetails":
            selectedSeats.map((key, value) => MapEntry(key.toString(), value)),
      };

      print('🚀 Sending booking request: $bookingData');

      // Make API call
      final response = await ApiCalls.createBooking(bookingData);

      // Handle response
      if (response.success && response.data != null) {
        // Check response code from API
        if (response.data!.responseCode == "00") {
          print(
              '🎉 Booking successful! Message: ${response.data!.responseMessage}');

          // Show success dialog
          _showSuccessDialog();

          // Navigate to success screen after a short delay
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.pushNamed(
                context,
                '/success',
                arguments: {
                  'selectedSeats': selectedSeats,
                  'slotId': slotId,
                  'totalAmount': totalAmount,
                  'busData': busData,
                },
              );
            }
          });
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
      print('❌ Unexpected error during booking: $e');
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
    // Get arguments from navigation
    final Map<String, dynamic> args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;

    final Map<int, String> selectedSeats =
        args['selectedSeats'] as Map<int, String>;
    final String slotId = args['slotId'] as String;
    final double totalAmount = args['totalAmount'] as double;
    final Map<String, dynamic> busData =
        args['busData'] as Map<String, dynamic>;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Booking Summary",
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF6C63FF),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header gradient section with bus info
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF6C63FF),
                    const Color(0xFF9C88FF),
                    const Color(0xFFB794FF),
                  ],
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: 20.h),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    margin: EdgeInsets.symmetric(horizontal: 20.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Icon(
                                Icons.directions_bus,
                                color: AppColors.primary,
                                size: 24.sp,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    busData['serviceName'] ?? 'Unknown Service',
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    "Happy Journey",
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        // Route and time info
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    busData['pickupLocation'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  Text(
                                    busData['departureTime'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward,
                              color: AppColors.primary,
                              size: 20.sp,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    busData['dropoffLocation'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  Text(
                                    busData['arrivalTime'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.grey[600],
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
                  SizedBox(height: 30.h),
                ],
              ),
            ),

            // Booking details section
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                children: [
                  // Trip details card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Trip Details",
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 20.h),

                        // Trip ID
                        _buildDetailRow(
                          Icons.confirmation_number,
                          "Trip ID",
                          busData['tripId']?.toString().substring(0, 8) ??
                              'Unknown',
                          Colors.green,
                        ),
                        SizedBox(height: 16.h),

                        // Selected Seats
                        _buildDetailRow(
                          Icons.airline_seat_recline_normal,
                          "Selected Seats",
                          _formatSeatNumbers(selectedSeats),
                          Colors.orange,
                        ),
                        SizedBox(height: 16.h),

                        // Passenger Info
                        _buildDetailRow(
                          Icons.people,
                          "Passengers",
                          _formatSeatGenders(selectedSeats),
                          Colors.purple,
                        ),
                        SizedBox(height: 16.h),

                        // Route
                        _buildDetailRow(
                          Icons.route,
                          "Route",
                          "${busData['pickupLocation']} → ${busData['dropoffLocation']}",
                          Colors.blue,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Fare breakdown card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Fare Breakdown",
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Base Fare (${selectedSeats.length} seats)",
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              "PKR ${totalAmount.toStringAsFixed(0)}",
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Service Fee",
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              "PKR ${(selectedSeats.length * 50).toStringAsFixed(0)}",
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Divider(color: Colors.grey[300]),
                        SizedBox(height: 12.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Total Amount",
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            Text(
                              "PKR ${(totalAmount + (selectedSeats.length * 50)).toStringAsFixed(0)}",
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30.h),

                  // Enhanced Confirm booking button with loading state
                  _buildGradientButton(
                    selectedSeats: selectedSeats,
                    slotId: slotId,
                    totalAmount: totalAmount,
                    busData: busData,
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required Map<int, String> selectedSeats,
    required String slotId,
    required double totalAmount,
    required Map<String, dynamic> busData,
  }) {
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
          onTap: _isLoading
              ? null
              : () => _handleBookingConfirmation(
                    selectedSeats: selectedSeats,
                    slotId: slotId,
                    totalAmount: totalAmount + (selectedSeats.length * 50),
                    busData: busData,
                  ),
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
                        "Processing...",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        "Confirm Booking - PKR ${(totalAmount + (selectedSeats.length * 50)).toStringAsFixed(0)}",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 16.sp,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
