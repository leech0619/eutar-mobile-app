import 'package:flutter/material.dart';
import '../../utils/auth.dart';
import '../screen/login_screen.dart';

class VerifyController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool canResendEmail = true;
  bool emailResent = false; // Tracks if the email has been resent
  String? errorMessage; // Variable to store error messages

  Future<void> resendEmailVerification(BuildContext context) async {
    if (canResendEmail && !emailResent) {
      try {
        await _authService.sendEmailVerification();
        canResendEmail = false;
        emailResent = true; // Mark email as resent
        errorMessage = null; // Clear previous error message
        notifyListeners();
      } catch (e) {
        errorMessage =
            'Failed to send email: ${e.toString()}'; // Set error message
        notifyListeners();
      }
    }
  }

  void navigateToLogin(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }
}
