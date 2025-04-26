import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/auth.dart';
import '../screen/verify_screen.dart';

/// Controller for handling user registration functionality.
class RegisterController extends ChangeNotifier {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();
  String? selectedGender;
  String? selectedFaculty;

  // List of gender options
  final List<String> genders = ['Male', 'Female', 'Other'];

  // List of faculty options
  final List<String> faculties = [
    'Faculty of Accountancy and Management (FAM)',
    'Faculty of Arts and Social Science (FAS)',
    'Teh Hong Piow Faculty of Business and Finance (THP FBF)',
    'Faculty of Creative Industries (FCI)',
    'Faculty of Engineering and Green Technology (FEGT)',
    'Faculty of Information and Communication Technology (FICT)',
    'Faculty of Science (FSc)',
    'Institute of Chinese Studies (ICS)',
    'Lee Kong Chian Faculty of Engineering and Science (LKC FES)',
    'M. Kandiah Faculty of Medicine and Health Sciences (MK FMHS)',
  ];

  final AuthService _authService = AuthService(); // Instance of AuthService for authentication operations
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Authentication instance

  String? errorMessage; // Variable to store error messages
  bool isLoading = false; // Indicates whether a registration operation is in progress

  // Validation for full name
  String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your full name'; // Error for empty full name
    }
    return null; // Full name is valid
  }

  // Validation for gender
  String? validateGender(String? value) {
    if (value == null) {
      return 'Please select gender'; // Error for unselected gender
    }
    return null; // Gender is valid
  }

  // Validation for birthday
  String? validateBirthday(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter birthday'; // Error for empty birthday
    }
    return null; // Birthday is valid
  }

  // Validation for email
  Future<String?> validateEmail(String? value) async {
    if (value == null || value.isEmpty) {
      return 'Please enter your email'; // Error for empty email
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Please enter a valid email address'; // Error for invalid email format
    }

    try {
      // Check if the email is already registered
      final isRegistered = await isEmailRegistered(value.trim());
      if (isRegistered) {
        return 'This email is registered.'; // Error for already registered email
      }
    } catch (e) {
      return 'An error occurred.'; // Error for unexpected issues
    }

    return null; // Email is valid
  }

  // Validation for faculty
  String? validateFaculty(String? value) {
    if (value == null) {
      return 'Please select your faculty'; // Error for unselected faculty
    }
    return null; // Faculty is valid
  }

  // Validation for password
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password'; // Error for empty password
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long'; // Error for short password
    }
    return null; // Password is valid
  }

  // Validation for confirm password
  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password'; // Error for empty confirm password
    }
    if (value != passwordController.text) {
      return 'Passwords do not match'; // Error for mismatched passwords
    }
    return null; // Confirm password is valid
  }

  /// Checks if the provided email is already registered in Firebase.
  ///
  /// [email] is the email address to check.
  /// Returns `true` if the email is registered, otherwise `false`.
  Future<bool> isEmailRegistered(String email) async {
    try {
      // Fetch sign-in methods for the provided email
      final signInMethods = await _auth.fetchSignInMethodsForEmail(email.trim());

      // If sign-in methods are not empty, the email is registered
      return signInMethods.isNotEmpty;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Authentication errors
      if (e.code == 'invalid-email') {
        throw Exception('Invalid email address.');
      } else {
        throw Exception('An error occurred while checking the email.');
      }
    } catch (e) {
      // Handle unexpected errors
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Registers a new user.
  ///
  /// [context] is the BuildContext used to navigate to the VerifyScreen and show feedback.
  Future<void> register(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      isLoading = true;
      errorMessage = null; // Clear previous error message
      notifyListeners();

      try {
        // Check if the email is already registered
        final isRegistered = await isEmailRegistered(emailController.text.trim());
        if (isRegistered) {
          errorMessage = 'This email is registered.';
          isLoading = false; // Set loading state to false
          notifyListeners(); // Notify UI to update
          return; // Stop further execution
        }

        // Prepare user data
        final userData = {
          'fullName': fullNameController.text.trim(),
          'email': emailController.text.trim(),
          'gender': selectedGender,
          'birthday': birthdayController.text.trim(),
          'faculty': selectedFaculty,
        };

        // Register user and save data to Firestore
        final user = await _authService.registerWithEmailAndPassword(
          emailController.text.trim(),
          passwordController.text.trim(),
          userData,
        );

        if (user != null) {
          errorMessage = null; // Clear error message on success
          isLoading = false; // Set loading state to false
          // Send email verification
          await _authService.sendEmailVerification();
          notifyListeners(); // Notify UI to update

          // Navigate to VerifyScreen and remove all previous routes
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const VerifyScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        // Remove "Exception: " from the error message
        errorMessage = 'Registration failed.';
        isLoading = false; // Set loading state to false
        notifyListeners(); // Notify UI to update
      }
    }
  }
}