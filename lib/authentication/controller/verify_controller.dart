import 'package:flutter/material.dart';
import '../../utils/auth.dart';
import '../screen/login_screen.dart';

/// Controller for handling email verification functionality.
class VerifyController extends ChangeNotifier {
  final AuthService _authService =
      AuthService(); // Instance of AuthService for authentication operations
  bool canResendEmail = true;
  bool emailResent = false;
  String? errorMessage;

  /// Resends the email verification to the user.
  ///
  /// [context] is the BuildContext used to show feedback or navigate.
  Future<void> resendEmailVerification(BuildContext context) async {
    if (canResendEmail && !emailResent) {
      try {
        // Attempt to send the email verification
        await _authService.sendEmailVerification();
        canResendEmail = false; // Disable further resends
        emailResent = true; // Mark email as resent
        errorMessage = null;
        notifyListeners();

        // Show success message in SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white), // Success icon
                SizedBox(width: 10), // Spacing between icon and text
                Expanded(
                  child: Text(
                    'Verification email resent successfully!', // Success message
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      } catch (e) {
        // Set error message if email sending fails
        errorMessage = 'Failed to send email: ${e.toString()}';
        notifyListeners();
      }
    }
  }

  /// Navigates the user to the login screen.
  ///
  /// [context] is the BuildContext used for navigation.
  void navigateToLogin(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ), // Navigate to LoginScreen
      (route) => false, // Remove all previous routes
    );
  }
}
