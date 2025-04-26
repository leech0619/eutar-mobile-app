import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth =
      FirebaseAuth.instance; // Firebase Authentication instance
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Firestore instance

  // Register a new user with email and password
  Future<User?> registerWithEmailAndPassword(
    String email,
    String password,
    Map<String, dynamic> userData, // Additional user data to store in Firestore
  ) async {
    try {
      // Create a new user in Firebase Authentication
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Save user data to Firestore
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userData);

      return userCredential.user; // Return the created user
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Authentication errors
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception(
            'The email address is already in use by another account.',
          );
        case 'invalid-email':
          throw Exception('The email address is not valid.');
        case 'weak-password':
          throw Exception(
            'The password is too weak. Please choose a stronger password.',
          );
        case 'operation-not-allowed':
          throw Exception(
            'Email/password accounts are not enabled. Please contact support.',
          );
        case 'network-request-failed':
          throw Exception(
            'Network error. Please check your internet connection and try again.',
          );
        default:
          throw Exception(e.message ?? 'An unknown error occurred.');
      }
    }
  }

  // Send email verification to the current user
  Future<void> sendEmailVerification() async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification(); // Send verification email
      }
    } catch (e) {
      throw Exception('Failed to send email verification: ${e.toString()}');
    }
  }

  // Log in a user with email and password
  Future<User?> loginWithEmailAndPassword(String email, String password) async {
    try {
      // Sign in the user
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      // Check if the email is verified
      if (user != null && !user.emailVerified) {
        throw Exception(
          'Your email is not verified. Please verify your email.',
        );
      }

      return user; // Return the logged-in user
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Authentication errors
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No user found with this email.');
        case 'wrong-password':
          throw Exception('Incorrect password. Please try again.');
        case 'invalid-email':
          throw Exception('The email address is not valid.');
        case 'user-disabled':
          throw Exception(
            'This user account has been disabled. Please contact support.',
          );
        case 'too-many-requests':
          throw Exception('Too many login attempts. Please try again later.');
        case 'network-request-failed':
          throw Exception(
            'Network error. Please check your internet connection and try again.',
          );
        default:
          throw Exception(e.message ?? 'An unknown error occurred.');
      }
    }
  }

  // Log out the current user
  Future<void> logout() async {
    try {
      // Clear the login state in shared_preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');

      // Log out the user from Firebase
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Failed to log out: $e');
    }
  }

  // Get the currently logged-in user
  User? getCurrentUser() {
    return _firebaseAuth.currentUser; // Return the current user
  }

  // Send a password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(
        email: email,
      ); // Send reset email
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Authentication errors
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No user found with this email.');
        case 'invalid-email':
          throw Exception('The email address is not valid.');
        default:
          throw Exception(e.message ?? 'An unknown error occurred.');
      }
    }
  }

  // Listen for authentication state changes
  Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges(); // Stream of auth state changes
  }

  // Update user profile (display name and photo URL)
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName); // Update display name
        await user.updatePhotoURL(photoURL); // Update photo URL
        await user.reload(); // Reload user data
      }
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  // Delete the current user account
  Future<void> deleteUser() async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.delete(); // Delete the user account
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Failed to delete user account.');
    }
  }

  // Reauthenticate the user with email and password
  Future<void> reauthenticateUser(String email, String password) async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user != null) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        await user.reauthenticateWithCredential(
          credential,
        ); // Reauthenticate user
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Reauthentication failed.');
    }
  }

  // Change the user's password
  Future<void> changePassword(String newPassword) async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword); // Update the password
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Failed to change password.');
    }
  }
}
