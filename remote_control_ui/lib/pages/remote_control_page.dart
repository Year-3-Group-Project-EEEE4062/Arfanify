import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_xlider/flutter_xlider.dart';

class remoteControlPage extends StatefulWidget {
  @override
  _remoteControlState createState() => _remoteControlState();
}

class _remoteControlState extends State<remoteControlPage> {
  double _mode = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: bar(),
      body: Column(
        //mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          //modeSetter(),
          controlPad(),
        ],
      ),
    );
  }

  //////////////////////////////////////////////////////////////////////////////

  Container controlPad() {
    return Container(
      color: Colors.black,
      height: 190,
      width: 190,
      child: Column(
        children: [
          forward_button(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              left_button(),
              const SizedBox(
                width: 50,
              ),
              right_button(),
            ],
          ),
          backwards_button(),
        ],
      ),
    );
  }

  SizedBox forward_button() {
    return SizedBox(
      height: 70,
      width: 50,
      child: FloatingActionButton(
        backgroundColor: const Color(0xff545454),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(
          Icons.arrow_upward_outlined,
          size: 40,
        ),
        onPressed: () {
          if (kDebugMode) {
            debugPrint("Forward button pressed");
          }
        },
      ),
    );
  }

  SizedBox backwards_button() {
    return SizedBox(
      height: 70,
      width: 50,
      child: FloatingActionButton(
        backgroundColor: const Color(0xff545454),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(
          Icons.arrow_downward_outlined,
          size: 40,
        ),
        onPressed: () {
          if (kDebugMode) {
            debugPrint("Backwards button pressed");
          }
        },
      ),
    );
  }

  SizedBox right_button() {
    return SizedBox(
      height: 50,
      width: 70,
      child: FloatingActionButton(
        backgroundColor: const Color(0xff545454),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(
          Icons.arrow_forward_outlined,
          size: 40,
        ),
        onPressed: () {
          if (kDebugMode) {
            debugPrint("Right button pressed");
          }
        },
      ),
    );
  }

  SizedBox left_button() {
    return SizedBox(
      height: 50,
      width: 70,
      child: FloatingActionButton(
        backgroundColor: const Color(0xff545454),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(
          Icons.arrow_back_outlined,
          size: 40,
        ),
        onPressed: () {
          if (kDebugMode) {
            debugPrint("Left button pressed");
          }
        },
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
          fontSize: 25,
          fontWeight: FontWeight.w300,
          height: 1.8,
        ),
      ),
      iconTheme: const IconThemeData(size: 40, color: Colors.white),
      //alignment of the text in the app bar
      centerTitle: true,
      //set background colour of AppBar
      backgroundColor: Colors.black,
    );
  }
}
