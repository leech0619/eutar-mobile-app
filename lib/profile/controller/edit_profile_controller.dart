import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/profile_model.dart';

class EditProfileController {
  /// Updates the user's profile in Firestore.
  ///
  /// [updatedProfile] is the updated profile data to be saved in Firestore.
  /// Returns `true` if the update is successful, or `false` if no matching document is found.
  Future<bool> updateProfile(ProfileModel updatedProfile) async {
    try {
      // Query Firestore to find the document with the matching email
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('users') // Replace 'users' with your collection name
              .where('email', isEqualTo: updatedProfile.email) // Match by email
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Get the document ID of the first matching document
        final docId = querySnapshot.docs.first.id;

        // Update the document with the new profile data
        await FirebaseFirestore.instance.collection('users').doc(docId).update({
          'fullName': updatedProfile.fullName,
          'gender': updatedProfile.gender,
          'birthday': updatedProfile.birthday,
          'faculty': updatedProfile.faculty,
        });

        return true; // Update successful
      } else {
        return false; // No matching document found
      }
    } catch (error) {
      // Handle any errors that occur during the update process
      throw Exception('Failed to update profile: $error');
    }
  }
}
