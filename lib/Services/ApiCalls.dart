import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:roadway/Services/StorageService.dart';
import 'package:roadway/Services/UserAuthStorage.dart';

// Response Models
class ApiResponse<T> {
  final bool success;
  final String message;
  final String responseCode;
  final T? data;
  final String? error;

  ApiResponse({
    required this.success,
    required this.message,
    required this.responseCode,
    this.data,
    this.error,
  });

  factory ApiResponse.success({
    required String message,
    required String responseCode,
    T? data,
  }) {
    return ApiResponse<T>(
      success: true,
      message: message,
      responseCode: responseCode,
      data: data,
    );
  }

  factory ApiResponse.error({
    required String message,
    String responseCode = "99",
    String? error,
  }) {
    return ApiResponse<T>(
      success: false,
      message: message,
      responseCode: responseCode,
      error: error,
    );
  }
}

class RegisterResponse {
  final String responseMessage;
  final String responseCode;

  RegisterResponse({
    required this.responseMessage,
    required this.responseCode,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      responseMessage: json['responseMessage'] ?? '',
      responseCode: json['responseCode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'responseMessage': responseMessage,
      'responseCode': responseCode,
    };
  }
}

class LoginResponse {
  final String token;
  final String name;
  final String email;
  final String gender;
  final String responseMessage;
  final String responseCode;

  LoginResponse({
    required this.name,
    required this.email,
    required this.gender,
    required this.token,
    required this.responseMessage,
    required this.responseCode,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      gender: json['gender'] ?? '',
      token: json['token'] ?? '',
      responseMessage: json['responseMessage'] ?? '',
      responseCode: json['responseCode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'gender': gender,
      'token': token,
      'responseMessage': responseMessage,
      'responseCode': responseCode,
    };
  }
}

// New Slot Models matching your API response
class TripData {
  final String id;
  final String busNumber;
  final String pickupLocation;
  final String destination;
  final String departureTime;
  final String arrivalTime;
  final double fare;
  final String createdAt;
  final String updatedAt;

