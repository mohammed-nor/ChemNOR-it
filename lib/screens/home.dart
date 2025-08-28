/// The main home page widget of the application, providing navigation between
/// Search, Chat, History, and Setting screens using a bottom navigation bar.
///
/// This widget is stateful and manages the currently selected tab index.
/// The `title` parameter is required and is used for configuration purposes.
///
/// The available pages are:
/// - [SearchWidget]: Search functionality
/// - [ChatWidget]: Chat interface
/// - [HistoryWidget]: View search/chat history
/// - [SettingPage]: Application settings
///
/// The bottom navigation bar allows switching between these pages.
import 'package:chemnor__it/screens/history.dart';
import 'package:chemnor__it/screens/search.dart';
import 'package:chemnor__it/screens/setting.dart';
import 'package:flutter/material.dart';

import 'chat.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //vars and methods here
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  static List<Widget> pages = <Widget>[SearchWidget(), ChatWidget(), HistoryWidget(), SettingPage()];
  int _bottomNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_bottomNavIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTap: (idx) {
          setState(() {
            _bottomNavIndex = idx;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color.fromARGB(255, 255, 245, 210),
        unselectedItemColor: Colors.white70,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        showUnselectedLabels: true,
        elevation: 12,
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
