//import packages
// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:remote_control_ui/pages/remote_control_page.dart';

class homePage extends StatelessWidget {
  const homePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: bar(),
      body: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Icon(
            Icons.directions_boat_filled,
            color: Colors.white,
            size: 200,
          )
        ],
      ),
      drawer: Drawer(
        backgroundColor: Color(0xff0C1222),
        child: ListView(
          padding: const EdgeInsets.all(0),
          children: <Widget>[
            drawer_header(),
            remote_control_drawer(context),
            autonomous_drawer(),
            cloud_backup_drawer()
          ],
        ),
      ),
    );
  }
}

AppBar bar() {
  return AppBar(
    //adjust the size of the app bar
    toolbarHeight: 50,
    //styling of the text in the app bar
    title: const Text(
      'Home',
      style: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w300,
      ),
    ),
    //alignment of the text in the app bar
    centerTitle: true,
    //set background colour of AppBar
    backgroundColor: Colors.black,
    //adjust the bottom shape of the appbar
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(5))),
  );
}

DrawerHeader drawer_header() {
  return DrawerHeader(
    decoration: BoxDecoration(
        color: Color(0xffEEEEEE), borderRadius: BorderRadius.circular(10)),
    //Container just acts as a filler so that Drawer Header has a child
    //if not, Drawer header not valid
    child: Container(
      alignment: Alignment.topLeft,
    ),
  );
}

ListTile remote_control_drawer(BuildContext context) {
  return ListTile(
    leading: Icon(
      Icons.settings_remote_sharp,
      color: Colors.white,
    ),
    title: Text(
      'Remote Control',
      style: TextStyle(
        color: Colors.white,
        fontSize: 19,
      ),
    ),
    onTap: () {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => remote_control_page()));
    },
  );
}

ListTile autonomous_drawer() {
  return const ListTile(
    leading: Icon(
      Icons.map_outlined,
      color: Colors.white,
    ),
    title: Text(
      'Autonomous',
      style: TextStyle(
        color: Colors.white,
        fontSize: 20,
      ),
    ),
  );
}

ListTile cloud_backup_drawer() {
  return const ListTile(
    leading: Icon(
      Icons.cloud_done,
      color: Colors.white,
    ),
    title: Text(
      'Cloud Backup',
      style: TextStyle(
        color: Colors.white,
        fontSize: 20,
      ),
    ),
  );
}
