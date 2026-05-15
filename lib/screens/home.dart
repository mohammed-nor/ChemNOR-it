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
import 'package:hive/hive.dart'; // For persistent flag storage
import 'package:url_launcher/url_launcher.dart';
import 'package:chemnor_it/main.dart'; // For settingsController
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
  // Track which tab is currently selected (0 = Search by default)
  int _bottomNavIndex = 0;

  // We remove the cached 'pages' list to ensure all widgets are recreated
  // and pick up the latest settings (font size, etc.) when the app rebuilds.

  @override
  void initState() {
    super.initState();
    // Show the API key guide unless the user previously dismissed it
    // by tapping "I already have a key" (persisted in Hive).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = Hive.box('settingBox');
      final alreadyDismissed =
          box.get('guideShown', defaultValue: false) as bool;
      if (!alreadyDismissed && settingsController.value.geminiApiKey.isEmpty) {
        _showApiKeyGuide();
      }
    });
  }

  /// Shows a modal bottom sheet guiding the user to get a free API key.
  void _showApiKeyGuide() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ApiKeyGuideSheet(
        onGoToSettings: () {
          Navigator.pop(ctx);
          setState(() => _bottomNavIndex = 3); // Jump to Settings tab
        },
        onDismissForever: () {
          // Persist the flag so the guide never shows again
          Hive.box('settingBox').put('guideShown', true);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  // Build the UI for the home page
  Widget build(BuildContext context) {
    // Generate the list of pages here so they pick up fresh settings on every build
    final pages = [
      SearchWidget(), // Index 0: Search screen
      ChatPage(), // Index 1: Chat screen
      HistoryWidget(), // Index 2: History screen
      SettingPage(), // Index 3: Settings screen
    ];

    return Scaffold(
      // Main content area - using IndexedStack to maintain page state
      body: IndexedStack(index: _bottomNavIndex, children: pages),

      // Bottom navigation bar
      bottomNavigationBar: NavigationBar(
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(fontSize: settingsController.value.fontSize - 2.0),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        selectedIndex: _bottomNavIndex,
        onDestinationSelected: (idx) {
          setState(() => _bottomNavIndex = idx);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            selectedIcon: Icon(Icons.search_rounded, color: Color(0xFF6366F1)),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(
              Icons.chat_bubble_rounded,
              color: Color(0xFF6366F1),
            ),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_edu_outlined),
            selectedIcon: Icon(
              Icons.history_edu_rounded,
              color: Color(0xFF6366F1),
            ),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(
              Icons.settings_rounded,
              color: Color(0xFF6366F1),
            ),
            label: 'Setting',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// API Key Guide Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ApiKeyGuideSheet extends StatelessWidget {
  final VoidCallback onGoToSettings;
  final VoidCallback onDismissForever;

  const _ApiKeyGuideSheet({
    required this.onGoToSettings,
    required this.onDismissForever,
  });

  @override
  Widget build(BuildContext context) {
    final baseFontSize = settingsController.value.fontSize;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Key icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6366F1).withOpacity(0.12),
              border: Border.all(
                color: const Color(0xFF6366F1).withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.vpn_key_rounded,
              color: Color(0xFF6366F1),
              size: 32,
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'One Step Before You Start',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: baseFontSize + 4.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            'ChemNOR uses Google\'s Gemini AI to search and analyse chemical '
            'compounds. You need a free API key from Google AI Studio — '
            'no credit card or payment required.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: baseFontSize - 2.0,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),

          // Step-by-step guide
          _buildStep(
            number: '1',
            title: 'Open Google AI Studio',
            subtitle: 'https://aistudio.google.com/app/api-keys',
            icon: Icons.open_in_browser_rounded,
          ),
          const SizedBox(height: 10),
          _buildStep(
            number: '2',
            title: 'Sign in & create an API key',
            subtitle: 'Uses your existing Google account — completely free',
            icon: Icons.add_circle_outline_rounded,
          ),
          const SizedBox(height: 10),
          _buildStep(
            number: '3',
            title: 'Paste the key in Settings',
            subtitle: 'Settings → API Key → paste and press Enter',
            icon: Icons.settings_rounded,
          ),
          const SizedBox(height: 28),

          // Primary button — open AI Studio
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => launchUrl(
                Uri.parse('https://aistudio.google.com/app/api-keys'),
                mode: LaunchMode.externalApplication,
              ),
              icon: Icon(Icons.open_in_new_rounded, size: baseFontSize + 2),
              label: Text(
                'Get My Free API Key',
                style: TextStyle(fontSize: baseFontSize - 2),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Secondary button — go to settings
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onGoToSettings,
              icon: Icon(Icons.settings_rounded, size: baseFontSize + 2),
              label: Text(
                'Go to Settings',
                style: TextStyle(fontSize: baseFontSize - 2),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: BorderSide(color: Colors.white.withOpacity(0.15)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Dismiss forever
          TextButton(
            onPressed: onDismissForever,
            child: Text(
              'I already have a key',
              style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: baseFontSize - 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required String number,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final baseFontSize = settingsController.value.fontSize;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Numbered circle
        Container(
          width: baseFontSize * 1.75,
          height: baseFontSize * 1.75,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF6366F1).withOpacity(0.15),
            border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.4)),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: const Color(0xFF818CF8),
                fontSize: baseFontSize - 3.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Step icon
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Icon(
            icon,
            size: baseFontSize,
            color: Colors.white.withOpacity(0.35),
          ),
        ),
        const SizedBox(width: 10),

        // Step text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: baseFontSize - 2.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: baseFontSize - 4.0,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
