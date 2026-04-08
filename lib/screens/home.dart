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
library;

// Import necessary screen widgets
import 'package:chemnor_it/screens/history.dart'; // History screen
import 'package:chemnor_it/screens/search.dart'; // Search screen
import 'package:chemnor_it/screens/setting.dart'; // Settings screen
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
      bottomNavigationBar: NavigationBar(
        // Navigation bar appearance
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        selectedIndex: _bottomNavIndex,
        
        // Handle tab selection
        onDestinationSelected: (idx) {
          setState(() {
            _bottomNavIndex = idx; // Update selected tab index
          });
        },

        // Navigation destinations
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            selectedIcon: Icon(Icons.search_rounded, color: Color(0xFF6366F1)),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded, color: Color(0xFF6366F1)),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_edu_outlined),
            selectedIcon: Icon(Icons.history_edu_rounded, color: Color(0xFF6366F1)),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded, color: Color(0xFF6366F1)),
            label: 'Setting',
          ),
        ],
      ),
    );
  }
}
