import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:roadway/Services/StorageService.dart';

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
  final String responseMessage;
  final String responseCode;

  LoginResponse({
    required this.token,
    required this.responseMessage,
    required this.responseCode,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] ?? '',
      responseMessage: json['responseMessage'] ?? '',
      responseCode: json['responseCode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
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

// Main API Service Class
class ApiCalls {
  static const String baseUrl = "https://c06814910c9e.ngrok-free.app";
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

  // Login API Call
  static Future<ApiResponse<LoginResponse>> login({
    required String email,
    required String password,
  }) async {
    try {
      final loginRequest = LoginRequest(
        email: email,
        password: password,
      );

      print('🚀 Making login request to: $baseUrl/api/auth/login');
      print('📝 Request body: ${json.encode(loginRequest.toJson())}');

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/auth/login'),
            headers: _headers,
            body: json.encode(loginRequest.toJson()),
          )
          .timeout(timeoutDuration);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      return _handleResponse<LoginResponse>(
        response,
        (json) => LoginResponse.fromJson(json),
      );
    } catch (e) {
      print('❌ Login error: ${e.toString()}');
      return _handleException<LoginResponse>(e);
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
}
