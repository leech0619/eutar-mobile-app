import 'package:shared_preferences/shared_preferences.dart';
import '../../home/screen/home_screen.dart';
import 'package:flutter/material.dart';
import '../../utils/auth.dart';
import '../../advisor/services/chat_session_service.dart'; // Import ChatSessionService

/// Controller for handling login functionality.
class LoginController extends ChangeNotifier {
  final GlobalKey<FormState> formKey =
      GlobalKey<FormState>();
  final TextEditingController emailController =
      TextEditingController();
  final TextEditingController passwordController =
      TextEditingController();
  bool isLoading = false;

  final AuthService _authService =
      AuthService(); // Instance of AuthService for authentication operations

  String? errorMessage; // Variable to store error messages

  /// Login method to authenticate the user.
  ///
  /// [context] is the BuildContext used to show SnackBars and navigate to the HomeScreen.
  Future<void> login(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      isLoading = true; // Set loading state to true
      errorMessage = null; // Clear any previous error messages
      notifyListeners(); // Notify listeners to update the UI

      try {
        // Attempt to log in
        final user = await _authService.loginWithEmailAndPassword(
          emailController.text.trim(), // Trim whitespace from email
          passwordController.text.trim(), // Trim whitespace from password
        );

        if (user != null) {
          // Save login state in shared_preferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);

          // Show success SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.white), // Success icon
                  SizedBox(width: 10), // Spacing between icon and text
                  Expanded(
                    child: Text(
                      'Login successful', // Success message
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

          // Navigate to the HomeScreen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } catch (e) {
        errorMessage = e.toString().replaceFirst(
          'Exception: ',
          '',
        ); // Extract error message

        // Show error SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white), // Error icon
                const SizedBox(width: 10), // Spacing between icon and text
                Expanded(
                  child: Text(
                    errorMessage!, // Display the error message
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red, // Red background for errors
            behavior: SnackBarBehavior.floating, // Floating SnackBar
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // Rounded corners
            ),
            margin: const EdgeInsets.all(16), // Margin around the SnackBar
            duration: const Duration(seconds: 3), // Duration of the SnackBar
          ),
        );
      } finally {
        isLoading = false; // Reset loading state
        notifyListeners(); // Notify listeners to update the UI
      }
    }
  }

  /// Sends a password reset email to the user.
  ///
  /// [context] is the BuildContext used to show feedback messages.
  Future<void> resetPassword(BuildContext context) async {
    try {
      await _authService.sendPasswordResetEmail(
        emailController.text.trim(),
      ); // Send reset email
      errorMessage = 'Password reset email sent!'; // Success message
      notifyListeners(); // Notify listeners to update the UI
    } catch (e) {
      errorMessage = e.toString().replaceFirst(
        'Exception: ',
        '',
      ); // Extract error message
      notifyListeners(); // Notify listeners to update the UI
    }
  }

  /// Validates the email input.
  ///
  /// Returns an error message if the email is invalid, or `null` if valid.
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email'; // Error for empty email
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Please enter a valid email address'; // Error for invalid email format
    }
    return null; // Email is valid
  }

  /// Validates the password input.
  ///
  /// Returns an error message if the password is invalid, or `null` if valid.
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password'; // Error for empty password
    }
    return null; // Password is valid
  }
}
