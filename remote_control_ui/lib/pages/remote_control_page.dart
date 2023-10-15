import 'dart:math';

import 'package:flutter/material.dart';

class remote_control_page extends StatelessWidget {
  const remote_control_page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: bar(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          forward_button(),
          backwards_button(),
          right_button(),
          left_button(),
        ],
      ),
    );
  }
}

SizedBox forward_button() {
  return SizedBox(
    height: 70,
    width: 50,
    child: FloatingActionButton(
      backgroundColor: Colors.grey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: const Icon(
        Icons.arrow_upward_outlined,
        size: 40,
      ),
      onPressed: () {},
    ),
  );
}

SizedBox backwards_button() {
  return SizedBox(
    height: 70,
    width: 50,
    child: FloatingActionButton(
      backgroundColor: Colors.grey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: const Icon(
        Icons.arrow_downward_outlined,
        size: 40,
      ),
      onPressed: () {},
    ),
  );
}

SizedBox right_button() {
  return SizedBox(
    height: 50,
    width: 70,
    child: FloatingActionButton(
      backgroundColor: Colors.grey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: const Icon(
        Icons.arrow_forward_outlined,
        size: 40,
      ),
      onPressed: () {},
    ),
  );
}

SizedBox left_button() {
  return SizedBox(
    height: 50,
    width: 70,
    child: FloatingActionButton(
      backgroundColor: Colors.grey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: const Icon(
        Icons.arrow_back_outlined,
        size: 40,
      ),
      onPressed: () {},
    ),
  );
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
    backgroundColor: Colors.black,
  );
}
