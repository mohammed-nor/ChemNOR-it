/// The main home page widget of the application, providing navigation between
/// Search, Chat, History, and Setting screens using a bottom navigation bar.
///
/// This widget is stateful and manages the currently selected tab index.
/// The `title` parameter is required and is used for configuration purposes.
///
/// The available pages are:
/// - [SearchWidget]: Search functionality for chemical compounds
/// - [ChatPage]: General chat interface for AI interaction
/// - [HistoryWidget]: View saved responses and search history
/// - [SettingPage]: Application settings management

// Import necessary screen widgets
import 'package:chemnor__it/screens/history.dart'; // History screen
import 'package:chemnor__it/screens/search.dart'; // Search screen
import 'package:chemnor__it/screens/setting.dart'; // Settings screen
import 'package:flutter/material.dart'; // Flutter UI components
import 'chat.dart'; // Chat screen

/// Main homepage widget that contains the navigation structure
class MyHomePage extends StatefulWidget {
  // Constructor requiring a title parameter
  const MyHomePage({super.key, required this.title});

  // Title for the home page - passed from parent widget
  final String title;

  @override
  // Create state for this widget
  State<MyHomePage> createState() => _MyHomePageState();
}

/// State class for the home page
class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    // TODO: implement initState - note: this TODO should be addressed
    super.initState();
    // Currently empty initialization
  }

  // List of all screens that can be navigated to
  static List<Widget> pages = <Widget>[
    SearchWidget(), // Index 0: Search screen
    ChatPage(), // Index 1: Chat screen
    HistoryWidget(), // Index 2: History screen
    SettingPage(), // Index 3: Settings screen
  ];

  // Track which tab is currently selected (0 = Search by default)
  int _bottomNavIndex = 0;

  @override
  // Build the UI for the home page
  Widget build(BuildContext context) {
    return Scaffold(
      // Main content area - shows the currently selected page
      body: pages[_bottomNavIndex],

      // Bottom navigation bar for switching between screens
      bottomNavigationBar: BottomNavigationBar(
        // Current selected tab
        currentIndex: _bottomNavIndex,

        // Handle tab selection
        onTap: (idx) {
          setState(() {
            _bottomNavIndex = idx; // Update selected tab index
          });
        },

        // Navigation bar styling and behavior
        type: BottomNavigationBarType.fixed, // Show all tabs equally
        selectedItemColor: const Color.fromARGB(255, 255, 245, 210), // Cream color for selected tab
        unselectedItemColor: Colors.white70, // Slightly translucent white for unselected tabs
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold), // Bold text for selected tab
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal), // Normal text for unselected tabs
        showUnselectedLabels: true, // Always show all tab labels
        elevation: 12, // Shadow depth for navigation bar
        // Navigation items - icons and labels for each screen
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.history_edu_rounded), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setting'),
        ],
      ),
    );
  }
}
