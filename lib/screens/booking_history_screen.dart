import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:math';

import 'package:roadway/Services/ApiCalls.dart';
import 'package:roadway/routes/app_routes.dart';
import 'package:roadway/screens/home_screen.dart';

class BookingsHistoryScreen extends StatefulWidget {
  const BookingsHistoryScreen({super.key});

  @override
  State<BookingsHistoryScreen> createState() => _BookingsHistoryScreenState();
}

class _BookingsHistoryScreenState extends State<BookingsHistoryScreen> {
  List<ApiBookingModel> bookings = [];
  bool isLoading = true;
  String? errorMessage;
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _fetchBookingHistory();
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

  Future<void> _fetchBookingHistory() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final result =
          await ApiCalls.fetchBookingHistory('talhashahidarain@gmail.com');

      if (result['success']) {
        final data = result['data'];

        if (data['responseCode'] == '00') {
          final List<dynamic> bookingsData = data['bookings'];
          setState(() {
            bookings = bookingsData
                .map((booking) => ApiBookingModel.fromJson(booking))
                .toList();
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage =
                data['responseMessage'] ?? 'Failed to fetch bookings';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = result['error'] ?? 'Failed to fetch bookings';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "My Bookings",
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
          onPressed: () => {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              ),
            )
          },
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
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white, size: 20.sp),
            onPressed: _fetchBookingHistory,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(
        child: Image.asset(
          'assets/images/loader1.gif',
          width: 100.w,
          height: 100.h,
        ),
      );
    }

    if (errorMessage != null) {
      return _buildErrorState();
    }

