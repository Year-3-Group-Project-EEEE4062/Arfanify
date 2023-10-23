import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/material.dart';

class BLEDialog extends StatefulWidget {
  const BLEDialog({super.key});

  @override
  State<BLEDialog> createState() => _BLEDialogState();
}

class _BLEDialogState extends State<BLEDialog> {
  Set<DeviceIdentifier> seen = {};
  Color scanButton = const Color(0xff333333);
  bool scanningBLE = false;
  List<BluetoothDevice> devs = FlutterBluePlus.connectedDevices;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 20, right: 10),
      //margin: const EdgeInsets.all(10),
      child: OutlinedButton(
        onPressed: () => _dialogBuilder(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          side: const BorderSide(color: Colors.white),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.circle_sharp,
              size: 20,
              //color: Color.fromARGB(255, 127, 208, 111),
              color: bleIconStateColor(),
            ), // Adjust the size as needed
            const SizedBox(width: 10), //add spacing between the icon and text
            const Text(
              'BLE',
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _dialogBuilder(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.circle_sharp,
                    size: 20,
                    color: bleIconStateColor(),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'BLE Devices Nearby',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              ),
            ],
          ),
          backgroundColor: const Color(0xff333333),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          actions: <Widget>[
            scanBLEButton(),
            const SizedBox(height: 10),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Color bleIconStateColor() {
    Color iconColor = const Color.fromARGB(255, 216, 72, 61);

    //check there is a device connected to the app, the status would turn green
    if (devs.isNotEmpty) {
      iconColor = const Color.fromARGB(255, 103, 219, 107);
    }

    return iconColor;
  }

  Container scanBLEButton() {
    return Container(
      margin: const EdgeInsets.all(10),
      child: IntrinsicWidth(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: scanButton,
            padding: EdgeInsets.zero,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            checkBLE();
          },
          child: const FittedBox(
            fit: BoxFit.contain,
            child: Icon(Icons.radar_sharp, size: 40),
          ),
        ),
      ),
    );
  }

  void checkBLE() async {
    // handle bluetooth on & off
    // note: for iOS the initial state is typically BluetoothAdapterState.unknown
    // note: if you have permissions issues you will get stuck at BluetoothAdapterState.unauthorized
    FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) async {
      if (state == BluetoothAdapterState.on) {
        // usually start scanning, connecting, etc
        debugPrint("Bluetooth is ON!");
        startBLEscanning();
      } else {
        debugPrint("Bluetooth problem encountered!!");
        // show an error to the user, etc

        // turn on bluetooth ourself if we can
        // for iOS, the user controls bluetooth enable/disable
        if (Platform.isAndroid) {
          FlutterBluePlus.turnOn();
        }
      }
    });
  }

  void startBLEscanning() async {
    int seconds = 0;
    FlutterBluePlus.scanResults.listen(
      (results) {
        for (ScanResult r in results) {
          if (seen.contains(r.device.remoteId) == false) {
            debugPrint("Found Something!!");
            debugPrint(
                '${r.device.remoteId}: "${r.advertisementData.localName}" found! rssi: ${r.rssi}');
            seen.add(r.device.remoteId);
          }
        }
      },
    );

    //when scanning, button is green in colour to let user know
    setState(() {
      scanButton = const Color.fromARGB(255, 127, 208, 111);
    });
    // Start scanning
    await FlutterBluePlus.startScan();

    //this is to enable scan for 5 seconds
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      seconds++;

      //if statement to check if 5 seconds has gone by
      if (seconds == 5) {
        timer.cancel(); // cancel the timer
        // Stop scanning
        await FlutterBluePlus.stopScan(); //stop the scan
        setState(() {
          scanButton = const Color(0xff333333); //change button colour
        });
      }
    });

    if (seen.isNotEmpty) debugPrint("Found Devices!!");
  }
}
