import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Controller for handling forgot password functionality.
class ForgotPasswordController {
  final FirebaseAuth _auth =
      FirebaseAuth.instance; // Firebase Authentication instance

  /// Sends a password reset email to the user.
  ///
  /// [email] is the email address of the user requesting the password reset.
  /// [context] is the BuildContext used to show SnackBars for feedback.
  Future<void> sendPasswordResetEmail({
    required String email,
    required BuildContext context,
  }) async {
    try {
      // Check if the email exists in Firebase Authentication
      final signInMethods = await _auth.fetchSignInMethodsForEmail(
        email.trim(), // Trim whitespace from the email
      );

      if (signInMethods.isEmpty) {
        // Show error SnackBar if no user is found with the provided email
        _showSnackBar(
          context,
          'No user found with this email.',
          Colors.red,
          Icons.error,
        );
        return;
      }

      // Email exists, send the password reset email
      await _auth.sendPasswordResetEmail(email: email.trim());
      // Show success SnackBar
      _showSnackBar(
        context,
        'Password reset email sent. Please check your inbox.',
        Colors.green,
        Icons.check_circle,
      );
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Authentication errors
      if (e.code == 'invalid-email') {
        // Show error SnackBar for invalid email format
        _showSnackBar(
          context,
          'The email address is not valid.',
          Colors.red,
          Icons.error,
        );
      } else {
        // Show generic error SnackBar for other exceptions
        _showSnackBar(
          context,
          'An error occurred. Please try again.',
          Colors.red,
          Icons.error,
        );
      }
    }
  }

  /// Displays a SnackBar with a custom message, background color, and icon.
  ///
  /// [context] is the BuildContext used to show the SnackBar.
  /// [message] is the message to display in the SnackBar.
  /// [backgroundColor] is the background color of the SnackBar.
  /// [icon] is the icon to display in the SnackBar.
  void _showSnackBar(
    BuildContext context,
    String message,
    Color backgroundColor,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white), // Display the provided icon
            const SizedBox(width: 10), // Add spacing between the icon and text
            Expanded(
              child: Text(
                message, // Display the provided message
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior:
            SnackBarBehavior.floating, // Make the SnackBar float above content
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            10,
          )
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(
          seconds: 3,
        ),
      ),
    );
  }
}
