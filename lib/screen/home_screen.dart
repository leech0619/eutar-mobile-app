import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _onBottomNavigationBarItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  final List<Widget> _pages = [
    const HomePageWidget(),
    const ResourcePage(),
    const AdvisorPage(),
    const BusPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
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
            padding: EdgeInsets.all(16),
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
}

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({Key? key}) : super(key: key);

  @override
  _HomePageWidgetState createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _unfocusNode = FocusNode();
  List<String> names = [
    'Resource Sharing',
    'Smart Academic Advisor Chatbot',
    'Bus Station Marker',
    'Profile',
  ];

  List<Widget> routes = [
    const ResourcePage(),
    const AdvisorPage(),
    const BusPage(),
    const ProfilePage(),
  ];

  final List<String> _listItem = [
    'assets/icon/resource.png',
    'assets/icon/advisor.png',
    'assets/icon/bus.png',
    'assets/icon/profile.png',
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          backgroundColor: Colors.blueAccent,
          title: const Text(
            'Home',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ), // Changed text color and font size
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).requestFocus(_unfocusNode),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
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
                          color: Color(0xFFFFFEFE),
                          borderRadius: BorderRadius.circular(30),
                          shape: BoxShape.rectangle,
                          border: Border.all(
                            color: Color.fromARGB(255, 112, 225, 167),
                            width: 5,
                          ),
                          image: DecorationImage(
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
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                color: Colors.black.withValues(
                                  alpha: 0.5,
                                ), // Semi-transparent background
                                child: Text(
                                  'Welcome to eUTAR',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28, // Increased font size
                                    fontWeight:
                                        FontWeight.bold, // Made text bold
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
                      fontSize: 26, // Increased font size
                      fontWeight: FontWeight.bold,
                    ), // Made text bold
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(
                child: GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  mainAxisSpacing: 5, // Reduced gap between buttons
                  crossAxisSpacing: 5, // Reduced gap between buttons
                  children: List.generate(4, (index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => routes[index],
                          ),
                        );
                      },
                      child: Card(
                        color: Colors.transparent,
                        elevation: 0,
                        child: Center(
                          // Center the button within the card
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.blueGrey, // Match the theme color
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: EdgeInsets.all(10),
                              fixedSize: Size(
                                180,
                                180,
                              ), // Increased button size
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => routes[index],
                                ),
                              );
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.asset(
                                    _listItem[index],
                                    width: 100, // Increased image size
                                    height: 100, // Increased image size
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Flexible(
                                  child: Text(
                                    names[index],
                                    style: TextStyle(
                                      color:
                                          Colors.white, // Match the text color
                                      fontSize: 18, // Adjusted font size
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2, // Allow text to have two rows
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
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
      body: Center(child: Text('Resource Sharing Page')),
    );
  }
}

class AdvisorPage extends StatelessWidget {
  const AdvisorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Advisor')),
      body: Center(child: Text('Smart Academic Advisor Page')),
    );
  }
}

class BusPage extends StatelessWidget {
  const BusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bus')),
      body: Center(child: Text('Bus Station Page')),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(child: Text('Profile Page')),
    );
  }
}
