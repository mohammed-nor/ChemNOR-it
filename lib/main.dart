/// The entry point of the ChemNOR app.
/// 
/// Initializes Flutter bindings, sets up Hive for local storage, and opens
/// required Hive boxes for settings and history. Instantiates the global
/// [SettingsController] with the settings box, then runs the app.
///
/// The [MyApp] widget uses a [ValueListenableBuilder] to listen for changes
/// in [AppSettings] via the [settingsController], updating the app's theme
/// and text scaling accordingly.
///
/// The app uses Material 3 design, a custom color scheme, and disables the
/// debug banner. The home screen is set to [MyHomePage].
import 'package:chemnor__it/screens/home.dart';
import 'package:chemnor__it/screens/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:path_provider/path_provider.dart';

late final SettingsController settingsController;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);
  await Hive.openBox('settingBox');
  await Hive.openBox<String>('historyBox');
  final settingBox = Hive.box('settingBox');
  settingsController = SettingsController(settingBox);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSettings>(
      valueListenable: settingsController,
      builder: (context, settings, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Flutter + Generative AI',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(brightness: Brightness.dark, seedColor: const Color.fromARGB(255, 200, 171, 244)),
            textTheme: Theme.of(context).textTheme.apply(fontSizeFactor: settings.fontSize / 16.0, displayColor: Colors.white, bodyColor: Colors.white),
          ),
          home: const MyHomePage(title: 'ChemNOR it!'),
        );
      },
    );
  }
}
