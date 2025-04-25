import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/profile_model.dart';

class EditProfileController {
  Future<bool> updateProfile(ProfileModel updatedProfile) async {
    try {
      // Query Firestore to find the document with the matching email
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users') // Replace 'users' with your collection name
          .where('email', isEqualTo: updatedProfile.email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Get the document ID of the first matching document
        final docId = querySnapshot.docs.first.id;

        // Update the document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(docId)
            .update({
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
      throw Exception('Failed to update profile: $error');
    }
  }
}