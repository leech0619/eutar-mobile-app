import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class BottomNavigationBarWidget extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabChange;

  const BottomNavigationBarWidget({
    super.key,
    required this.currentIndex,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black38, spreadRadius: 0, blurRadius: 10),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5),
        child: GNav(
          selectedIndex: currentIndex,
          onTabChange: onTabChange,
          gap: 3,
          backgroundColor: Colors.white,
          color: Colors.black,
          activeColor: Colors.white,
          tabBackgroundColor: Colors.blueAccent,
          padding: const EdgeInsets.all(16),
          tabs: const [
            GButton(icon: Icons.home, text: "Home"),
            GButton(icon: Icons.book, text: "Resource"),
            GButton(icon: Icons.school, text: "Advisor"),
            GButton(icon: Icons.directions_bus, text: "Bus"),
            GButton(icon: Icons.person, text: "Profile"),
          ],
        ),
      ),
    );
  }
}
