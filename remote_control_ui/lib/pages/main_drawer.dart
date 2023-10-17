import 'package:flutter/material.dart';
import 'package:remote_control_ui/pages/autonomous_page.dart';
import 'package:remote_control_ui/pages/home_page.dart';
import 'package:remote_control_ui/pages/remote_control_page.dart';

class MainDrawer extends StatefulWidget {
  @override
  State<MainDrawer> createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> {
  int _selectedIndex = 0;
  //final _category = ['home', 'remoteControl', 'autonomous', 'cloudBackup'];
  final _category = [HomePage(), remoteControlPage(), AutonomousPage()];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xff545454),
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

  void checkIndex(int newIndex) {
    debugPrint('$newIndex , $_selectedIndex');
    if (_selectedIndex != newIndex) {
      //only change to new page when the index changes
      _onItemTapped(newIndex);
      Navigator.pop(context);
      //Navigator.pushReplacementNamed(context, '/${_category[_selectedIndex]}');
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (BuildContext context) => _category[_selectedIndex]));
    } else {
      Navigator.pop(context);
    }
    //else do nothing
  }

  ListTile home_page_drawer(BuildContext context) {
    return ListTile(
      leading: const Icon(
        Icons.home,
        color: Colors.white,
      ),
      title: const Text(
        'Home',
        style: TextStyle(
          color: Colors.white,
          fontSize: 19,
        ),
      ),
      onTap: () {
        checkIndex(0);
      },
    );
  }

  ListTile remote_control_drawer(BuildContext context) {
    return ListTile(
      selected: _selectedIndex == 1,
      leading: const Icon(
        Icons.settings_remote_sharp,
        color: Colors.white,
      ),
      title: const Text(
        'Remote Control',
        style: TextStyle(
          color: Colors.white,
          fontSize: 19,
        ),
      ),
      onTap: () {
        checkIndex(1);
      },
    );
  }

  ListTile autonomous_drawer(BuildContext context) {
    return ListTile(
      leading: const Icon(
        Icons.map_outlined,
        color: Colors.white,
      ),
      title: const Text(
        'Autonomous',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
        ),
      ),
      selected: _selectedIndex == 2,
      onTap: () {
        checkIndex(2);
      },
    );
  }

  ListTile cloud_backup_drawer(BuildContext context) {
    return ListTile(
      leading: const Icon(
        Icons.cloud_done,
        color: Colors.white,
      ),
      title: const Text(
        'Cloud Backup',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
        ),
      ),
      selected: _selectedIndex == 3,
      onTap: () {
        checkIndex(3);
      },
    );
  }
}
