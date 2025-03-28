import 'package:flutter/material.dart';
import '../../utils/auth.dart';
import '../screen/verify_screen.dart';

class RegisterController extends ChangeNotifier {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController birthdayController = TextEditingController();
  String? selectedGender;
  String? selectedFaculty;

  final List<String> genders = ['Male', 'Female', 'Other'];
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

  final AuthService _authService = AuthService();

  String? errorMessage; // Variable to store error message
  bool isLoading = false; // Variable to track loading state

  // Validation for full name
  String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your full name';
    }
    return null;
  }

  // Validation for gender
  String? validateGender(String? value) {
    if (value == null) {
      return 'Please select your gender';
    }
    return null;
  }

  // Validation for birthday
  String? validateBirthday(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your birthday';
    }
    return null;
  }

  // Validation for email
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // Validation for faculty
  String? validateFaculty(String? value) {
    if (value == null) {
      return 'Please select your faculty';
    }
    return null;
  }

  // Validation for password
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  // Validation for confirm password
  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Register method
  Future<void> register(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      isLoading = true; // Set loading state to true
      errorMessage = null; // Clear previous error message
      notifyListeners(); // Notify UI to update

      try {
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
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        isLoading = false; // Set loading state to false
        notifyListeners(); // Notify UI to update
      }
    }
  }
}
