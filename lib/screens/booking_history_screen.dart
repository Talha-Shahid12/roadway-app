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

class BookingsHistoryScreen extends StatefulWidget {
  const BookingsHistoryScreen({super.key});

  @override
  State<BookingsHistoryScreen> createState() => _BookingsHistoryScreenState();
}

class _BookingsHistoryScreenState extends State<BookingsHistoryScreen> {
  // Sample booking data - In real app, this would come from API/Database
  final List<BookingModel> bookings = [
    BookingModel(
      ticketId: "TKT123456789",
      passenger: "Talha Shahid",
      route: "Lahore → Islamabad",
      date: "2025-08-05",
      time: "07:00 AM",
      arrivalTime: "11:30 AM",
      seats: "A1, A2",
      fare: "PKR 3000",
      busNumber: "LHR-ISB-001",
      duration: "4h 30min",
      status: BookingStatus.confirmed,
      bookingDate: DateTime(2025, 8, 1),
    ),
    BookingModel(
      ticketId: "TKT987654321",
      passenger: "Talha Shahid",
      route: "Islamabad → Karachi",
      date: "2025-08-10",
      time: "09:00 AM",
      arrivalTime: "10:00 PM",
      seats: "B5",
      fare: "PKR 4500",
      busNumber: "ISB-KHI-205",
      duration: "13h 00min",
      status: BookingStatus.confirmed,
      bookingDate: DateTime(2025, 8, 3),
    ),
    BookingModel(
      ticketId: "TKT456789123",
      passenger: "Talha Shahid",
      route: "Karachi → Lahore",
      date: "2025-07-25",
      time: "08:30 AM",
      arrivalTime: "09:30 PM",
      seats: "C3, C4",
      fare: "PKR 4200",
      busNumber: "KHI-LHR-102",
      duration: "13h 00min",
      status: BookingStatus.confirmed,
      bookingDate: DateTime(2025, 7, 20),
    ),
    BookingModel(
      ticketId: "TKT789123456",
      passenger: "Talha Shahid",
      route: "Lahore → Multan",
      date: "2025-06-15",
      time: "06:00 AM",
      arrivalTime: "11:00 AM",
      seats: "A7",
      fare: "PKR 1800",
      busNumber: "LHR-MLT-301",
      duration: "5h 00min",
      status: BookingStatus.pending,
      bookingDate: DateTime(2025, 6, 10),
    ),
  ];

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
      body: bookings.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                return _buildBookingCard(bookings[index]);
              },
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

  Widget _buildBookingCard(BookingModel booking) {
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
                      booking.ticketId,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      "Booked on ${_formatDate(booking.bookingDate)}",
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
                            booking.route.split(' → ')[0],
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            booking.time,
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
                          booking.duration,
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
                            booking.route.split(' → ')[1],
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
                      child: _buildDetailItem("Date", booking.date),
                    ),
                    Expanded(
                      child: _buildDetailItem("Seats", booking.seats),
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
                      child: _buildDetailItem("Fare", booking.fare),
                    ),
                  ],
                ),

                SizedBox(height: 20.h),

                // Action buttons
                if (booking.status == BookingStatus.confirmed) ...[
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
                ] else if (booking.status == BookingStatus.confirmed) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showQRDialog(booking),
                          icon: Icon(
                            Icons.qr_code,
                            color: Colors.grey,
                            size: 18.sp,
                          ),
                          label: Text(
                            "View QR",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12.sp,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey),
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
                            backgroundColor: Colors.grey[600],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (booking.status == BookingStatus.pending) ...[
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
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.pending:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  void _showQRDialog(BookingModel booking) {
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
                  booking.ticketId,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 20.h),
                QrImageView(
                  data: booking.ticketId,
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

  // Download functionality (same as BookingSuccessScreen but adapted for BookingModel)
  Future<void> _generateAndDownloadTicket(
      BuildContext context, BookingModel booking) async {
    try {
      bool hasPermission = await _requestStoragePermission();

      if (!hasPermission) {
        _showErrorDialog(
            context, "Storage permission is required to save the ticket.");
        return;
      }

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
                pw.Text("Ticket ID: ${booking.ticketId}"),
                pw.Text("Passenger: ${booking.passenger}"),
                pw.Text("Route: ${booking.route}"),
                pw.Text("Date: ${booking.date}"),
                pw.Text("Time: ${booking.time}"),
                pw.Text("Seats: ${booking.seats}"),
                pw.Text("Fare: ${booking.fare}"),
                pw.Text("Bus Number: ${booking.busNumber}"),
                pw.Text("Status: ${booking.status.name.toUpperCase()}"),
                pw.SizedBox(height: 20),
                pw.Text("Scan this QR at the station:",
                    style: pw.TextStyle(fontSize: 14)),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.BarcodeWidget(
                    data: booking.ticketId,
                    barcode: pw.Barcode.qrCode(),
                    width: 120,
                    height: 120,
                  ),
                ),
              ],
            ),
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
      List<int> pdfBytes, BookingModel booking) async {
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
      final fileName = 'Ticket_${booking.ticketId}_$timestamp.pdf';
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
}

// Data Models
class BookingModel {
  final String ticketId;
  final String passenger;
  final String route;
  final String date;
  final String time;
  final String arrivalTime;
  final String seats;
  final String fare;
  final String busNumber;
  final String duration;
  final BookingStatus status;
  final DateTime bookingDate;

  BookingModel({
    required this.ticketId,
    required this.passenger,
    required this.route,
    required this.date,
    required this.time,
    required this.arrivalTime,
    required this.seats,
    required this.fare,
    required this.busNumber,
    required this.duration,
    required this.status,
    required this.bookingDate,
  });
}

enum BookingStatus {
  confirmed,
  pending,
}
