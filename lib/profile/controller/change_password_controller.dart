import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordController {
  final FirebaseAuth _auth =
      FirebaseAuth.instance; // Firebase Authentication instance

  /// Changes the user's password.
  ///
  /// [currentPassword] is the user's current password for reauthentication.
  /// [newPassword] is the new password to be set for the user.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser; // Get the currently signed-in user

    // Check if the user is signed in
    if (user == null) {
      throw Exception('No user is currently signed in.');
    }

    try {
      // Reauthenticate the user with the current password
      final credential = EmailAuthProvider.credential(
        email: user.email!, // The user's email
        password: currentPassword, // The current password provided by the user
      );

      await user.reauthenticateWithCredential(
        credential,
      ); // Reauthenticate the user

      // Update the password
      await user.updatePassword(newPassword); // Set the new password
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Authentication errors
      if (e.code == 'wrong-password') {
        throw Exception('The current password is incorrect.');
      } else {
        throw Exception(e.message ?? 'An error occurred.');
      }
    } catch (e) {
      // Handle unexpected errors
      throw Exception('An unexpected error occurred.');
    }
  }
}
