import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/auth.dart';
import '../model/profile_model.dart';

class ProfileController {
  final AuthService _authService = AuthService();

  Future<ProfileModel?> fetchUserData() async {
    final user = _authService.getCurrentUser();
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        return ProfileModel.fromMap(userDoc.data()!);
      }
    }
    return null;
  }

  Future<void> logout() async {
    await _authService.logout();
  }
}