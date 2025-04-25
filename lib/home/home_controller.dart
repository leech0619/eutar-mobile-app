import 'package:eutar/busstation/bus_schedule_list_screen.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../authentication/screen/profile_screen.dart';
import '../advisor/advisor_page.dart';

class HomeController extends ChangeNotifier {
  int currentIndex = 0;

  final List<Widget> pages = [
    const HomeScreen(),
    const ResourcePage(),
    const AdvisorPage(),
    const BusScheduleListScreen(),
    const ProfileScreen(),
  ];

  void updateIndex(int index) {
    currentIndex = index;
    notifyListeners();
  }
}
