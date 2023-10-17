import 'package:flutter/material.dart';
import 'package:remote_control_ui/pages/main_drawer.dart';

class AutonomousPage extends StatelessWidget {
  const AutonomousPage({super.key});

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
            Icons.map_outlined,
            color: Colors.white,
            size: 200,
          ),
        ],
      ),
      drawer: MainDrawer(),
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  AppBar bar() {
    return AppBar(
      //adjust the size of the app bar
      toolbarHeight: 50,
      //styling of the text in the app bar
      title: const Text(
        'Autonomous',
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
