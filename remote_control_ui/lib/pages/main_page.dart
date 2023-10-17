import 'package:flutter/material.dart';
import 'package:remote_control_ui/pages/autonomous_page.dart';
import 'package:remote_control_ui/pages/cloud_backup_page.dart';
import 'package:remote_control_ui/pages/home_page.dart';
import 'package:remote_control_ui/pages/remote_control_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  final _category = [
    HomePage(),
    remoteControlPage(),
    AutonomousPage(),
    CloudBackupPage()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: bar(context),
      drawer: DrawerPage(context),
      body: _category[_selectedIndex],
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  Drawer DrawerPage(BuildContext context) {
    return Drawer(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      child: ListView(
        padding: const EdgeInsets.all(0),
        children: <Widget>[
          drawer_header(),
          const SizedBox(height: 5),
          home_page_drawer(context),
          const SizedBox(height: 5),
          remote_control_drawer(context),
          const SizedBox(height: 5),
          autonomous_drawer(context),
          const SizedBox(height: 5),
          cloud_backup_drawer(context)
        ],
      ),
    );
  }

  DrawerHeader drawer_header() {
    return DrawerHeader(
      decoration: BoxDecoration(
          color: const Color(0xff333333),
          borderRadius: BorderRadius.circular(10)),
      //Container just acts as a filler so that Drawer Header has a child
      //if not, Drawer header not valid
      child: Container(
        alignment: Alignment.topLeft,
      ),
    );
  }

  ListTile home_page_drawer(BuildContext context) {
    return ListTile(
      selected: _selectedIndex == 0,
      selectedColor: Color(0xff29A8AB),
      leading: const Icon(
        Icons.home,
      ),
      title: const Text(
        'Home',
        style: TextStyle(
          fontSize: 19,
        ),
      ),
      onTap: () {
        _onItemTapped(0);
        Navigator.pop(context);
      },
    );
  }

  ListTile remote_control_drawer(BuildContext context) {
    return ListTile(
      selected: _selectedIndex == 1,
      selectedColor: Color(0xff29A8AB),
      leading: const Icon(
        Icons.settings_remote_sharp,
      ),
      title: const Text(
        'Remote Control',
        style: TextStyle(
          fontSize: 19,
        ),
      ),
      onTap: () {
        _onItemTapped(1);
        Navigator.pop(context);
      },
    );
  }

  ListTile autonomous_drawer(BuildContext context) {
    return ListTile(
      selected: _selectedIndex == 2,
      selectedColor: Color(0xff29A8AB),
      leading: const Icon(
        Icons.map_outlined,
      ),
      title: const Text(
        'Autonomous',
        style: TextStyle(
          fontSize: 20,
        ),
      ),
      onTap: () {
        _onItemTapped(2);
        Navigator.pop(context);
      },
    );
  }

  ListTile cloud_backup_drawer(BuildContext context) {
    return ListTile(
      selected: _selectedIndex == 3,
      selectedColor: Color(0xff29A8AB),
      leading: const Icon(
        Icons.cloud_done,
      ),
      title: const Text(
        'Cloud Backup',
        style: TextStyle(
          fontSize: 20,
        ),
      ),
      onTap: () {
        _onItemTapped(3);
        Navigator.pop(context);
      },
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  AppBar bar(BuildContext context) {
    return AppBar(
      //adjust the size of the app bar
      toolbarHeight: 50,
      //styling of the text in the app bar
      title: const Text(
        'ARFANIFY',
        style: TextStyle(
          color: Colors.white,
          fontSize: 25,
          fontWeight: FontWeight.w300,
          height: 2.3,
        ),
      ),
      //resize the hamburger icon
      iconTheme: const IconThemeData(size: 45, color: Colors.white),
      //alignment of the text in the app bar
      centerTitle: true,
      //set background colour of AppBar
      backgroundColor: Colors.black,
      //adjust the bottom shape of the appbar
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(5))),
    );
  }
}