    if (bookings.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        return _buildBookingCard(bookings[index]);
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80.sp,
            color: Colors.red[400],
          ),
          SizedBox(height: 16.h),
          Text(
            "Error loading bookings",
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            errorMessage ?? "Something went wrong",
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20.h),
          ElevatedButton(
            onPressed: _fetchBookingHistory,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text(
              "Retry",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            "No bookings found",
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "Your booking history will appear here",
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(ApiBookingModel booking) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with status
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: _getStatusColor(booking.status).withOpacity(0.3),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "TKT${(booking.primaryBookingId).substring(0, 8).toUpperCase() ?? 'N/A'}",
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      "Booked on ${_formatDate(booking.createdAt)}",
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    booking.status.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                // Route and Time
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.pickupLocation,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            booking.departureTime,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Icon(
                          Icons.directions_bus,
                          color: Colors.orange,
                          size: 24.sp,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          booking.busNumber,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            booking.dropoffLocation,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            booking.arrivalTime,
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

                SizedBox(height: 16.h),

                // Booking details
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                          "Date", _formatDate(booking.bookingDate)),
                    ),
                    Expanded(
                      child: _buildDetailItem("Seats", booking.seatsDisplay),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem("Bus No.", booking.busNumber),
                    ),
                    Expanded(
                      child: _buildDetailItem("Fare", "PKR ${booking.fare}"),
                    ),
                  ],
                ),

                SizedBox(height: 20.h),

                // Action buttons
                if (booking.status == BookingStatus.Confirmed) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showQRDialog(booking),
                          icon: Icon(
                            Icons.qr_code,
                            color: Colors.orange,
                            size: 18.sp,
                          ),
                          label: Text(
                            "Show QR",
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 12.sp,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.orange),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _generateAndDownloadTicket(context, booking),
                          icon: Icon(
                            Icons.download,
                            color: Colors.white,
                            size: 18.sp,
                          ),
                          label: Text(
                            "Download",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (booking.status == BookingStatus.Pending) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      "This booking is not confirmed yet",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.Confirmed:
        return Colors.green;
      case BookingStatus.Pending:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  String _formatDateForTicket(DateTime date) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return "${date.day} ${months[date.month]} ${date.year}";
  }

  void _showQRDialog(ApiBookingModel booking) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Container(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "QR Code",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  "TKT${(booking.primaryBookingId).substring(0, 8).toUpperCase() ?? 'N/A'}",
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 20.h),
                QrImageView(
                  data:
                      "TKT${(booking.primaryBookingId).substring(0, 8).toUpperCase() ?? 'N/A'}",
                  version: QrVersions.auto,
                  size: 200.sp,
                  backgroundColor: Colors.white,
                ),
                SizedBox(height: 20.h),
                Text(
                  "Show this QR code at the station",
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.h),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Text(
                    "Close",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _generateAndDownloadTicket(
      BuildContext context, ApiBookingModel booking) async {
    try {
      bool hasPermission = await _requestStoragePermission();

      if (!hasPermission) {
        _showErrorDialog(
            context, "Storage permission is required to save the ticket.");
        return;
      }

      // Load logo
      pw.MemoryImage? logoImage;
      try {
        final logoData = await rootBundle.load('assets/images/logo.png');
        logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
      } catch (e) {
        print('Error loading logo: $e');
      }

      final pdf = pw.Document();

      // FIRST PAGE - Main ticket content
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20), // Add proper margins
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildTicketHeader(logoImage, booking),
              pw.SizedBox(height: 20),

              // Customer Details Section
              _buildCustomerDetails(booking),
              pw.SizedBox(height: 20),

              // Journey Details Section
              _buildJourneyDetails(booking),
              pw.SizedBox(height: 20),

              // QR Code Section
              _buildQRSection(booking),

              pw.Spacer(), // Push footer to bottom

              // Page footer
              pw.Container(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  "Page 1 of 2 - Please see next page for Terms & Conditions",
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ),
            ],
          ),
        ),
      );

      // SECOND PAGE - Terms and Conditions
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header for second page
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.orange50,
                  border: pw.Border.all(color: PdfColors.orange200),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      "ROADWAY - Terms & Conditions",
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.orange800,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Terms and Conditions - Full content
              pw.Expanded(
                child: _buildTermsAndConditions(),
              ),

              // Footer
              pw.Container(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  "Page 2 of 2",
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ),
            ],
          ),
        ),
      );

      String? filePath = await _saveFileToDevice(await pdf.save(), booking);

      if (filePath == null) {
        _showErrorDialog(context, "Failed to save the ticket.");
        return;
      }

      _showSuccessDialog(context, "Ticket downloaded successfully!");
      await OpenFile.open(filePath);
    } catch (e) {
      _showErrorDialog(context, "Failed to download ticket: ${e.toString()}");
    }
  }

  pw.Widget _buildTicketHeader(
      pw.MemoryImage? logoImage, ApiBookingModel booking) {
    return pw.Container(
      color: PdfColors.orange50,
      padding: const pw.EdgeInsets.all(15),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              if (logoImage != null) ...[
                pw.Image(logoImage, width: 300, height: 100),
                pw.SizedBox(width: 10),
              ],
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "ROADWAY",
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.orange800,
                    ),
                  ),
                  pw.Text(
                    "eTICKET",
                    style: pw.TextStyle(
                      fontSize: 14,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                "Faisal Movers",
                style:
                    pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                "+923030720728",
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCustomerDetails(ApiBookingModel booking) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "Customer Details",
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("Journey",
                              style: const pw.TextStyle(
                                  fontSize: 10, color: PdfColors.grey700)),
                          pw.Text(
                              "${booking.pickupLocation} -> ${booking.dropoffLocation}",
                              style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 8),
                          pw.Text("Booked On",
                              style: const pw.TextStyle(
                                  fontSize: 10, color: PdfColors.grey700)),
                          pw.Text(_formatDateForTicket(booking.createdAt),
                              style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("Journey Date",
                              style: const pw.TextStyle(
                                  fontSize: 10, color: PdfColors.grey700)),
                          pw.Text(_formatDateForTicket(booking.bookingDate),
                              style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 8),
                          pw.Text("Departure Time",
                              style: const pw.TextStyle(
                                  fontSize: 10, color: PdfColors.grey700)),
                          pw.Text(booking.departureTime,
                              style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.Container(
            width: 1,
            height: 80,
            color: PdfColors.grey300,
          ),
          pw.SizedBox(width: 15),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "Operator Details",
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                pw.Text("Contact No.",
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey700)),
                pw.Text("+923030720728",
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                pw.Text("Email",
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey700)),
                pw.Text("talhashahidarain@gmail.com",
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildJourneyDetails(ApiBookingModel booking) {
    return pw.Container(
      color: PdfColors.grey100,
      padding: const pw.EdgeInsets.all(15),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Talha Shahid",
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("A/C Sleeper (2+2)",
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey700)),
              pw.Text("Seat Number",
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey700)),
              pw.Text("Departure time",
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey700)),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Faisal Movers",
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text(booking.seatsDisplay,
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text(booking.departureTime,
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(booking.busNumber,
                  style: const pw.TextStyle(fontSize: 12)),
              pw.Text(
                  _calculateDuration(
                          booking.departureTime, booking.arrivalTime) ??
                      '8h 00m',
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey700)),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Divider(thickness: 1, color: PdfColors.grey400),
          pw.SizedBox(height: 15),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("Booking Date",
                      style: const pw.TextStyle(
                          fontSize: 10, color: PdfColors.grey700)),
                  pw.Text(
                      _formatDateForTicket(booking
                          .bookingDate), //{_formatDate(booking.createdAt)}
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("From",
                      style: const pw.TextStyle(
                          fontSize: 10, color: PdfColors.grey700)),
                  pw.Text(booking.pickupLocation,
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("To",
                      style: const pw.TextStyle(
                          fontSize: 10, color: PdfColors.grey700)),
                  pw.Text(booking.dropoffLocation,
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("Booking ID",
                      style: const pw.TextStyle(
                          fontSize: 10, color: PdfColors.grey700)),
                  pw.Text(
                      "TKT${(booking.primaryBookingId).substring(0, 8).toUpperCase()}",
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text("Base Fare Rs.${booking.fare}/-",
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.Divider(thickness: 1, color: PdfColors.grey400),
                  pw.Text("Net Amount Rs.${booking.fare}/-",
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildQRSection(ApiBookingModel booking) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "Important Instructions:",
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  "Please carry a printed copy or show this e-ticket on your mobile device",
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey700),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 20),
          pw.Column(
            children: [
              pw.BarcodeWidget(
                data:
                    "TKT${(booking.primaryBookingId).substring(0, 8).toUpperCase()}",
                barcode: pw.Barcode.qrCode(),
                width: 80,
                height: 80,
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                "Scan at Station",
                style:
                    const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTermsAndConditions() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          "Terms and Conditions",
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 15),

        // Terms in a more compact layout
        pw.Column(
          children: [
            _buildTermItem("1.",
                "Roadway is ONLY a bus ticket agent and does not provide bus services on its own. The services are provided by the bus operator."),
            _buildTermItem("2.",
                "Our responsibility includes reservation for seat that will be occupied by passenger in bus during his/her journey."),
            _buildTermItem("3.",
                "Our responsibility includes information and maintenance on account of online support and information in case of cancellations."),
            _buildTermItem("4.",
                "The bus operator and roadway reserve the right to refuse service to any person without assigning any reasons. Intoxicated persons may not be allowed to travel."),
            _buildTermItem("5.",
                "The bus operator not departing/reaching on time is their own discretion and we are not liable for the same."),
            _buildTermItem("6.",
                "In case of breakdown or any unforeseen problems during journey, alternate transport will be provided by the operator."),
            _buildTermItem("7.",
                "The bus operator cancelling the trip due to unavoidable circumstances is not liable for the same."),
            _buildTermItem("8.",
                "Bus operators may ask for identification proof i.e. driving license, election card, pan card, passport, etc."),
            _buildTermItem("9.",
                "Passenger shall be deemed as confirmed only at the time of boarding."),
            _buildTermItem("10.",
                "Cancellation charges would be as per the cancellation policy of the operator or 15% of gross amount whichever is higher."),
            _buildTermItem("11.",
                "Departure and arrival times mentioned are as per the operator's time table and passengers should be present at pickup points 15 minutes prior."),
            _buildTermItem("12.",
                "Passengers should recheck route, time and terminals. Late arrivals will be treated as no-show and cancellation policy will apply."),
            _buildTermItem("13.",
                "Carrying dangerous or illegal items is prohibited and anyone found carrying such items will be handed over to authorities."),
            _buildTermItem("14.",
                "For any arrangement related query please call Roadway support numbers provided."),
            _buildTermItem("15.",
                "This e-ticket does not warrant confirmed travel and is subject to availability of seats at boarding."),
            _buildTermItem("16.",
                "Passengers in excess of permissible seating capacity shall not be entertained."),
            _buildTermItem("17.",
                "Road permit does not give confirmation and fare related issues are dependent on bus operators."),
          ],
        ),

        pw.SizedBox(height: 20),

        // Additional info section
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Have a safe journey!",
                          style: pw.TextStyle(
                              fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 5),
                      pw.Text("For Assistance Call: +923030720728",
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey700)),
                      pw.Text("Available: Mon-Sun 11:00 AM to 6:00 PM",
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("Cancellation Policy",
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text("Before 6 hours: 90% refund",
                          style: const pw.TextStyle(fontSize: 9)),
                      pw.Text("After 6 hours: No refund",
                          style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTermItem(String number, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6), // Increased spacing
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 20, // Increased width for number
            child: pw.Text(
              number,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              text,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isIOS) return true;

    if (Platform.isAndroid) {
      var androidInfo = await DeviceInfoPlugin().androidInfo;

      if (androidInfo.version.sdkInt >= 30) {
        var status = await Permission.manageExternalStorage.status;
        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
          return status.isGranted;
        }
        return true;
      } else if (androidInfo.version.sdkInt >= 23) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          return status.isGranted;
        }
        return true;
      }
    }

    return true;
  }

  Future<String?> _saveFileToDevice(
      List<int> pdfBytes, ApiBookingModel booking) async {
    try {
      Directory? directory;

      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
        if (directory == null) {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = await getApplicationDocumentsDirectory();
          }
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) return null;

      final roadwayDir = Directory('${directory.path}/RoadwayBookings');
      if (!await roadwayDir.exists()) {
        await roadwayDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          'Ticket_${"TKT${(booking.primaryBookingId).substring(0, 8).toUpperCase() ?? 'N/A'}"}_$timestamp.pdf';
      final filePath = '${roadwayDir.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      return filePath;
    } catch (e) {
      return null;
    }
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24.sp),
              SizedBox(width: 8.w),
              Text("Success"),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK", style: TextStyle(color: Colors.orange)),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 24.sp),
              SizedBox(width: 8.w),
              Text("Error"),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK", style: TextStyle(color: Colors.orange)),
            ),
          ],
        );
      },
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
        if (index == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const HomeScreen(), // Replace with your HomeScreen
            ),
          );
        } else if (index == 2) {
          Navigator.pushNamed(context, AppRoutes.announcements);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const BookingsHistoryScreen(),
            ),
          );
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

// Updated Data Model for API Response
class ApiBookingModel {
  final DateTime createdAt;
  final String tripId;
  final DateTime bookingDate;
  final String busNumber;
  final int fare;
  final String departureTime;
  final String arrivalTime;
  final String pickupLocation;
  final String dropoffLocation;
  final List<int> seatNumbers;
  final List<String> bookingIds;
  final BookingStatus status;

  ApiBookingModel({
    required this.createdAt,
    required this.tripId,
    required this.bookingDate,
    required this.busNumber,
    required this.fare,
    required this.departureTime,
    required this.arrivalTime,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.seatNumbers,
    required this.bookingIds,
    required this.status,
  });

  factory ApiBookingModel.fromJson(Map<String, dynamic> json) {
    return ApiBookingModel(
      createdAt: DateTime.parse(json['createdAt']),
      tripId: json['tripId'],
      bookingDate: DateTime.parse(json['bookingDate']),
      busNumber: json['busNumber'],
      fare: json['fare'],
      departureTime: json['departureTime'],
      arrivalTime: json['arrivalTime'],
      pickupLocation: json['pickupLocation'],
      dropoffLocation: json['dropoffLocation'],
      seatNumbers: List<int>.from(json['seatNumbers']),
      bookingIds: List<String>.from(json['bookingIds']),
      status: json['bookingStatus'] == 'Pending'
          ? BookingStatus.Pending
          : BookingStatus.Confirmed,
    );
  }

  String get primaryBookingId => bookingIds.first;

  String get seatsDisplay {
    if (seatNumbers.length == 1) {
      return seatNumbers.first.toString();
    }
    return seatNumbers.join(', ');
  }
}

enum BookingStatus {
  Confirmed,
  Pending,
}
