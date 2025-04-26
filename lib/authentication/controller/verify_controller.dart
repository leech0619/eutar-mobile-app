import 'package:flutter/material.dart';
import '../../utils/auth.dart';
import '../screen/login_screen.dart';

/// Controller for handling email verification functionality.
class VerifyController extends ChangeNotifier {
  final AuthService _authService =
      AuthService(); // Instance of AuthService for authentication operations
  bool canResendEmail =
      true;
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
        canResendEmail = false;
        emailResent = true;
        errorMessage = null;
        notifyListeners();
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
