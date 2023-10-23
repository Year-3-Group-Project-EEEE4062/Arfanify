import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/material.dart';
import 'package:kumi_popup_window/kumi_popup_window.dart';

//////////////////////////////////////////////////////////////////////////////
// BLE Status //
class AppBarBLE extends StatefulWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => Size.fromHeight(AppBar().preferredSize.height);

  @override
  State<AppBarBLE> createState() => _AppBarBLEState();
}

class _AppBarBLEState extends State<AppBarBLE> {
  List<BluetoothDevice> availableDevices = [];
  Color scanButton = const Color(0xff333333);
  bool scanningBLE = false;
  bool _isConnected = false;
  List<BluetoothDevice> _connectedDevices = [];

  @override
  void initState() {
    super.initState();

    FlutterBluePlus.systemDevices.then((devices) {
      _connectedDevices = devices;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
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

      actions: [statusBLE()],
      //adjust the bottom shape of the appbar
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(5))),
    );
  }

  Container statusBLE() {
    return Container(
      padding: const EdgeInsets.only(top: 20, right: 10),
      child: OutlinedButton(
        onPressed: () {
          BLEPopUp();
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          side: const BorderSide(color: Colors.white),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'BLE',
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }

  KumiPopupWindow BLEPopUp() {
    return showPopupWindow(
      context,
      gravity: KumiPopupGravity.rightTop,
      //curve: Curves.elasticOut,
      //bgColor: Colors.grey.withOpacity(0.5),
      clickOutDismiss: true,
      clickBackDismiss: true,
      customAnimation: false,
      customPop: false,
      customPage: false,
      //targetRenderBox: (btnKey.currentContext.findRenderObject() as RenderBox),
      needSafeDisplay: true,
      underStatusBar: false,
      underAppBar: true,
      offsetX: 0,
      offsetY: 0,
      duration: const Duration(milliseconds: 200),
      childFun: (pop) {
        return Container(
          key: GlobalKey(),
          padding: const EdgeInsets.all(10),
          height: 100,
          width: 500,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10), color: Colors.white),
          child: Row(
            children: [
              Icon(
                Icons.circle_sharp,
                size: 20,
                color: const Color.fromARGB(255, 100, 210, 103),
              ),
              const SizedBox(width: 10),
              const Text(
                'Connection',
                style: TextStyle(color: Colors.black, fontSize: 20),
              ),
            ],
          ),
        );
      },
    );
  }
}
