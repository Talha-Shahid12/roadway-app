// Create a new file: lib/models/route_data.dart
// This will be the single source of truth for RouteData

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

  // Factory constructor for recent searches
  factory RouteData.forRecentSearch({
    required String from,
    required String to,
    required DateTime searchDate,
  }) {
    return RouteData(
      from: from,
      to: to,
      price: "Search Again",
      duration: "Recent",
      searchDate: searchDate,
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
      'price': price,
      'duration': duration,
      'searchDate': searchDate?.toIso8601String(),
    };
  }

  // Create from JSON for storage
  factory RouteData.fromJson(Map<String, dynamic> json) {
    return RouteData(
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      price: json['price'] ?? '',
      duration: json['duration'] ?? '',
      searchDate: json['searchDate'] != null
          ? DateTime.parse(json['searchDate'])
          : null,
    );
  }

  // Create a copy with updated values
  RouteData copyWith({
    String? from,
    String? to,
    String? price,
    String? duration,
    DateTime? searchDate,
  }) {
    return RouteData(
      from: from ?? this.from,
      to: to ?? this.to,
      price: price ?? this.price,
      duration: duration ?? this.duration,
      searchDate: searchDate ?? this.searchDate,
    );
  }

  @override
  String toString() {
    return 'RouteData(from: $from, to: $to, price: $price, duration: $duration, searchDate: $searchDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RouteData &&
        other.from == from &&
        other.to == to &&
        other.price == price &&
        other.duration == duration &&
        other.searchDate == searchDate;
  }

  @override
  int get hashCode {
    return from.hashCode ^
        to.hashCode ^
        price.hashCode ^
        duration.hashCode ^
        (searchDate?.hashCode ?? 0);
  }
}
