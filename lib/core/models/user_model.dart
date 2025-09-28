import 'package:cloud_firestore/cloud_firestore.dart';
import 'elo_rating.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final int level;
  final int totalXP;
  final int totalFocusMinutes;
  final int currentStreak;
  final int longestStreak;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final UserPreferences preferences;
  final String? photoUrl;
  final String? bio;
  final EloRating eloRating;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.level,
    required this.totalXP,
    required this.totalFocusMinutes,
    required this.currentStreak,
    required this.longestStreak,
    required this.createdAt,
    required this.lastLoginAt,
    required this.preferences,
    required this.eloRating,
    this.photoUrl,
    this.bio,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Handle timestamp fields with null safety
    DateTime getTimestamp(dynamic value, DateTime defaultValue) {
      if (value == null) return defaultValue;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return defaultValue;
    }

    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? 'Focus Hero',
      level: map['level'] ?? 1,
      totalXP: map['totalXP'] ?? 0,
      totalFocusMinutes: map['totalFocusMinutes'] ?? 0,
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      createdAt: getTimestamp(map['createdAt'], DateTime.now()),
      lastLoginAt: getTimestamp(map['lastLoginAt'], DateTime.now()),
      preferences: UserPreferences.fromMap(map['preferences'] ?? {}),
      eloRating: map['eloRating'] != null
          ? EloRating.fromMap(map['eloRating'])
          : EloRating.initial(),
      photoUrl: map['photoUrl'],
      bio: map['bio'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'level': level,
      'totalXP': totalXP,
      'totalFocusMinutes': totalFocusMinutes,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'preferences': preferences.toMap(),
      'eloRating': eloRating.toMap(),
      'photoUrl': photoUrl,
      'bio': bio,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    int? level,
    int? totalXP,
    int? totalFocusMinutes,
    int? currentStreak,
    int? longestStreak,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    UserPreferences? preferences,
    EloRating? eloRating,
    String? photoUrl,
    String? bio,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      level: level ?? this.level,
      totalXP: totalXP ?? this.totalXP,
      totalFocusMinutes: totalFocusMinutes ?? this.totalFocusMinutes,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      preferences: preferences ?? this.preferences,
      eloRating: eloRating ?? this.eloRating,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
    );
  }
}

class UserPreferences {
  final int focusDuration;
  final int breakDuration;
  final int longBreakDuration;
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool darkModeEnabled;
  final String focusReminderTime;
  final List<String> blockedApps;
  final List<String> blockedWebsites;

  UserPreferences({
    required this.focusDuration,
    required this.breakDuration,
    required this.longBreakDuration,
    required this.notificationsEnabled,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.darkModeEnabled,
    required this.focusReminderTime,
    required this.blockedApps,
    required this.blockedWebsites,
  });

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      focusDuration: map['focusDuration'] ?? 25,
      breakDuration: map['breakDuration'] ?? 5,
      longBreakDuration: map['longBreakDuration'] ?? 15,
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      soundEnabled: map['soundEnabled'] ?? true,
      vibrationEnabled: map['vibrationEnabled'] ?? true,
      darkModeEnabled: map['darkModeEnabled'] ?? false,
      focusReminderTime: map['focusReminderTime'] ?? '09:00',
      blockedApps: List<String>.from(map['blockedApps'] ?? []),
      blockedWebsites: List<String>.from(map['blockedWebsites'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'focusDuration': focusDuration,
      'breakDuration': breakDuration,
      'longBreakDuration': longBreakDuration,
      'notificationsEnabled': notificationsEnabled,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'darkModeEnabled': darkModeEnabled,
      'focusReminderTime': focusReminderTime,
      'blockedApps': blockedApps,
      'blockedWebsites': blockedWebsites,
    };
  }

  UserPreferences copyWith({
    int? focusDuration,
    int? breakDuration,
    int? longBreakDuration,
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? darkModeEnabled,
    String? focusReminderTime,
    List<String>? blockedApps,
    List<String>? blockedWebsites,
  }) {
    return UserPreferences(
      focusDuration: focusDuration ?? this.focusDuration,
      breakDuration: breakDuration ?? this.breakDuration,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      focusReminderTime: focusReminderTime ?? this.focusReminderTime,
      blockedApps: blockedApps ?? this.blockedApps,
      blockedWebsites: blockedWebsites ?? this.blockedWebsites,
    );
  }
}