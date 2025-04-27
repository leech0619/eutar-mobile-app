import 'package:eutar/profile/screen/change_password_screen.dart';
import 'package:eutar/profile/screen/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import '../controller/profile_controller.dart';
import '../model/profile_model.dart';
import '../../authentication/screen/login_screen.dart';

// ProfileScreen is responsible for displaying and managing user profile details
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Instantiate the controller once (outside build) to avoid recreating it unnecessarily
  final ProfileController controller = ProfileController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          // Popup menu for additional profile options
          PopupMenuButton<String>(
            onSelected: _handleMenuSelection,
            itemBuilder:
                (context) => const [
                  PopupMenuItem(
                    value: 'Edit Profile',
                    child: Text('Edit Profile', style: TextStyle(fontSize: 18)),
                  ),
                  PopupMenuItem(
                    value: 'Change Password',
                    child: Text(
                      'Change Password',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'Logout',
                    child: Text('Logout', style: TextStyle(fontSize: 18)),
                  ),
                ],
          ),
        ],
      ),

      // Body fetches and displays profile information asynchronously
      body: FutureBuilder<ProfileModel?>(
        future: controller.fetchUserData(), // Fetch user data
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show loading indicator while fetching
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // Show error if fetching fails
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            // Show message if no user data is available
            return const Center(child: Text('No user data available'));
          }

          // Successfully fetched user data
          final profile = snapshot.data!;

          return LayoutBuilder(
            builder: (context, constraints) {
              final screenHeight = constraints.maxHeight;

              // Calculate height proportions
              final headerHeight = screenHeight * 0.25; // 25% for header
              final detailsHeight = screenHeight * 0.70; // 70% for details

              return Column(
                children: [
                  // Profile Header Section
                  Container(
                    height: headerHeight,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Profile picture (placeholder icon)
                        const CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Display full name
                        Text(
                          profile.fullName,
                          style: TextStyle(
                            fontSize: screenHeight < 700 ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  // Profile Details Section
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Individual detail cards
                          _buildProfileDetailCard(
                            icon: Icons.school,
                            title: 'Faculty',
                            value: profile.faculty,
                            screenHeight: screenHeight,
                          ),
                          _buildProfileDetailCard(
                            icon: Icons.email,
                            title: 'Email',
                            value: profile.email,
                            screenHeight: screenHeight,
                          ),
                          _buildProfileDetailCard(
                            icon: Icons.person,
                            title: 'Gender',
                            value: profile.gender,
                            screenHeight: screenHeight,
                          ),
                          _buildProfileDetailCard(
                            icon: Icons.cake,
                            title: 'Birthday',
                            value: profile.birthday,
                            screenHeight: screenHeight,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // Handle menu selections: Edit Profile, Change Password, Logout
  Future<void> _handleMenuSelection(String value) async {
    if (value == 'Edit Profile') {
      final profile = await controller.fetchUserData();
      if (profile != null) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditProfileScreen(profile: profile),
          ),
        );
        if (result == true) {
          setState(() {}); // Refresh UI after editing
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load profile data')),
        );
      }
    } else if (value == 'Change Password') {
      // Ensure the SnackBar is shown only once
      if (mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
        );
        if (result == true) {
          ScaffoldMessenger.of(
            context,
          ).clearSnackBars(); // Clear any existing SnackBars
          ScaffoldMessenger.of(context).showSnackBar(
            _buildSuccessSnackBar('Password changed successfully'),
          );
        }
      }
    } else if (value == 'Logout') {
      await controller.logout();
      ScaffoldMessenger.of(
        context,
      ).clearSnackBars(); // Clear any existing SnackBars
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(_buildSuccessSnackBar('Logout successful'));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  // Build a success SnackBar for notifications
  SnackBar _buildSuccessSnackBar(String message) {
    return SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }

  // Build each profile detail card (e.g., Faculty, Email, Gender, Birthday)
  Widget _buildProfileDetailCard({
    required IconData icon,
    required String title,
    required String value,
    required double screenHeight,
  }) {
    double fontSize = screenHeight < 700 ? 14 : 16;
    double valueFontSize = screenHeight < 700 ? 16 : 18;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Icon inside a circle avatar
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.blue.withValues(alpha: 0.1),
              child: Icon(icon, size: 28, color: Colors.blue),
            ),
            const SizedBox(width: 20),
            // Title and Value texts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: valueFontSize,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis, // Truncate long text
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
