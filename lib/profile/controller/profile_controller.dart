import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/auth.dart';
import '../model/profile_model.dart';

class ProfileController {
  final AuthService _authService =
      AuthService(); // Instance of AuthService for authentication operations

  /// Fetches the user's profile data from Firestore.
  ///
  /// Returns a [ProfileModel] if the user data exists, or `null` if no data is found.
  Future<ProfileModel?> fetchUserData() async {
    final user =
        _authService.getCurrentUser(); // Get the currently signed-in user
    if (user != null) {
      // Fetch the user's document from the Firestore 'users' collection
      final userDoc =
          await FirebaseFirestore.instance
              .collection(
                'users',
              ) // Replace 'users' with your Firestore collection name if different
              .doc(user.uid) // Use the user's UID as the document ID
              .get();

      // Check if the document exists
      if (userDoc.exists) {
        // Convert the Firestore document data to a ProfileModel
        return ProfileModel.fromMap(userDoc.data()!);
      }
    }
    return null; // Return null if no user is signed in or no data is found
  }

  /// Logs out the currently signed-in user.
  ///
  /// This method clears the user's authentication state.
  Future<void> logout() async {
    await _authService.logout(); // Call the logout method from AuthService
  }
}