  TripData({
    required this.id,
    required this.busNumber,
    required this.pickupLocation,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.fare,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TripData.fromJson(Map<String, dynamic> json) {
    return TripData(
      id: json['_id'] ?? '',
      busNumber: json['busNumber'] ?? '',
      pickupLocation: json['pickupLocation'] ?? '',
      destination: json['destination'] ?? '',
      departureTime: json['departureTime'] ?? '',
      arrivalTime: json['arrivalTime'] ?? '',
      fare: (json['fare'] ?? 0.0).toDouble(),
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'busNumber': busNumber,
      'pickupLocation': pickupLocation,
      'destination': destination,
      'departureTime': departureTime,
      'arrivalTime': arrivalTime,
      'fare': fare,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class SlotData {
  final String id;
  final String tripId;
  final String busNumber;
  final String date;
  final int totalSeats;
  final int availableSeats;
  final String slotStatus;
  final double baseFare;
  final String createdAt;
  final String updatedAt;
  final TripData trip;

  SlotData({
    required this.id,
    required this.tripId,
    required this.busNumber,
    required this.date,
    required this.totalSeats,
    required this.availableSeats,
    required this.slotStatus,
    required this.baseFare,
    required this.createdAt,
    required this.updatedAt,
    required this.trip,
  });

  factory SlotData.fromJson(Map<String, dynamic> json) {
    return SlotData(
      id: json['_id'] ?? '',
      tripId: json['tripId'] ?? '',
      busNumber: json['busNumber'] ?? '',
      date: json['date'] ?? '',
      totalSeats: json['totalSeats'] ?? 0,
      availableSeats: json['availableSeats'] ?? 0,
      slotStatus: json['slotStatus'] ?? '',
      baseFare: (json['baseFare'] ?? 0.0).toDouble(),
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      trip: TripData.fromJson(json['trip'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'tripId': tripId,
      'busNumber': busNumber,
      'date': date,
      'totalSeats': totalSeats,
      'availableSeats': availableSeats,
      'slotStatus': slotStatus,
      'baseFare': baseFare,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'trip': trip.toJson(),
    };
  }

  // Helper getters for easy access
  String get from => trip.pickupLocation;
  String get to => trip.destination;
  String get departureTime => trip.departureTime;
  String get arrivalTime => trip.arrivalTime;
  double get fare => trip.fare;
}

class SearchSlotsResponse {
  final bool success;
  final List<SlotData> trips;
  final int totalSlots;
  final String? message;

  SearchSlotsResponse({
    required this.success,
    required this.trips,
    required this.totalSlots,
    this.message,
  });

  factory SearchSlotsResponse.fromJson(Map<String, dynamic> json) {
    List<SlotData> tripsList = [];

    if (json['trips'] != null && json['trips'] is List) {
      tripsList = (json['trips'] as List)
          .map((trip) => SlotData.fromJson(trip as Map<String, dynamic>))
          .toList();
    }

    return SearchSlotsResponse(
      success: json['success'] ?? false,
      trips: tripsList,
      totalSlots: json['totalSlots'] ?? 0,
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'trips': trips.map((trip) => trip.toJson()).toList(),
      'totalSlots': totalSlots,
      'message': message,
    };
  }
}

// Request Models
class RegisterRequest {
  final String name;
  final String email;
  final String password;
  final String gender;

  RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
    required this.gender,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'gender': gender,
    };
  }
}

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class SearchSlotsRequest {
  final String from;
  final String to;
  final String dateInput;

  SearchSlotsRequest({
    required this.from,
    required this.to,
    required this.dateInput,
  });

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
      'dateInput': dateInput,
    };
  }
}

// API Exception Classes
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? responseCode;

  ApiException({
    required this.message,
    this.statusCode,
    this.responseCode,
  });

  @override
  String toString() => 'ApiException: $message';
}

class NetworkException implements Exception {
  final String message;

  NetworkException({required this.message});

  @override
  String toString() => 'NetworkException: $message';
}

class TimeoutException implements Exception {
  final String message;

  TimeoutException({required this.message});

  @override
  String toString() => 'TimeoutException: $message';
}

class SeatStatus {
  final String? gender;
  final int seatNumber;
  final String status;
  final String? bookedBy;
  final String? bookingId;
  final String? bookedAt;
  final String id;

  SeatStatus({
    this.gender,
    required this.seatNumber,
    required this.status,
    this.bookedBy,
    this.bookingId,
    this.bookedAt,
    required this.id,
  });

  factory SeatStatus.fromJson(Map<String, dynamic> json) {
    return SeatStatus(
      gender: json['gender'],
      seatNumber: json['seatNumber'] ?? 0,
      status: json['status'] ?? 'Available',
      bookedBy: json['bookedBy'],
      bookingId: json['bookingId'],
      bookedAt: json['bookedAt'],
      id: json['_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gender': gender,
      'seatNumber': seatNumber,
      'status': status,
      'bookedBy': bookedBy,
      'bookingId': bookingId,
      'bookedAt': bookedAt,
      '_id': id,
    };
  }
}

class SlotDetailData {
  final String id;
  final String tripId;
  final String busNumber;
  final String date;
  final int totalSeats;
  final int availableSeats;
  final String slotStatus;
  final double baseFare;
  final List<SeatStatus> seatStatus;
  final String createdAt;
  final String updatedAt;

  SlotDetailData({
    required this.id,
    required this.tripId,
    required this.busNumber,
    required this.date,
    required this.totalSeats,
    required this.availableSeats,
    required this.slotStatus,
    required this.baseFare,
    required this.seatStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SlotDetailData.fromJson(Map<String, dynamic> json) {
    List<SeatStatus> seatStatusList = [];

    if (json['seatStatus'] != null && json['seatStatus'] is List) {
      seatStatusList = (json['seatStatus'] as List)
          .map((seat) => SeatStatus.fromJson(seat as Map<String, dynamic>))
          .toList();
    }

    return SlotDetailData(
      id: json['_id'] ?? '',
      tripId: json['tripId'] ?? '',
      busNumber: json['busNumber'] ?? '',
      date: json['date'] ?? '',
      totalSeats: json['totalSeats'] ?? 0,
      availableSeats: json['availableSeats'] ?? 0,
      slotStatus: json['slotStatus'] ?? '',
      baseFare: (json['baseFare'] ?? 0.0).toDouble(),
      seatStatus: seatStatusList,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'tripId': tripId,
      'busNumber': busNumber,
      'date': date,
      'totalSeats': totalSeats,
      'availableSeats': availableSeats,
      'slotStatus': slotStatus,
      'baseFare': baseFare,
      'seatStatus': seatStatus.map((seat) => seat.toJson()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class GetSlotDataResponse {
  final bool success;
  final SlotDetailData slot;
  final String? message;

  GetSlotDataResponse({
    required this.success,
    required this.slot,
    this.message,
  });

  factory GetSlotDataResponse.fromJson(Map<String, dynamic> json) {
    return GetSlotDataResponse(
      success: json['success'] ?? false,
      slot: SlotDetailData.fromJson(json['slot'] ?? {}),
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'slot': slot.toJson(),
      'message': message,
    };
  }
}

class GetSlotDataRequest {
  final String slotId;

  GetSlotDataRequest({
    required this.slotId,
  });

  Map<String, dynamic> toJson() {
    return {
      'slotId': slotId,
    };
  }
}

// New Booking Response Model
class BookingResponse {
  final String responseMessage;
  final String responseCode;

  BookingResponse({
    required this.responseMessage,
    required this.responseCode,
  });

  factory BookingResponse.fromJson(Map<String, dynamic> json) {
    return BookingResponse(
      responseMessage: json['responseMessage'] ?? '',
      responseCode: json['responseCode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'responseMessage': responseMessage,
      'responseCode': responseCode,
    };
  }
}

// New Booking Request Model
class BookingRequest {
  final String tripId;
  final String email;
  final String travelDate;
  final Map<String, String> seatNumberDetails;

  BookingRequest({
    required this.tripId,
    required this.email,
    required this.travelDate,
    required this.seatNumberDetails,
  });

  Map<String, dynamic> toJson() {
    return {
      'tripId': tripId,
      'email': email,
      'travelDate': travelDate,
      'seatNumberDetails': seatNumberDetails,
    };
  }
}

class TopTripsResponse {
  final bool success;
  final String message;
  final List<TopTripData>? data;

  TopTripsResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory TopTripsResponse.fromJson(Map<String, dynamic> json) {
    return TopTripsResponse(
      success: json['responseCode'] == '00',
      message: json['responseMessage'] ?? 'Unknown error',
      data: json['data'] != null
          ? (json['data'] as List)
              .map((item) => TopTripData.fromJson(item))
              .toList()
          : null,
    );
  }
}

class TopTripData {
  final String id;
  final String busNumber;
  final String pickupLocation;
  final String destination;
  final String departureTime;
  final String arrivalTime;
  final int fare;
  final DateTime createdAt;

  TopTripData({
    required this.id,
    required this.busNumber,
    required this.pickupLocation,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.fare,
    required this.createdAt,
  });

  factory TopTripData.fromJson(Map<String, dynamic> json) {
    return TopTripData(
      id: json['_id'] ?? '',
      busNumber: json['busNumber'] ?? '',
      pickupLocation: json['pickupLocation'] ?? '',
      destination: json['destination'] ?? '',
      departureTime: json['departureTime'] ?? '',
      arrivalTime: json['arrivalTime'] ?? '',
      fare: json['fare'] ?? 0,
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Convert to RouteData for compatibility with existing UI
  RouteData toRouteData() {
    return RouteData(
      from: pickupLocation,
      to: destination,
      price: "PKR ${fare.toString()}",
      duration: _calculateDuration(),
    );
  }

  String _calculateDuration() {
    try {
      // Parse departure and arrival times
      final depTime = _parseTime(departureTime);
      final arrTime = _parseTime(arrivalTime);

      // Calculate duration
      Duration duration;
      if (arrTime.isBefore(depTime)) {
        // Next day arrival
        duration = arrTime.add(Duration(days: 1)).difference(depTime);
      } else {
        duration = arrTime.difference(depTime);
      }

      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;

      return "${hours}h ${minutes}m";
    } catch (e) {
      return "N/A";
    }
  }

  DateTime _parseTime(String timeStr) {
    // Parse time format like "03:00 PM"
    final parts = timeStr.split(' ');
    final timeParts = parts[0].split(':');
    int hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    if (parts.length > 1 && parts[1].toUpperCase() == 'PM' && hour != 12) {
      hour += 12;
    } else if (parts.length > 1 &&
        parts[1].toUpperCase() == 'AM' &&
        hour == 12) {
      hour = 0;
    }

    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }
}

// API Response Model
class AnnouncementResponse {
  final bool success;
  final String message;
  final List<AnnouncementApiModel> announcements;
  final int count;

  AnnouncementResponse({
    required this.success,
    required this.message,
    required this.announcements,
    required this.count,
  });

  factory AnnouncementResponse.fromJson(Map<String, dynamic> json) {
    return AnnouncementResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      announcements: (json['announcements'] as List<dynamic>?)
              ?.map((item) => AnnouncementApiModel.fromJson(item))
              .toList() ??
          [],
      count: json['count'] ?? 0,
    );
  }
}

// API Model that matches your API response
class AnnouncementApiModel {
  final String id;
  final String title;
  final String content;
  final String category;
  final String priority;
  final String operatorName;
  final String? email;
  final DateTime publishedDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  AnnouncementApiModel({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.priority,
    required this.operatorName,
    this.email,
    required this.publishedDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AnnouncementApiModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementApiModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? '',
      priority: json['priority'] ?? 'low',
      operatorName: json['operatorName'] ?? '',
      email: json['email'],
      publishedDate:
          DateTime.tryParse(json['publishedDate'] ?? '') ?? DateTime.now(),
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  // Convert API model to your existing AnnouncementData model
  AnnouncementData toAnnouncementData() {
    return AnnouncementData(
      id: id,
      title: title,
      content: content,
      operatorName: operatorName,
      category: category,
      priority: _mapPriority(priority),
      publishedDate: publishedDate,
      isRead: !isActive,
      imageUrl: null, // Add image URL if your API provides it
    );
  }

  AnnouncementPriority _mapPriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AnnouncementPriority.high;
      case 'medium':
        return AnnouncementPriority.medium;
      case 'low':
      default:
        return AnnouncementPriority.low;
    }
  }
}

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

// Add this response model to your existing models
class MarkAnnouncementResponse {
  final bool success;
  final String message;
  final String responseCode;
  final Map<String, dynamic>? data;

  MarkAnnouncementResponse({
    required this.success,
    required this.message,
    required this.responseCode,
    this.data,
  });

  factory MarkAnnouncementResponse.fromJson(Map<String, dynamic> json) {
    return MarkAnnouncementResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      responseCode: json['responseCode'] ?? '99',
      data: json['data'],
    );
  }
}

// Main API Service Class
class ApiCalls {
  static const String baseUrl = "https://03959292fbf3.ngrok-free.app";
  static const Duration timeoutDuration = Duration(seconds: 30);

  // Headers
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static Map<String, String> _headersWithToken(String token) => {
        ..._headers,
        'Authorization': 'Bearer $token',
      };

  // Helper method to handle HTTP responses
  static ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    try {
      final Map<String, dynamic> responseBody = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Success response
        final data = fromJson(responseBody);

        return ApiResponse.success(
          message: responseBody['responseMessage'] ??
              responseBody['message'] ??
              'Success',
          responseCode: responseBody['responseCode'] ?? '00',
          data: data,
        );
      } else {
        // Error response
        final errorMessage = responseBody['responseMessage'] ??
            responseBody['message'] ??
            'Unknown error occurred';
        final errorCode = responseBody['responseCode'] ?? '99';

        throw ApiException(
          message: errorMessage,
          statusCode: response.statusCode,
          responseCode: errorCode,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to parse response: ${e.toString()}',
        statusCode: response.statusCode,
      );
    }
  }

  static ApiResponse<GetSlotDataResponse> _handleGetSlotDataResponse(
      http.Response response) {
    try {
      final Map<String, dynamic> responseBody = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Success response
        final data = GetSlotDataResponse.fromJson(responseBody);
        return ApiResponse.success(
          message: data.message ?? 'Slot data retrieved successfully',
          responseCode: '00',
          data: data,
        );
      } else {
        // Error response
        final errorMessage =
            responseBody['message'] ?? 'Failed to retrieve slot data';

        throw ApiException(
          message: errorMessage,
          statusCode: response.statusCode,
          responseCode: '99',
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to parse response: ${e.toString()}',
        statusCode: response.statusCode,
      );
    }
  }

  // Helper method to handle HTTP responses for search slots
  static ApiResponse<SearchSlotsResponse> _handleSearchResponse(
      http.Response response) {
    try {
      final Map<String, dynamic> responseBody = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Success response - direct parsing since your API returns success: true
        final data = SearchSlotsResponse.fromJson(responseBody);
        return ApiResponse.success(
          message: data.message ?? 'Slots found successfully',
          responseCode: '00',
          data: data,
        );
      } else {
        // Error response
        final errorMessage =
            responseBody['message'] ?? 'Failed to search slots';

        throw ApiException(
          message: errorMessage,
          statusCode: response.statusCode,
          responseCode: '99',
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to parse response: ${e.toString()}',
        statusCode: response.statusCode,
      );
    }
  }

  // Helper method to handle exceptions
  static ApiResponse<T> _handleException<T>(dynamic error) {
    if (error is SocketException) {
      return ApiResponse.error(
        message: 'No internet connection. Please check your network.',
        error: 'NetworkError',
      );
    } else if (error is HttpException) {
      return ApiResponse.error(
        message: 'Server error occurred. Please try again later.',
        error: 'ServerError',
      );
    } else if (error is FormatException) {
      return ApiResponse.error(
        message: 'Invalid response format from server.',
        error: 'FormatError',
      );
    } else if (error is ApiException) {
      return ApiResponse.error(
        message: error.message,
        responseCode: error.responseCode ?? '99',
        error: 'ApiError',
      );
    } else if (error.toString().contains('TimeoutException')) {
      return ApiResponse.error(
        message: 'Request timeout. Please try again.',
        error: 'TimeoutError',
      );
    } else {
      return ApiResponse.error(
        message: 'An unexpected error occurred: ${error.toString()}',
        error: 'UnknownError',
      );
    }
  }

  // Utility method to validate booking data
  static String? validateBookingData(Map<String, dynamic> bookingData) {
    if (!bookingData.containsKey('tripId') ||
        bookingData['tripId'].toString().trim().isEmpty) {
      return 'Trip ID is required';
    }

    if (!bookingData.containsKey('email') ||
        bookingData['email'].toString().trim().isEmpty) {
      return 'Email is required';
    }

    if (!isValidEmail(bookingData['email'].toString())) {
      return 'Please provide a valid email address';
    }

    if (!bookingData.containsKey('travelDate') ||
        bookingData['travelDate'].toString().trim().isEmpty) {
      return 'Travel date is required';
    }

    if (!bookingData.containsKey('seatNumberDetails') ||
        bookingData['seatNumberDetails'] == null ||
        (bookingData['seatNumberDetails'] as Map).isEmpty) {
      return 'At least one seat must be selected';
    }

    return null;
  }

  // Register API Call
  static Future<ApiResponse<RegisterResponse>> register({
    required String fullName,
    required String email,
    required String password,
    required String gender,
  }) async {
    try {
      final registerRequest = RegisterRequest(
        name: fullName,
        email: email,
        password: password,
        gender: gender,
      );

      print('🚀 Making register request to: $baseUrl/api/auth/register');
      print('📝 Request body: ${json.encode(registerRequest.toJson())}');

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/auth/register'),
            headers: _headers,
            body: json.encode(registerRequest.toJson()),
          )
          .timeout(timeoutDuration);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      return _handleResponse<RegisterResponse>(
        response,
        (json) => RegisterResponse.fromJson(json),
      );
    } catch (e) {
      print('❌ Register error: ${e.toString()}');
      return _handleException<RegisterResponse>(e);
    }
  }

  static Future<ApiResponse<LoginResponse>> login({
    required String email,
    required String password,
  }) async {
    print('🔥 LOGIN FUNCTION STARTED'); // Add this at the very beginning

    try {
      final loginRequest = LoginRequest(
        email: email,
        password: password,
      );

      print('🚀 Making login request to: $baseUrl/api/auth/login');
      print('📝 Request body: ${json.encode(loginRequest.toJson())}');

      print('⏰ About to make HTTP request'); // Add this

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/auth/login'),
            headers: _headers,
            body: json.encode(loginRequest.toJson()),
          )
          .timeout(timeoutDuration);

      print('📥 Response received!'); // Add this
      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      // Handle the response
      final apiResponse = _handleResponse<LoginResponse>(
        response,
        (json) => LoginResponse.fromJson(json),
      );

      // If login is successful, store user data automatically
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ Login successful, storing user data...');
        await _storeUserDataFromLoginResponse(response.body);
      }

      return apiResponse;
    } catch (e) {
      print('❌ Login error: ${e.toString()}');
      print('❌ Error type: ${e.runtimeType}'); // Add this for more detail
      return _handleException<LoginResponse>(e);
    }
  }

  static Future<Map<String, dynamic>> updateFCMToken({
    required String email,
    required String fcmToken,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/announcement/update-fcm-token');
      log('Updating FCM token for email: $email');
      log("FCM Token: $fcmToken");
      log('Making FCM token update request to: $url');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'fcmToken': fcmToken,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              responseData['message'] ?? 'FCM token updated successfully',
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update FCM token',
          'errors': responseData['errors'] ?? [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'errors': [],
      };
    }
  }

// Helper function to store user data from login response
  static Future<void> _storeUserDataFromLoginResponse(
      String responseBody) async {
    try {
      final Map<String, dynamic> response = json.decode(responseBody);

      // Check if response contains user data and is successful
      if (response['responseCode'] == '00' &&
          response['responseMessage'] == 'Success' &&
          response.containsKey('user')) {
        final Map<String, dynamic> userJson = response['user'];

        // Create UserData object
        final userData = UserData.fromLogin(
          token: userJson['token']?.toString() ?? '',
          name: userJson['name']?.toString() ?? '',
          email: userJson['email']?.toString() ?? '',
          gender: userJson['gender']?.toString() ?? '',
        );

        // Validate user data before storing
        if (userData.isComplete) {
          // Save to secure storage
          await UserAuthStorage.saveUserData(userData);

          // Also save token separately for quick access
          await UserAuthStorage.saveAuthToken(userData.token);

          print('💾 User data stored successfully:');
          print('   👤 Name: ${userData.name}');
          print('   📧 Email: ${userData.email}');
          print('   🎭 Gender: ${userData.gender}');
          print('   🔑 Token: ${userData.token}');
        } else {
          print('⚠️ Incomplete user data, not storing');
          print('   Token empty: ${userData.token.isEmpty}');
          print('   Name empty: ${userData.name.isEmpty}');
          print('   Email empty: ${userData.email.isEmpty}');
          print('   Gender empty: ${userData.gender.isEmpty}');
        }
      } else {
        print('⚠️ Response does not contain valid user data');
        print('   Response code: ${response['responseCode']}');
        print('   Contains user: ${response.containsKey('user')}');
      }
    } catch (e) {
      print('❌ Error storing user data from login response: $e');
    }
  }

  // Search Available Slots API Call
  static Future<ApiResponse<SearchSlotsResponse>> searchSlots({
    required String from,
    required String to,
    required String dateInput,
    String? token,
  }) async {
    try {
      final searchRequest = SearchSlotsRequest(
        from: from,
        to: to,
        dateInput: "2024-8-10",
      );

      print('🚀 Making search slots request to: $baseUrl/api/slots/search');
      print('📝 Request body: ${json.encode(searchRequest.toJson())}');

      final headers = token != null ? _headersWithToken(token) : _headers;

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/slots/search'), // Update endpoint as needed
            headers: headers,
            body: json.encode(searchRequest.toJson()),
          )
          .timeout(timeoutDuration);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      return _handleSearchResponse(response);
    } catch (e) {
      print('❌ Search slots error: ${e.toString()}');
      return _handleException<SearchSlotsResponse>(e);
    }
  }

  // Test Connection (Utility method)
  static Future<ApiResponse<String>> testConnection() async {
    try {
      print('🔍 Testing connection to: $baseUrl');

      final response = await http
          .get(
            Uri.parse('$baseUrl/api/health'), // Health check endpoint
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      print('📥 Health check status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return ApiResponse.success(
          message: 'Connection successful',
          responseCode: '00',
          data: 'Server is reachable',
        );
      } else {
        return ApiResponse.error(
          message: 'Server is not responding properly',
          responseCode: '99',
        );
      }
    } catch (e) {
      print('❌ Connection test error: ${e.toString()}');
      return _handleException<String>(e);
    }
  }

  // Utility method to validate email
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Utility method to validate password strength
  static bool isValidPassword(String password) {
    // At least 8 characters, 1 uppercase, 1 lowercase, 1 number
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password);
  }

  // Get password strength message
  static String getPasswordStrengthMessage(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain at least one number';
    }
    return 'Strong password';
  }

  // Utility method to format date for API
  static String formatDateForApi(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Utility method to validate search inputs
  static String? validateSearchInputs(
      String from, String to, DateTime? selectedDate) {
    if (from.trim().isEmpty) {
      return 'Please enter departure location';
    }

    if (to.trim().isEmpty) {
      return 'Please enter destination location';
    }

    if (from.trim().toLowerCase() == to.trim().toLowerCase()) {
      return 'Departure and destination locations cannot be the same';
    }

    if (selectedDate == null) {
      return 'Please select a travel date';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    if (selectedDay.isBefore(today)) {
      return 'Travel date cannot be in the past';
    }

    return null;
  }

  // Get Slot Data API Call
  static Future<ApiResponse<GetSlotDataResponse>> getSlotData({
    required String slotId,
    String? token,
  }) async {
    try {
      final getSlotDataRequest = GetSlotDataRequest(
        slotId: slotId,
      );

      print(
          '🚀 Making get slot data request to: $baseUrl/api/slots/getSlotData');
      print('📝 Request body: ${json.encode(getSlotDataRequest.toJson())}');

      final headers = token != null ? _headersWithToken(token) : _headers;

      final response = await http
          .post(
            Uri.parse(
                '$baseUrl/api/slots/getSlotData'), // Update endpoint as needed
            headers: headers,
            body: json.encode(getSlotDataRequest.toJson()),
          )
          .timeout(timeoutDuration);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      return _handleGetSlotDataResponse(response);
    } catch (e) {
      print('❌ Get slot data error: ${e.toString()}');
      return _handleException<GetSlotDataResponse>(e);
    }
  }

  static Future<ApiResponse<BookingResponse>> createBooking(
    Map<String, dynamic> bookingData, {
    String? token,
  }) async {
    try {
      // Validate booking data first
      final validationError = validateBookingData(bookingData);
      if (validationError != null) {
        throw ApiException(
          message: validationError,
          responseCode: '99',
        );
      }

      // Validate required fields
      if (!bookingData.containsKey('tripId') ||
          !bookingData.containsKey('email') ||
          !bookingData.containsKey('travelDate') ||
          !bookingData.containsKey('seatNumberDetails')) {
        throw ApiException(
          message: 'Missing required booking data fields',
          responseCode: '99',
        );
      }

      // Create booking request object
      final bookingRequest = BookingRequest(
        tripId: bookingData['tripId'].toString(),
        email: bookingData['email'].toString(),
        travelDate: bookingData['travelDate'].toString(),
        seatNumberDetails:
            Map<String, String>.from(bookingData['seatNumberDetails'] ?? {}),
      );

      print(
          '🚀 Making create booking request to: $baseUrl/api/bookings/create');
      print('📝 Request body: ${json.encode(bookingRequest.toJson())}');

      // Prepare headers (with or without token)
      final headers = token != null ? _headersWithToken(token) : _headers;

      // Make the API call
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/bookings/createBooking'),
            headers: headers,
            body: json.encode(bookingRequest.toJson()),
          )
          .timeout(timeoutDuration);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      // Handle the response using the existing _handleResponse method
      return _handleResponse<BookingResponse>(
        response,
        (json) => BookingResponse.fromJson(json),
      );
    } catch (e) {
      print('❌ Create booking error: ${e.toString()}');
      return _handleException<BookingResponse>(e);
    }
  }

  static Future<Map<String, dynamic>> fetchBookingHistory(String email) async {
    try {
      final response = await http.post(
        Uri.parse(
            '$baseUrl/api/bookings/getBookingHistory'), // Replace with your actual API endpoint
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📥 Booking history response: $data');
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch bookings: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error: $e',
      };
    }
  }

  static Future<TopTripsResponse> getTopTrips() async {
    try {
      print('🚌 Fetching top trips from API...');

      final response = await http.get(
        Uri.parse(
            '$baseUrl/api/trip/getTopTrips'), // Replace with your actual endpoint
        headers: {
          'Content-Type': 'application/json',
          // Add any required headers like authorization tokens
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception(
              'Request timeout. Please check your internet connection.');
        },
      );

      print('📡 API Response Status: ${response.statusCode}');
      print('📡 API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final topTripsResponse = TopTripsResponse.fromJson(jsonData);

        if (topTripsResponse.success) {
          print(
              '✅ Successfully fetched ${topTripsResponse.data?.length ?? 0} top trips');
          return topTripsResponse;
        } else {
          print('❌ API returned error: ${topTripsResponse.message}');
          return TopTripsResponse(
            success: false,
            message: topTripsResponse.message,
          );
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        return TopTripsResponse(
          success: false,
          message: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Exception in getTopTrips: $e');
      return TopTripsResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  static Future<AnnouncementResponse> fetchAnnouncements(String email) async {
    try {
      log("email in fetchAnnouncements: $email");
      final response = await http.post(
        Uri.parse(
            '$baseUrl/api/announcement/list'), // Replace with your actual endpoint
        headers: {
          'Content-Type': 'application/json',
          // Add any authentication headers if needed
          // 'Authorization': 'Bearer YOUR_TOKEN_HERE',
        },
        body: jsonEncode({
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return AnnouncementResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load announcements: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching announcements: $e');
    }
  }

// Add this function to your ApiCalls class
  static Future<ApiResponse<MarkAnnouncementResponse>> markAnnouncementAsRead({
    required String announcementId,
    String? token,
  }) async {
    try {
      print(
          '🚀 Making mark announcement as read request to: $baseUrl/api/announcement/mark-as-read');
      print('📝 Request body: ${json.encode({
            'announcementId': announcementId
          })}');

      final headers = token != null ? _headersWithToken(token) : _headers;

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/announcement/mark-as-read'),
            headers: headers,
            body: json.encode({
              'announcementId': announcementId,
            }),
          )
          .timeout(timeoutDuration);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      return _handleResponse<MarkAnnouncementResponse>(
        response,
        (json) => MarkAnnouncementResponse.fromJson(json),
      );
    } catch (e) {
      print('❌ Mark announcement as read error: ${e.toString()}');
      return _handleException<MarkAnnouncementResponse>(e);
    }
  }

  // Helper function to mark announcement as read and update local state
  static Future<bool> markAnnouncementAsReadAndUpdate({
    required String announcementId,
    String? token,
    Function(String)? onSuccess,
    Function(String)? onError,
  }) async {
    try {
      final response = await markAnnouncementAsRead(
        announcementId: announcementId,
        token: token,
      );

      if (response.success && response.data != null) {
        final markResponse = response.data!;

        if (markResponse.success && markResponse.responseCode == '00') {
          print('✅ Announcement marked as read successfully');
          onSuccess?.call(markResponse.message);
          return true;
        } else {
          print(
              '❌ Failed to mark announcement as read: ${markResponse.message}');
          onError?.call(markResponse.message);
          return false;
        }
      } else {
        print('❌ API call failed: ${response.message}');
        onError?.call(response.message);
        return false;
      }
    } catch (e) {
      print('❌ Exception in markAnnouncementAsReadAndUpdate: $e');
      onError?.call('Failed to mark announcement as read: $e');
      return false;
    }
  }

  // Function 1: Send OTP to email
  static Future<Map<String, dynamic>> sendOTP(String email) async {
    try {
      log("📤 Sending OTP to email: $email");

      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/send-otp'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      );

      log("📥 Send OTP Response: ${response.statusCode}");
      log("📥 Send OTP Body: ${response.body}");

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'OTP sent successfully',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to send OTP',
          'error': responseData['error'],
        };
      }
    } catch (e) {
      log("❌ Send OTP Error: $e");
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  // Function 2: Verify OTP
  static Future<Map<String, dynamic>> verifyOTP(
      String email, String otp) async {
    try {
      log("📤 Verifying OTP for email: $email");
      log("📤 OTP: $otp");

      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/verify-otp'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      );

      log("📥 Verify OTP Response: ${response.statusCode}");
      log("📥 Verify OTP Body: ${response.body}");

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'OTP verified successfully',
          'data': responseData['data'],
          'resetToken':
              responseData['resetToken'], // Token needed for password reset
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Invalid OTP',
          'error': responseData['error'],
        };
      }
    } catch (e) {
      log("❌ Verify OTP Error: $e");
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  // Function 3: Reset Password
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      log("📤 Resetting password for email: $email");

      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/reset-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'newPassword': newPassword,
        }),
      );

      log("📥 Reset Password Response: ${response.statusCode}");
      log("📥 Reset Password Body: ${response.body}");

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Password reset successfully',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to reset password',
          'error': responseData['error'],
        };
      }
    } catch (e) {
      log("❌ Reset Password Error: $e");
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }
}
