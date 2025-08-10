import 'package:flutter/material.dart';
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
import 'package:intl/intl.dart';

class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the arguments passed from the previous screen
    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // Extract data from arguments
    final Map<int, String>? selectedSeats =
        args?['selectedSeats'] as Map<int, String>?;
    final String? slotId = args?['slotId'] as String?;
    final double? totalAmount = args?['totalAmount'] as double?;
    final Map<String, dynamic>? busData =
        args?['busData'] as Map<String, dynamic>?;

    // Generate ticket ID using slotId or timestamp
    final String ticketId =
        "TKT${slotId?.substring(0, 8).toUpperCase() ?? DateTime.now().millisecondsSinceEpoch.toString().substring(5)}";

    // Hard-coded passenger name (you'll replace this with session storage later)
    final String passenger = "Talha Shahid";

    // Format seats display
    final String seats = selectedSeats?.keys.join(', ') ?? '';

    // Format route
    final String route =
        "${busData?['pickupLocation'] ?? 'Unknown'} → ${busData?['dropoffLocation'] ?? 'Unknown'}";

    // Format date
    final String date = DateFormat('yyyy-MM-dd').format(busData!['travelDate']);

    // Get times
    final String departureTime = busData?['departureTime'] ?? 'Unknown';
    final String arrivalTime = busData?['arrivalTime'] ?? 'Unknown';

    // Format fare
    final String fare = "PKR ${totalAmount?.toStringAsFixed(0) ?? '0'}";

    // Service name as bus number
    final String busNumber = busData?['serviceName'] ?? 'Unknown Service';

    // Calculate duration (you might want to implement actual calculation)
    final String duration =
        "Varies"; // You can calculate this based on departure and arrival times

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "Thank You",
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
          onPressed: () {
            Navigator.popUntil(context, ModalRoute.withName('/home'));
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
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              // Success Message
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 20.h),
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
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 60.sp,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      "Booking Confirmed!",
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      "Your ticket has been booked successfully",
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.h),

              // Ticket Card
              Container(
                width: double.infinity,
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
                    // Ticket ID Section
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        children: [
                          SizedBox(height: 8.h),
                          Text(
                            ticketId,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Divider with dashed line
                    Container(
                      height: 1,
                      child: CustomPaint(
                        size: Size(double.infinity, 1),
                        painter: DashedLinePainter(),
                      ),
                    ),

                    // Ticket Details
                    Padding(
                      padding: EdgeInsets.all(20.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Route and Time
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      busData?['pickupLocation'] ?? 'Unknown',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      departureTime,
                                      style: TextStyle(
                                        fontSize: 14.sp,
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
                                    duration,
                                    style: TextStyle(
                                      fontSize: 12.sp,
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
                                      busData?['dropoffLocation'] ?? 'Unknown',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      arrivalTime,
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

                          SizedBox(height: 24.h),

                          // Service and Date Details
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildDetailItem("Service", busNumber),
                              ),
                              Expanded(
                                child: _buildDetailItem("Date", date),
                              ),
                            ],
                          ),

                          SizedBox(height: 16.h),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildDetailItem("Passenger", passenger),
                              ),
                              Expanded(
                                child: _buildDetailItem(
                                    "Seat${selectedSeats != null && selectedSeats.length > 1 ? 's' : ''}",
                                    seats),
                              ),
                            ],
                          ),

                          SizedBox(height: 16.h),

                          _buildDetailItem("Total Fare", fare),

                          // Show seat gender assignments if available
                          if (selectedSeats != null &&
                              selectedSeats.isNotEmpty) ...[
                            SizedBox(height: 16.h),
                            Text(
                              "Seat Assignments:",
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            ...selectedSeats.entries
                                .map((entry) => Padding(
                                      padding: EdgeInsets.only(bottom: 4.h),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Seat ${entry.key}:",
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 8.w, vertical: 2.h),
                                            decoration: BoxDecoration(
                                              color: entry.value == 'male'
                                                  ? Colors.blue.withOpacity(0.1)
                                                  : Colors.pink
                                                      .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4.r),
                                              border: Border.all(
                                                color: entry.value == 'male'
                                                    ? Colors.blue
                                                        .withOpacity(0.3)
                                                    : Colors.pink
                                                        .withOpacity(0.3),
                                              ),
                                            ),
                                            child: Text(
                                              entry.value.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 10.sp,
                                                color: entry.value == 'male'
                                                    ? Colors.blue[700]
                                                    : Colors.pink[700],
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.h),

              // Payment Status Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(
                  "Booking Initiated — Please Pay To Confirm.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              SizedBox(height: 30.h),

              // Action Buttons
              Row(
                children: [
                  // Expanded(
                  //   child: ElevatedButton.icon(
                  //     onPressed: () => _generateAndDownloadTicket(
                  //       context,
                  //       ticketId,
                  //       passenger,
                  //       route,
                  //       date,
                  //       departureTime,
                  //       seats,
                  //       fare,
                  //       busNumber,
                  //       arrivalTime,
                  //     ),
                  //     icon: Icon(
                  //       Icons.download,
                  //       color: Colors.white,
                  //       size: 20.sp,
                  //     ),
                  //     label: Text(
                  //       "Download",
                  //       style: TextStyle(
                  //         color: Colors.white,
                  //         fontSize: 14.sp,
                  //         fontWeight: FontWeight.w600,
                  //       ),
                  //     ),
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: Colors.orange,
                  //       padding: EdgeInsets.symmetric(vertical: 14.h),
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(12.r),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.popUntil(
                            context, ModalRoute.withName('/home'));
                      },
                      icon: Icon(
                        Icons.home,
                        color: Colors.orange,
                        size: 20.sp,
                      ),
                      label: Text(
                        "Home",
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          side: BorderSide(color: Colors.orange, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20.h),
            ],
          ),
        ),
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
            fontSize: 12.sp,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Future<void> _generateAndDownloadTicket(
    BuildContext context,
    String ticketId,
    String passenger,
    String route,
    String date,
    String departureTime,
    String seats,
    String fare,
    String busNumber,
    String arrivalTime,
  ) async {
    try {
      // Request appropriate permissions based on Android version
      bool hasPermission = await _requestStoragePermission();

      if (!hasPermission) {
        _showErrorDialog(context,
            "Storage permission is required to save the ticket. Please grant permission in app settings.");
        return;
      }

      // Generate PDF
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (context) => pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Roadway Ticket",
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Text("Ticket ID: $ticketId"),
                pw.Text("Passenger: $passenger"),
                pw.Text("Route: $route"),
                pw.Text("Date: $date"),
                pw.Text("Departure: $departureTime"),
                pw.Text("Arrival: $arrivalTime"),
                pw.Text("Seats: $seats"),
                pw.Text("Fare: $fare"),
                pw.Text("Service: $busNumber"),
                pw.SizedBox(height: 20),
                pw.Text("Scan this QR at the station:",
                    style: pw.TextStyle(fontSize: 14)),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.BarcodeWidget(
                    data: ticketId,
                    barcode: pw.Barcode.qrCode(),
                    width: 120,
                    height: 120,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text("Terms & Conditions:",
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Text(
                    "• Please arrive at the station 30 minutes before departure",
                    style: pw.TextStyle(fontSize: 10)),
                pw.Text("• This ticket is non-refundable and non-transferable",
                    style: pw.TextStyle(fontSize: 10)),
                pw.Text("• Keep this ticket safe and present it during travel",
                    style: pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
        ),
      );

      // Get the appropriate directory and save file
      String? filePath = await _saveFileToDevice(await pdf.save(), passenger);

      if (filePath == null) {
        _showErrorDialog(
            context, "Failed to save the ticket. Please try again.");
        return;
      }

      // Show success message and open file
      _showSuccessDialog(context,
          "Ticket downloaded successfully!\nSaved to: ${filePath.split('/').last}");

      // Open the PDF file
      await OpenFile.open(filePath);
    } catch (e) {
      _showErrorDialog(context, "Failed to download ticket: ${e.toString()}");
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isIOS) {
      return true; // iOS doesn't need explicit storage permission for app documents
    }

    // For Android
    if (Platform.isAndroid) {
      var androidInfo = await DeviceInfoPlugin().androidInfo;

      if (androidInfo.version.sdkInt >= 30) {
        // Android 11+ (API 30+) - Request MANAGE_EXTERNAL_STORAGE
        var status = await Permission.manageExternalStorage.status;
        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
          return status.isGranted;
        }
        return true;
      } else if (androidInfo.version.sdkInt >= 23) {
        // Android 6+ to Android 10 - Request WRITE_EXTERNAL_STORAGE
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          return status.isGranted;
        }
        return true;
      }
    }

    return true; // For older Android versions
  }

  Future<String?> _saveFileToDevice(
      List<int> pdfBytes, String passenger) async {
    try {
      Directory? directory;

      if (Platform.isAndroid) {
        // Try to get external storage directory first
        directory = await getExternalStorageDirectory();

        // If external storage is not available, use downloads directory
        if (directory == null) {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            // Fallback to internal storage
            directory = await getApplicationDocumentsDirectory();
          }
        }
      } else {
        // iOS
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        return null;
      }

      // Create RoadwayBookings directory
      final roadwayDir = Directory('${directory.path}/RoadwayBookings');
      if (!await roadwayDir.exists()) {
        await roadwayDir.create(recursive: true);
      }

      // Generate filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          'Ticket_${passenger.replaceAll(' ', '_')}_$timestamp.pdf';
      final filePath = '${roadwayDir.path}/$fileName';

      // Save PDF to file
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      return filePath;
    } catch (e) {
      print('Error saving file: $e');
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
              Text("Success", style: TextStyle(fontSize: 18.sp)),
            ],
          ),
          content: Text(message, style: TextStyle(fontSize: 14.sp)),
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
              Text("Error", style: TextStyle(fontSize: 18.sp)),
            ],
          ),
          content: Text(message, style: TextStyle(fontSize: 14.sp)),
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
}

// Custom painter for dashed line
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    double dashWidth = 5;
    double dashSpace = 3;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
