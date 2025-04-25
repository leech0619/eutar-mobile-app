import 'package:eutar/profile/screen/change_password_screen.dart';
import 'package:eutar/profile/screen/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import '../controller/profile_controller.dart';
import '../model/profile_model.dart';
import '../../authentication/screen/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final ProfileController controller = ProfileController();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'Edit Profile') {
                // Navigate to Edit Profile screen
                final profile =
                    await controller.fetchUserData(); // Fetch the user data
                if (profile != null) {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfileScreen(
                        profile: profile,
                      ), // Pass the ProfileModel
                    ),
                  );

                  // Refresh the profile data if changes were saved
                  if (result == true) {
                    // Call fetchUserData again to refresh the profile
                    controller.fetchUserData();
                    setState(() {});
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to load profile data'),
                    ),
                  );
                }
              } else if (value == 'Change Password') {
                // Navigate to ChangePasswordScreen and wait for the result
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChangePasswordScreen(),
                  ),
                );

                // Check the result and refresh the profile if needed
                if (result == true) {
                  // Show a success SnackBar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: const [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Password changed successfully',
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
                }
              } else if (value == 'Logout') {
                // Perform logout
                await controller.logout();

                // Show success SnackBar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: const [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Logout successful',
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

                // Navigate to the LoginScreen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'Edit Profile',
                child: Text(
                  'Edit Profile',
                  style: TextStyle(fontSize: 20),
                ),
              ),
              const PopupMenuItem(
                value: 'Change Password',
                child: Text(
                  'Change Password',
                  style: TextStyle(fontSize: 20),
                ),
              ),
              const PopupMenuItem(
                value: 'Logout',
                child: Text(
                  'Logout',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<ProfileModel?>(
        future: controller.fetchUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No user data available'));
          }

          final profile = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 50, color: Colors.blue),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        profile.fullName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Profile Details
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      _buildProfileDetailCard(
                        icon: Icons.school,
                        title: 'Faculty',
                        value: profile.faculty,
                      ),
                      const SizedBox(height: 10),
                      _buildProfileDetailCard(
                        icon: Icons.email,
                        title: 'Email',
                        value: profile.email,
                      ),
                      const SizedBox(height: 10),
                      _buildProfileDetailCard(
                        icon: Icons.person,
                        title: 'Gender',
                        value: profile.gender,
                      ),
                      const SizedBox(height: 10),
                      _buildProfileDetailCard(
                        icon: Icons.cake,
                        title: 'Birthday',
                        value: profile.birthday,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileDetailCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: Icon(icon, size: 30, color: Colors.blue),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
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
