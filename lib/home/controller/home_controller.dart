import 'package:eutar/busstation/screen/bus_schedule_list_screen.dart';
import 'package:eutar/resource_sharing/screen/resource_screen.dart';
import 'package:flutter/material.dart';
import '../screen/home_screen.dart';
import '../../profile/screen/profile_screen.dart';
import '../../advisor/advisor_page.dart';

class HomeController extends ChangeNotifier {
  int currentIndex = 0;

  final List<Widget> pages = [
    const HomeScreen(),
    const ResourceScreen(),
    const HomeScreen(),
    const BusScheduleListScreen(),
    const ProfileScreen(),
    const AdvisorPage(),
  ];

  void updateIndex(int index) {
    currentIndex = index;
    notifyListeners();
  }
}
