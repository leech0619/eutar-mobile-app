import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No user is currently signed in.');
    }

    try {
      // Reauthenticate the user with the current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update the password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('The current password is incorrect.');
      } else {
        throw Exception(e.message ?? 'An error occurred.');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred.');
    }
  }
}