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

import 'package:chemnor__it/screens/home.dart'; // Main home page with navigation
import 'package:chemnor__it/screens/settings_controller.dart'; // App settings management
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

  // Get reference to settings box for initial setup and controller
  final settingsBox = await Hive.openBox('settingBox');

  // Initialize default model if not set already
  if (!settingsBox.containsKey('selectedModel')) {
    await settingsBox.put('selectedModel', 'gemini1_5flash');
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
            // Use Material 3 design language
            useMaterial3: true,

            // Color scheme based on purple hue with dark mode
            colorScheme: ColorScheme.fromSeed(brightness: Brightness.dark, seedColor: const Color.fromARGB(255, 200, 171, 244)),

            // Apply font size scaling from settings to all text
            textTheme: Theme.of(context).textTheme.apply(
              // Scale font size based on user preference
              fontSizeFactor: settings.fontSize / 16.0,
              // Set text colors to white for both display and body text
              displayColor: Colors.white,
              bodyColor: Colors.white,
            ),
          ),

          // Set the home page to MyHomePage with a title
          home: const MyHomePage(title: 'ChemNOR it!'),
        );
      },
    );
  }
}
