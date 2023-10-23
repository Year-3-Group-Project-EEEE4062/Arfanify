import 'package:flutter/material.dart';
import 'package:remote_control_ui/pages/BLE_dialog.dart';
import 'package:remote_control_ui/pages/autonomous_page.dart';
import 'package:remote_control_ui/pages/cloud_backup_page.dart';
//import 'package:remote_control_ui/pages/home_page.dart';
import 'package:remote_control_ui/pages/remote_control_page.dart';
import 'package:remote_control_ui/pages/scan_screen.dart';

// HomePage integrated within MainPage

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  ////////////////////////variables
  int _selectedIndex = 0;
  final _category = [
    const MainPage(),
    remoteControlPage(),
    const AutonomousPage(),
    //const CloudBackupPage()
    const ScanScreen()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  ////////////////////////Scaffold
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBarBLE(),
        drawer: DrawerPage(context),
        body: (_selectedIndex == 0) ? HomePage() : _category[_selectedIndex]
        // body: _category[_selectedIndex]
        );
  }

  //////////////////////////////////////////////////////////////////////////////
  // HOMEPAGE //
  Center HomePage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          arfanifyIcon(),
          remoteControlButton(),
          autonomousButton(),
          cloudBackupButton(),
        ],
      ),
    );
  }

  Image arfanifyIcon() {
    return const Image(
      image: AssetImage('assets/icons/Arfanify.png'),
      width: 200,
      height: 200,
      color: Colors.white,
    );
  }

  Container remoteControlButton() {
    return Container(
      margin: const EdgeInsets.all(10),
      height: 100,
      width: 160,
      child: ElevatedButton(
        onPressed: () {
          // MainPage();
          _onItemTapped(1); // Use the variable within the print statement
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff333333),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.settings_remote_sharp,
                size: 60), // Adjust the size as needed
            Text(
              'Remote Control',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Container autonomousButton() {
    return Container(
      margin: const EdgeInsets.all(10),
      height: 100,
      width: 160,
      child: ElevatedButton(
        onPressed: () {
          _onItemTapped(2); // Use the variable within the print statement
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff333333),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.map_outlined, size: 60), // Adjust the size as needed
            Text(
              'Autonomous',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Container cloudBackupButton() {
    return Container(
      margin: const EdgeInsets.all(10),
      height: 100,
      width: 160,
      child: ElevatedButton(
        onPressed: () {
          _onItemTapped(3); // Use the variable within the print statement
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff333333),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.cloud_done, size: 60), // Adjust the size as needed
            Text(
              'Cloud Backup',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  // DRAWER //
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
          cloud_backup_drawer(context),
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
}
