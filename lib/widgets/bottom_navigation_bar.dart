import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class BottomNavigationBarWidget extends StatelessWidget {
  final int currentIndex; // The currently selected tab index
  final Function(int) onTabChange; // Callback function to handle tab changes

  const BottomNavigationBarWidget({
    super.key,
    required this.currentIndex,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    // Get screen width for responsive design
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate gap and padding dynamically based on screen size
    final double gap = screenWidth * 0.02; // 2% of screen width
    final double padding = screenWidth * 0.04; // 4% of screen width

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white, // Background color of the navigation bar
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30), // Rounded corners on the top left
          topRight: Radius.circular(30), // Rounded corners on the top right
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black38, // Shadow color
            spreadRadius: 0, // Spread radius of the shadow
            blurRadius: 10, // Blur radius of the shadow
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: padding, // Horizontal padding for the bar
          vertical: 10, // Fixed vertical padding for the bar
        ),
        child: GNav(
          selectedIndex: currentIndex, // The currently selected tab index
          onTabChange: onTabChange, // Callback for tab change
          gap: gap, // Gap between icon and text in each tab
          backgroundColor: Colors.white, // Background color of the navigation bar
          color: Colors.black, // Default icon color
          activeColor: Colors.white, // Icon color when active
          tabBackgroundColor: Colors.blueAccent, // Background color of active tab
          padding: EdgeInsets.all(12), // Padding inside each tab
          tabs: const [
            // Define the tabs with icons and labels
            GButton(icon: Icons.home, text: "Home"), // Home tab
            GButton(icon: Icons.book, text: "Resource"), // Resource tab
            GButton(icon: Icons.school, text: "Advisor"), // Advisor tab
            GButton(icon: Icons.directions_bus, text: "Bus"), // Bus tab
            GButton(icon: Icons.person, text: "Profile"), // Profile tab
          ],
        ),
      ),
    );
  }
}