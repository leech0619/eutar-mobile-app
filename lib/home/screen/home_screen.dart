import '../../widgets/bottom_navigation_bar.dart';

import '../../busstation/screen/bus_schedule_list_screen.dart';
import 'package:flutter/material.dart';
import '../../resource_sharing/screen/resource_screen.dart';
import '../../profile/screen/profile_screen.dart';
import '../../advisor/advisor_page.dart';

// Main HomeScreen widget that supports navigation
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // Track current selected tab index

  // Feature names and icons for the home page grid
  final List<String> featureNames = [
    'Resource Sharing',
    'Smart Academic Advisor Chatbot',
    'Bus Station Marker',
    'Profile',
  ];

  final List<String> featureIcons = [
    'assets/icon/resource.png',
    'assets/icon/advisor.png',
    'assets/icon/bus.png',
    'assets/icon/profile.png',
  ];

  // Pages for bottom navigation bar
  final List<Widget> _pages = [
    const HomeScreen(), // Index 0 (Home)
    const ResourceScreen(), // Index 1
    const AdvisorPage(), // Index 2
    const BusScheduleListScreen(), // Index 3
    const ProfileScreen(), // Index 4
  ];

  // Handle bottom navigation item tap
  void _onBottomNavigationBarItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      // Show home page layout only when index is 0, otherwise show selected page
      body:
          _currentIndex == 0
              ? _buildHomePage(context, screenWidth, screenHeight)
              : _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBarWidget(
        currentIndex: _currentIndex, // Pass the current index
        onTabChange: _onBottomNavigationBarItemTapped, // Handle tab changes
      ),
    );
  }

  // Custom layout for the Home page (index 0)
  Widget _buildHomePage(
    BuildContext context,
    double screenWidth,
    double screenHeight,
  ) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: const Text(
            'Home',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Top banner with welcome message
            Container(
              width: double.infinity,
              height: screenHeight * 0.22,
              decoration: const BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(35),
                  bottomRight: Radius.circular(35),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Center(
                    child: Container(
                      width: constraints.maxWidth * 0.9,
                      height: constraints.maxHeight * 0.85,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFEFE),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color.fromARGB(255, 112, 225, 167),
                          width: 5,
                        ),
                        image: const DecorationImage(
                          image: AssetImage(
                            'assets/images/utar_background.jpg',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Welcome text over background
                          Center(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.02,
                                vertical: screenHeight * 0.005,
                              ),
                              color: Colors.black.withOpacity(0.5),
                              child: Text(
                                'Welcome to eUTAR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth * 0.065,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Section title for features
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0, 12, 0, 0),
                child: Text(
                  'Features',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: screenWidth * 0.065, // Responsive font size
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // Grid view for feature cards (fixed height, no scroll)
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.05), // Responsive padding
              child: SizedBox(
                height:
                    screenHeight *
                    0.45, // Fixed height for the grid (adjust if needed)
                child: GridView.builder(
                  physics:
                      const NeverScrollableScrollPhysics(), // Disable scroll
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 cards per row
                    mainAxisSpacing:
                        screenHeight * 0.02, // Responsive vertical spacing
                    crossAxisSpacing:
                        screenWidth * 0.03, // Responsive horizontal spacing
                    childAspectRatio: 1, // Make cards more square
                  ),
                  itemCount: featureNames.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        _onBottomNavigationBarItemTapped(index + 1);
                      },
                      child: Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.asset(
                                featureIcons[index],
                                width: screenWidth * 0.16,
                                height: screenWidth * 0.16,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.02,
                              ),
                              child: Text(
                                featureNames[index],
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize:
                                      screenWidth *
                                      0.036, // Responsive font size
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
