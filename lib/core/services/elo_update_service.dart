import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/elo_rating.dart';
import '../services/firebase_service.dart';

class EloUpdateService {
  static final FirebaseFirestore _firestore = FirebaseService.firestore;

  // Update ELO rating after each focus session
  static Future<void> updateEloAfterSession(String userId, int sessionMinutes) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return;

    final userData = userDoc.data()!;
    final currentElo = userData['eloRating'] != null
        ? EloRating.fromMap(userData['eloRating'])
        : EloRating.initial();

    // Update weekly focus time
    final updatedElo = WeeklyEloCalculator.updateWeeklyFocus(currentElo, sessionMinutes);

    await _firestore.collection('users').doc(userId).update({
      'eloRating': updatedElo.toMap(),
    });
  }

  // Weekly ELO calculation (run this weekly via Cloud Functions or scheduled job)
  static Future<void> performWeeklyEloUpdate() async {
    final users = await _firestore.collection('users').get();

    for (final userDoc in users.docs) {
      final userData = userDoc.data();
      final currentElo = userData['eloRating'] != null
          ? EloRating.fromMap(userData['eloRating'])
          : EloRating.initial();

      if (WeeklyEloCalculator.shouldUpdateRating(currentElo)) {
        // Calculate new rating based on weekly performance
        final newElo = WeeklyEloCalculator.calculateWeeklyRating(
          currentElo,
          currentElo.weeklyFocusMinutes,
        );

        // Reset weekly minutes after calculation
        final resetElo = WeeklyEloCalculator.resetWeeklyFocus(newElo);

        await _firestore.collection('users').doc(userDoc.id).update({
          'eloRating': resetElo.toMap(),
        });
      }
    }
  }

  // Check and update if needed (call this on app startup)
  static Future<void> checkAndUpdateUserElo(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return;

    final userData = userDoc.data()!;
    final currentElo = userData['eloRating'] != null
        ? EloRating.fromMap(userData['eloRating'])
        : EloRating.initial();

    if (WeeklyEloCalculator.shouldUpdateRating(currentElo)) {
      await performWeeklyEloUpdate();
    }
  }
}