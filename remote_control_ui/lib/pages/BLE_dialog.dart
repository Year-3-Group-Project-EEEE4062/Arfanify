import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/material.dart';
import 'package:kumi_popup_window/kumi_popup_window.dart';

class AppBarBLE extends StatefulWidget {
  const AppBarBLE({super.key});

  @override
  State<AppBarBLE> createState() => _AppBarBLEState();
}

class _AppBarBLEState extends State<AppBarBLE> {
  List<BluetoothDevice> _connectedDevices = [];
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;

  @override
  void initState() {
    super.initState();

    FlutterBluePlus.systemDevices.then((devices) {
      _connectedDevices = devices;
      setState(() {});
    });

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      _scanResults = results;
      setState(() {});
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      _isScanning = state;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 20, right: 10),
      child: OutlinedButton(
        onPressed: () {
          BLEPopUp(context);
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

  KumiPopupWindow BLEPopUp(BuildContext context) {
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
          height: 500,
          width: 500,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10), color: Colors.white),
          child: Column(
            children: [
              BLEStatusRow(),
              MediumFoundRow(),
              BLEButtonsRow(context),
            ],
          ),
        );
      },
    );
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  String getConnectedLength() {
    int mediumCount = 0;

    if (_scanResults.isNotEmpty) {
      mediumCount = _scanResults
          .where((result) => result.device.platformName == 'Medium')
          .length;
    }

    return '$mediumCount';
  }

  Row MediumFoundRow() {
    return Row(
      children: [
        const SizedBox(width: 24),
        Text(
          getConnectedLength(), //call to get the amount of system device connected
          style: const TextStyle(color: Colors.black, fontSize: 20),
        ),
        const SizedBox(width: 15),
        const Text(
          'Medium Found',
          style: TextStyle(color: Colors.black, fontSize: 20),
        )
      ],
    );
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Future onScanPressed() async {
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      debugPrint("Start Scan Error $e");
    }
    setState(() {}); // force refresh of systemDevices
  }

  Future onStopPressed() async {
    try {
      FlutterBluePlus.stopScan();
    } catch (e) {
      debugPrint("Stop Scan Error $e");
    }
  }

  Row BLEButtonsRow(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 20),
        TextButton(
          style: TextButton.styleFrom(
            textStyle: Theme.of(context).textTheme.labelLarge,
          ),
          child: const Text('Refresh'),
          onPressed: () {
            setState(() {}); //refreshes the pop up window
          },
        ),
        TextButton(
          style: TextButton.styleFrom(
            textStyle: Theme.of(context).textTheme.labelLarge,
          ),
          child: const Text('Scan Devices'),
          onPressed: () {
            onScanPressed();
          },
        ),
      ],
    );
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Color connectionColor() {
    Color connectionIcon = const Color.fromARGB(255, 205, 64, 54);
    bool isMediumConnected =
        _connectedDevices.any((device) => device.platformName == 'Medium');

    if (isMediumConnected) {
      connectionIcon = const Color.fromARGB(255, 91, 206, 94);
    }

    return connectionIcon;
  }

  Row BLEStatusRow() {
    return Row(
      children: [
        SizedBox(width: 20),
        Icon(
          Icons.circle_sharp,
          size: 20,
          color: connectionColor(),
        ),
        const SizedBox(width: 10),
        const Text(
          'Connection',
          style: TextStyle(color: Colors.black, fontSize: 20),
        ),
      ],
    );
  }
}
