import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/feeding_schedule.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Create user profile if it does not exist
  Future<void> createUserProfile(User user, String fullName) async {
    try {
      DocumentReference userRef = _db.collection('users').doc(user.uid);
      DocumentSnapshot docSnapshot = await userRef.get();

      if (!docSnapshot.exists) {
        await userRef.set({
          'fullName': fullName,
          'email': user.email ?? '',
          'profilePictureUrl': '', // Default empty profile picture URL
        });
        print("User profile created for ${user.uid}");
      } else {
        print("User profile already exists for ${user.uid}");
      }
    } catch (e) {
      print('Error creating user profile: $e');
      rethrow;
    }
  }

  /// Check for duplicate feeding schedule (to the minute)
  Future<bool> isDuplicateSchedule({
    required String userId,
    required DateTime time,
    required String label,
  }) async {
    try {
      QuerySnapshot query =
          await _db
              .collection('feedingSchedules')
              .where('userId', isEqualTo: userId)
              .where('label', isEqualTo: label)
              .get();

      for (var doc in query.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final existingTime = DateTime.parse(data['time']);
        final t1 = DateTime(
          existingTime.year,
          existingTime.month,
          existingTime.day,
          existingTime.hour,
          existingTime.minute,
        );
        final t2 = DateTime(
          time.year,
          time.month,
          time.day,
          time.hour,
          time.minute,
        );
        if (t1.isAtSameMomentAs(t2)) return true;
      }
      return false;
    } catch (e) {
      print('Error checking for duplicate schedule: $e');
      return false;
    }
  }

  /// Create feeding schedule
  Future<void> createFeedingSchedule(FeedingSchedule feedingSchedule) async {
    try {
      DocumentReference ref = _db.collection('feedingSchedules').doc();
      await ref.set(feedingSchedule.toMap());
      print("Feeding schedule created for user ${feedingSchedule.userId}");
    } catch (e) {
      print('Error creating feeding schedule: $e');
      rethrow;
    }
  }

  /// Get all feeding schedules for user
  Future<List<FeedingSchedule>> getFeedingSchedules(String userId) async {
    try {
      QuerySnapshot snapshot =
          await _db
              .collection('feedingSchedules')
              .where('userId', isEqualTo: userId)
              .get();

      final now = DateTime.now();

      // Use a for loop instead of map to handle async operations
      List<FeedingSchedule> schedules = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        FeedingSchedule schedule = FeedingSchedule.fromMap(data);

        // Handle expired feeding schedules
        if (schedule.time.isBefore(now)) {
          // Mark expired schedules as completed
          if (!schedule.completed) {
            await doc.reference.update({'completed': true});
            print(
              "Marked expired feeding schedule as completed for ${schedule.userId}",
            );

            // Store this feeding schedule in notifications
            await _storeNotification(schedule);
          }
        }

        schedules.add(schedule);
      }

      return schedules;
    } catch (e) {
      print('Error fetching feeding schedules: $e');
      return [];
    }
  }

  /// Store expired feeding schedule as notification
  Future<void> _storeNotification(FeedingSchedule schedule) async {
    try {
      DocumentReference notificationRef = _db.collection('notifications').doc();
      await notificationRef.set({
        'userId': schedule.userId,
        'label': schedule.label,
        'time': schedule.time.toIso8601String(),
        'message': 'Feeding time for ${schedule.label} has passed.',
        'completed': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print(
        "Stored expired feeding schedule as notification for ${schedule.userId}",
      );
    } catch (e) {
      print("Error storing notification: $e");
    }
  }

  /// Update feeding schedule
  Future<void> updateFeedingSchedule(FeedingSchedule updatedSchedule) async {
    try {
      final query =
          await _db
              .collection('feedingSchedules')
              .where('userId', isEqualTo: updatedSchedule.userId)
              .where('time', isEqualTo: updatedSchedule.time.toIso8601String())
              .limit(1)
              .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update(updatedSchedule.toMap());
        print("Feeding schedule updated for ${updatedSchedule.userId}");
      } else {
        print("No schedule found to update.");
      }
    } catch (e) {
      print('Error updating feeding schedule: $e');
      rethrow;
    }
  }

  /// Mark expired feeding schedules as completed
  Future<void> markExpiredFeedingsAsCompleted(String userId) async {
    try {
      final snapshot =
          await _db
              .collection('feedingSchedules')
              .where('userId', isEqualTo: userId)
              .get();

      final now = DateTime.now();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final schedule = FeedingSchedule.fromMap(data);
        if (schedule.time.isBefore(now) && !schedule.completed) {
          await doc.reference.update({'completed': true});
          print(
            "Marked expired feeding schedule as completed for ${schedule.userId}",
          );

          // Store expired feeding schedule in notifications
          await _storeNotification(schedule);
        }
      }
    } catch (e) {
      print('Error marking expired feedings: $e');
      rethrow;
    }
  }

  /// Delete expired feeding schedules (if needed)
  Future<void> deleteExpiredFeedings(String userId) async {
    try {
      final snapshot =
          await _db
              .collection('feedingSchedules')
              .where('userId', isEqualTo: userId)
              .get();

      final now = DateTime.now();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final schedule = FeedingSchedule.fromMap(data);
        if (schedule.time.isBefore(now) && schedule.completed) {
          await doc.reference.delete();
          print(
            "Deleted expired feeding schedule at ${schedule.time} for $userId",
          );
        }
      }
    } catch (e) {
      print('Error deleting expired feeding schedules: $e');
      rethrow;
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>> getUserData(String userId) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'fullName': data['fullName'] ?? 'Unknown',
          'email': data['email'] ?? '',
          'profilePictureUrl': data['profilePictureUrl'] ?? '',
        };
      } else {
        return {};
      }
    } catch (e) {
      print('Error fetching user data: $e');
      return {};
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(
    String userId,
    String fullName,
    String email,
  ) async {
    try {
      await _db.collection('users').doc(userId).update({
        'fullName': fullName,
        'email': email,
      });
      print("User profile updated for $userId");
    } catch (e) {
      print('Error updating user profile: $e');
    }
  }
}
