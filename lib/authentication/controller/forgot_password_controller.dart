import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      // Check if the email exists in Firebase Authentication
      final signInMethods = await _auth.fetchSignInMethodsForEmail(
        email.trim(),
      );

      if (signInMethods.isEmpty) {
        // Email does not exist
        return 'No user found with this email.';
      }

      // Email exists, send the password reset email
      await _auth.sendPasswordResetEmail(email: email.trim());
      return 'Password reset email sent. Please check your inbox.';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') {
        return 'The email address is not valid.';
      }
      return 'An error occurred. Please try again.';
    }
  }
}
