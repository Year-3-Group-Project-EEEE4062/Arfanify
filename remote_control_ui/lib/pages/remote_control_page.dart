import 'package:flutter/material.dart';

class remote_control_page extends StatelessWidget {
  const remote_control_page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: bar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Container()],
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
      'Remote Control',
      style: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w300,
      ),
    ),
    //alignment of the text in the app bar
    centerTitle: true,
    //set background colour of AppBar
    backgroundColor: Colors.blueGrey,
    //adjust the bottom shape of the appbar
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(5))),
  );
}
