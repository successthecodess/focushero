import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/elo_rating.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';

class EloService {
  static final FirebaseFirestore _firestore = FirebaseService.firestore;
  static final FirebaseAuth _auth = FirebaseService.auth;

  // Update user's ELO after completing a session
  static Future<void> updateSessionFocus(int sessionMinutes) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) return;

    final userData = UserModel.fromMap(userDoc.data()!);
    final currentElo = userData.eloRating;

    // Update weekly focus time
    final updatedElo = WeeklyEloCalculator.updateWeeklyFocus(
      currentElo,
      sessionMinutes,
    );

    await _firestore.collection('users').doc(user.uid).update({
      'eloRating': updatedElo.toMap(),
    });
  }

  // Check and update ELO ratings daily
  static Future<void> checkAndUpdateDailyElo() async {
    final now = DateTime.now();

    // Query all users
    final usersSnapshot = await _firestore.collection('users').get();

    for (final doc in usersSnapshot.docs) {
      final userData = UserModel.fromMap(doc.data());
      final currentElo = userData.eloRating;

      // Check if it's time for daily update
      if (WeeklyEloCalculator.shouldUpdateRating(currentElo)) {
        final newElo = WeeklyEloCalculator.calculateWeeklyRating(
          currentElo,
          currentElo.weeklyFocusMinutes,
        );

        // Reset weekly focus for next period
        final resetElo = WeeklyEloCalculator.resetWeeklyFocus(newElo);

        await doc.reference.update({
          'eloRating': resetElo.toMap(),
        });
      }
    }
  }

  // Get user's current ELO ranking position
  static Future<int> getUserRanking(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .orderBy('eloRating.rating', descending: true)
        .get();

    int position = 1;
    for (final doc in snapshot.docs) {
      if (doc.id == userId) {
        return position;
      }
      position++;
    }

    return -1; // User not found
  }

  // Initialize ELO for new users
  static Future<void> initializeUserElo(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'eloRating': EloRating.initial().toMap(),
    });
  }

  // Get leaderboard data
  static Stream<QuerySnapshot> getEloLeaderboard({int limit = 10}) {
    return _firestore
        .collection('users')
        .orderBy('eloRating.rating', descending: true)
        .limit(limit)
        .snapshots();
  }
}