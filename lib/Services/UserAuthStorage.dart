import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserAuthStorage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static const String _userDataKey = 'user_data';
  static const String _tokenKey = 'auth_token';

  // Get user data from storage
  static Future<UserData?> getUserData() async {
    try {
      final jsonString = await _storage.read(key: _userDataKey);
      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }

      final Map<String, dynamic> json = jsonDecode(jsonString);
      return UserData.fromJson(json);
    } catch (e) {
      print('❌ Error loading user data: $e');
      return null;
    }
  }

  // Save user data to storage
  static Future<void> saveUserData(UserData userData) async {
    try {
      final jsonString = jsonEncode(userData.toJson());
      await _storage.write(key: _userDataKey, value: jsonString);
      print('✅ User data saved successfully');
    } catch (e) {
      print('❌ Error saving user data: $e');
    }
  }

  // Get auth token separately (for quick access)
  static Future<String?> getAuthToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      print('❌ Error loading auth token: $e');
      return null;
    }
  }

  // Save auth token separately
  static Future<void> saveAuthToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
      print('✅ Auth token saved successfully');
    } catch (e) {
      print('❌ Error saving auth token: $e');
    }
  }

  // Update specific user field
  static Future<void> updateUserField(String field, String value) async {
    try {
      final currentUser = await getUserData();
      if (currentUser != null) {
        UserData updatedUser;
        switch (field.toLowerCase()) {
          case 'name':
            updatedUser = currentUser.copyWith(name: value);
            break;
          case 'email':
            updatedUser = currentUser.copyWith(email: value);
            break;
          case 'gender':
            updatedUser = currentUser.copyWith(gender: value);
            break;
          case 'token':
            updatedUser = currentUser.copyWith(token: value);
            await saveAuthToken(value); // Also update separate token storage
            break;
          default:
            print('❌ Unknown field: $field');
            return;
        }
        await saveUserData(updatedUser);
        print('✅ User field "$field" updated successfully');
      }
    } catch (e) {
      print('❌ Error updating user field: $e');
    }
  }

  // Check if user is logged in
  static Future<bool> isUserLoggedIn() async {
    try {
      final token = await getAuthToken();
      final userData = await getUserData();
      return token != null && token.isNotEmpty && userData != null;
    } catch (e) {
      print('❌ Error checking login status: $e');
      return false;
    }
  }

  // Clear all user data (logout)
  static Future<void> clearUserData() async {
    try {
      await _storage.delete(key: _userDataKey);
      await _storage.delete(key: _tokenKey);
      print('✅ User data cleared successfully');
    } catch (e) {
      print('❌ Error clearing user data: $e');
    }
  }

  // Get user name quickly
  static Future<String?> getUserName() async {
    try {
      final userData = await getUserData();
      return userData?.name;
    } catch (e) {
      print('❌ Error getting user name: $e');
      return null;
    }
  }

  // Get user email quickly
  static Future<String?> getUserEmail() async {
    try {
      final userData = await getUserData();
      return userData?.email;
    } catch (e) {
      print('❌ Error getting user email: $e');
      return null;
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

// UserData class to handle user information
class UserData {
  final String token;
  final String name;
  final String email;
  final String gender;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  UserData({
    required this.token,
    required this.name,
    required this.email,
    required this.gender,
    this.createdAt,
    this.lastLogin,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'name': name,
      'email': email,
      'gender': gender,
      'createdAt': createdAt?.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  // Create from JSON
  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      token: json['token']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      lastLogin: json['lastLogin'] != null
          ? DateTime.tryParse(json['lastLogin'].toString())
          : null,
    );
  }

  // Create a copy with updated fields
  UserData copyWith({
    String? token,
    String? name,
    String? email,
    String? gender,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return UserData(
      token: token ?? this.token,
      name: name ?? this.name,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  // Helper method for login
  factory UserData.fromLogin({
    required String token,
    required String name,
    required String email,
    required String gender,
  }) {
    return UserData(
      token: token,
      name: name,
      email: email,
      gender: gender,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
    );
  }

  // Update last login time
  UserData updateLastLogin() {
    return copyWith(lastLogin: DateTime.now());
  }

  // Check if user data is complete
  bool get isComplete {
    return token.isNotEmpty &&
        name.isNotEmpty &&
        email.isNotEmpty &&
        gender.isNotEmpty;
  }

  // Get display name (first name only)
  String get displayName {
    return name.split(' ').first;
  }

  // Get initials for avatar
  String get initials {
    final names = name.trim().split(' ');
    if (names.length >= 2) {
      return '${names.first[0]}${names.last[0]}'.toUpperCase();
    } else if (names.isNotEmpty) {
      return names.first.substring(0, 1).toUpperCase();
    }
    return 'U';
  }

  @override
  String toString() {
    return 'UserData(name: $name, email: $email, gender: $gender, hasToken: ${token.isNotEmpty})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserData &&
        other.token == token &&
        other.name == name &&
        other.email == email &&
        other.gender == gender;
  }

  @override
  int get hashCode {
    return token.hashCode ^ name.hashCode ^ email.hashCode ^ gender.hashCode;
  }
}
