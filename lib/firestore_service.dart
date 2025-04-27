import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/feeding_schedule.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create user profile if not exists
  Future<void> createUserProfile(User user, String fullName) async {
    try {
      DocumentReference userRef = _db.collection('users').doc(user.uid);

      // Check if the user already exists
      DocumentSnapshot docSnapshot = await userRef.get();

      if (!docSnapshot.exists) {
        await userRef.set({
          'fullName': fullName,
          'email': user.email,
          'profilePictureUrl': '', // Optional, can be updated later
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

  // Create a feeding schedule for the user
  Future<void> createFeedingSchedule(FeedingSchedule feedingSchedule) async {
    try {
      print("Creating feeding schedule in Firestore");
      print("Data to save: ${feedingSchedule.toMap()}");

      DocumentReference feedingScheduleRef =
          _db.collection('feedingSchedules').doc();

      print("Document ID: ${feedingScheduleRef.id}");

      await feedingScheduleRef.set(feedingSchedule.toMap());

      // Verify data was written
      DocumentSnapshot savedDoc = await feedingScheduleRef.get();
      if (savedDoc.exists) {
        print("Document successfully written with data: ${savedDoc.data()}");
      } else {
        print("Document appears to be missing after write");
      }

      print("Feeding schedule created for user ${feedingSchedule.userId}");
    } catch (e) {
      print('Error creating feeding schedule: $e');
      print('Error stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Fetch feeding schedules for a specific user
  Future<List<FeedingSchedule>> getFeedingSchedules(String userId) async {
    try {
      QuerySnapshot querySnapshot =
          await _db
              .collection('feedingSchedules')
              .where('userId', isEqualTo: userId)
              .get();

      return querySnapshot.docs.map((doc) {
        return FeedingSchedule.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('Error fetching feeding schedules: $e');
      return [];
    }
  }

  // Fetch user data
  Future<Map<String, dynamic>> getUserData(String userId) async {
    try {
      DocumentSnapshot docSnapshot =
          await _db.collection('users').doc(userId).get();
      return docSnapshot.data() as Map<String, dynamic>;
    } catch (e) {
      print('Error fetching user data: $e');
      return {};
    }
  }

  // Update user profile
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
