/// The entry point of the ChemNOR app.
///
/// This file initializes the application, sets up storage, configures themes,
/// and launches the main app widget. It serves as the foundation for all
/// other components of the ChemNOR chemistry application.
///
/// The [MyApp] widget uses a [ValueListenableBuilder] to listen for changes
/// in [AppSettings] via the [settingsController], updating the app's theme
/// and text scaling accordingly.
///
/// The app uses Material 3 design, a custom color scheme, and disables the
/// debug banner. The home screen is set to [MyHomePage].
library;

import 'package:chemnor_it/screens/home.dart'; // Main home page with navigation
import 'package:chemnor_it/screens/settings_controller.dart'; // App settings management
import 'package:flutter/material.dart'; // Core Flutter framework
import 'package:hive_flutter/adapters.dart'; // Persistent storage with Hive
import 'package:path_provider/path_provider.dart'; // Access to app directory for storage

// Global settings controller accessible throughout the app
late final SettingsController settingsController;

/// Main entry point function
void main() async {
  // Ensure Flutter is initialized before calling platform channels
  WidgetsFlutterBinding.ensureInitialized();

  // Get app's document directory for storing Hive boxes
  final appDocumentDir = await getApplicationDocumentsDirectory();

  // Initialize Hive for Flutter with the document directory path
  await Hive.initFlutter(appDocumentDir.path);

  // Open 'settingBox' for app preferences (without type - will be dynamic)
  await Hive.openBox('settingBox');

  // Open 'historyBox' specifically for storing String messages from chat history
  await Hive.openBox<String>('historyBox');

  // Open 'chatBox' for storing the general chat message history
  await Hive.openBox('chatBox');

  // Get reference to settings box for initial setup and controller
  final settingsBox = await Hive.openBox('settingBox');

  // Initialize default model if not set already
  if (!settingsBox.containsKey('selectedModel')) {
    await settingsBox.put('selectedModel', 'gemini3_0flash');
  }

  // Create the settings controller with the settings box
  settingsController = SettingsController(settingsBox);
  // Launch the app with MyApp as the root widget
  runApp(MyApp());
}

/// Root application widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use ValueListenableBuilder to rebuild UI when settings change
    return ValueListenableBuilder<AppSettings>(
      // Listen to changes in the settings controller
      valueListenable: settingsController,
      // Build the MaterialApp with current settings
      builder: (context, settings, _) {
        return MaterialApp(
          // Remove the debug banner from the corner
          debugShowCheckedModeBanner: false,

          // App title shown in task switchers and OS interfaces
          title: 'ChemNOR It!',

          // Theme configuration
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,

            // Custom color scheme for a premium scientific look
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6366F1), // Indigo primary
              brightness: Brightness.dark,
              surface: const Color(0xFF0F172A), // Deep slate surface
              background: const Color(0xFF020617), // Near-black background
            ),

            // Scaffold background color
            scaffoldBackgroundColor: const Color(0xFF020617),

            // Card theme for consistent material elevations
            cardTheme: CardThemeData(
              color: const Color(0xFF1E293B),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.05),
                  width: 1,
                ),
              ),
            ),

            // Input decoration theme for glassmorphism-like fields
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF6366F1),
                  width: 2,
                ),
              ),
            ),

            // Elevated button theme
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),

            // NOTE: textTheme font scaling is intentionally NOT applied here.
            // Typography.material2021() has null fontSize on several styles,
            // which causes a crash when fontSizeFactor != 1.0.
            // Font size is already applied per-widget via settingsController.value.fontSize.
          ),

          // Set the home page to MyHomePage with a title
          home: const MyHomePage(title: 'ChemNOR it!'),
        );
      },
    );
  }
}
