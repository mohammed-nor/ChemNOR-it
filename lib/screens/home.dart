import 'package:chemnor__it/screens/search2.dart';
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

  static List<Widget> pages = <Widget>[SearchWidget2(), ChatWidget(), SettingPage()];
  int _bottomNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter + Generative AI',
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(brightness: Brightness.dark, seedColor: const Color.fromARGB(255, 200, 171, 244))),
      home: Scaffold(
        body: pages[_bottomNavIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _bottomNavIndex,
          onTap: (idx) {
            setState(() {
              _bottomNavIndex = idx;
            });
          },
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setting'),
          ],
        ),
        appBar: AppBar(),
      ),
    );
  }
}
