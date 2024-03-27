import 'package:flutter/material.dart';
import 'package:remote_control_ui/pages/ble_PopUp.dart';
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
  final BLEcontroller myController = BLEcontroller();

  ////////////////////////variables
  int _selectedIndex = 0;
  late List<Widget> _pages;

  //update the selected index based on which page user wants to go to
  _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  _updateMediumBLE(String command) {
    //AppBarBLEState().sendDataBLE(command);
    myController.sendDataBLE(command);
  }

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(updateScaffoldBody: _onItemTapped),
      RemoteControlPage(bLE: _updateMediumBLE),
      const AutonomousPagee(),
      const CloudBackupPage(),
    ];
  }

  ////////////////////////Scaffold
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: bar(context),
      drawer: drawerPage(context),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  // DRAWER //
  Drawer drawerPage(BuildContext context) {
    return Drawer(
      width: 220,
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      child: ListView(
        padding: const EdgeInsets.all(0),
        children: <Widget>[
          drawerHeader(),
          const SizedBox(height: 5),
          homePageDrawer(context),
          const SizedBox(height: 5),
          remoteControlDrawer(context),
          const SizedBox(height: 5),
          autonomousDrawer(context),
          const SizedBox(height: 5),
          cloudBackupDrawer(context),
        ],
      ),
    );
  }

  DrawerHeader drawerHeader() {
    return DrawerHeader(
      decoration: const BoxDecoration(
        color: Color(0xff171717),
      ),
      //Container just acts as a filler so that Drawer Header has a child
      //if not, Drawer header not valid
      child: Container(
        alignment: Alignment.topLeft,
      ),
    );
  }

  ListTile homePageDrawer(BuildContext context) {
    return ListTile(
      selected: _selectedIndex == 0,
      selectedColor: const Color(0xff29A8AB),
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

  ListTile remoteControlDrawer(BuildContext context) {
    return ListTile(
      selected: _selectedIndex == 1,
      selectedColor: const Color(0xff29A8AB),
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

  ListTile autonomousDrawer(BuildContext context) {
    return ListTile(
      selected: _selectedIndex == 2,
      selectedColor: const Color(0xff29A8AB),
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

  ListTile cloudBackupDrawer(BuildContext context) {
    return ListTile(
      selected: _selectedIndex == 3,
      selectedColor: const Color(0xff29A8AB),
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

      actions: [AppBarBLE(controller: myController)],
      //adjust the bottom shape of the appbar
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(5))),
    );
  }
}