import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static const String _recentSearchesKey = 'recent_searches';
  static const int _maxRecentSearches = 5;

  // Get recent searches from storage
  static Future<List<RouteData>> getRecentSearches() async {
    try {
      final jsonString = await _storage.read(key: _recentSearchesKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) {
            try {
              return RouteData.fromJson(Map<String, dynamic>.from(json));
            } catch (e) {
              print('Error parsing route data: $e');
              return null;
            }
          })
          .where((route) => route != null)
          .cast<RouteData>()
          .toList();
    } catch (e) {
      print('Error loading recent searches: $e');
      return [];
    }
  }

  // Add a new search to recent searches
  static Future<void> addRecentSearch(RouteData route) async {
    try {
      final currentSearches = await getRecentSearches();

      // Remove if already exists (to avoid duplicates)
      currentSearches.removeWhere((existing) =>
          existing.from.toLowerCase() == route.from.toLowerCase() &&
          existing.to.toLowerCase() == route.to.toLowerCase());

      // Add to beginning of list
      currentSearches.insert(0, route);

      // Keep only the most recent 5 searches
      if (currentSearches.length > _maxRecentSearches) {
        currentSearches.removeRange(_maxRecentSearches, currentSearches.length);
      }

      // Convert to JSON and save
      final jsonList = currentSearches.map((route) => route.toJson()).toList();
      final jsonString = jsonEncode(jsonList);

      await _storage.write(key: _recentSearchesKey, value: jsonString);
      print(
          '✅ Recent search saved successfully. Total: ${currentSearches.length}');
    } catch (e) {
      print('❌ Error saving recent search: $e');
    }
  }

  // Clear all recent searches
  static Future<void> clearRecentSearches() async {
    try {
      await _storage.delete(key: _recentSearchesKey);
      print('✅ Recent searches cleared successfully');
    } catch (e) {
      print('❌ Error clearing recent searches: $e');
    }
  }

  // Check if storage is available
  static Future<bool> isStorageAvailable() async {
    try {
      await _storage.write(key: 'test_key', value: 'test_value');
      await _storage.delete(key: 'test_key');
      return true;
    } catch (e) {
      print('❌ Storage not available: $e');
      return false;
    }
  }
}

// Enhanced RouteData class with better JSON handling
class RouteData {
  final String from;
  final String to;
  final String price;
  final String duration;
  final DateTime? searchDate;

  RouteData({
    required this.from,
    required this.to,
    required this.price,
    required this.duration,
    this.searchDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
      'price': price,
      'duration': duration,
      'searchDate': searchDate?.toIso8601String(),
      'timestamp': DateTime.now().millisecondsSinceEpoch, // For sorting
    };
  }

  factory RouteData.fromJson(Map<String, dynamic> json) {
    return RouteData(
      from: json['from']?.toString() ?? '',
      to: json['to']?.toString() ?? '',
      price: json['price']?.toString() ?? 'Search Again',
      duration: json['duration']?.toString() ?? '',
      searchDate: json['searchDate'] != null
          ? DateTime.tryParse(json['searchDate'].toString())
          : null,
    );
  }

  // Helper method to create a route for recent searches
  factory RouteData.forRecentSearch({
    required String from,
    required String to,
    required DateTime searchDate,
  }) {
    return RouteData(
      from: from,
      to: to,
      price: "Search Again",
      duration: _formatDateForDisplay(searchDate),
      searchDate: searchDate,
    );
  }

  static String _formatDateForDisplay(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return "Today";
    } else if (difference == 1) {
      return "Yesterday";
    } else if (difference < 7) {
      return "${difference}d ago";
    } else {
      return "${date.day}/${date.month}";
    }
  }

  @override
  String toString() {
    return 'RouteData(from: $from, to: $to, date: $searchDate)';
  }
}
