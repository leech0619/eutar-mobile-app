import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../resource_sharing/screen/resource_screen.dart';
import '../authentication/screen/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

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

  final List<Widget> _pages = [
    const HomeScreen(),
    const ResourceScreen(),
    const AdvisorPage(),
    const BusPage(),
    const ProfileScreen(),
  ];

  void _onBottomNavigationBarItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentIndex == 0
          ? _buildHomePage(context)
          : _pages[_currentIndex],
      bottomNavigationBar: Container(
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
            selectedIndex: _currentIndex,
            onTabChange: _onBottomNavigationBarItemTapped,
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
      ),
    );
  }

  Widget _buildHomePage(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blueAccent,
          title: const Text(
            'Home',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
          centerTitle: true,
        ),
        body: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              width: double.infinity,
              height: 220,
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
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
                      height: 220 * 0.85,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFEFE),
                        borderRadius: BorderRadius.circular(30),
                        shape: BoxShape.rectangle,
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
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              color: Colors.black.withOpacity(0.5),
                              child: const Text(
                                'Welcome to eUTAR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
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
            const Align(
              alignment: AlignmentDirectional(-0.85, 0),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0, 30, 0, 0),
                child: Text(
                  'Features',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 5,
                  crossAxisSpacing: 5,
                ),
                itemCount: featureNames.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      _onBottomNavigationBarItemTapped(index + 1);
                    },
                    child: Card(
                      color: Colors.transparent,
                      elevation: 0,
                      child: Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.all(10),
                            fixedSize: const Size(180, 180),
                          ),
                          onPressed: () {
                            _onBottomNavigationBarItemTapped(index + 1);
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.asset(
                                  featureIcons[index],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Flexible(
                                child: Text(
                                  featureNames[index],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
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
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResourcePage extends StatelessWidget {
  const ResourcePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resource')),
      body: const Center(child: Text('Resource Sharing Page')),
    );
  }
}

class AdvisorPage extends StatelessWidget {
  const AdvisorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Advisor')),
      body: const Center(child: Text('Smart Academic Advisor Page')),
    );
  }
}

class BusPage extends StatelessWidget {
  const BusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bus')),
      body: const Center(child: Text('Bus Station Page')),
    );
  }
}