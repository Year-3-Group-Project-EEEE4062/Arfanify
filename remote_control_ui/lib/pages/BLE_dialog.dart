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
  List<BluetoothDevice> availableDevices = [];
  Color scanButton = const Color(0xff333333);
  bool scanningBLE = false;
  List<BluetoothDevice> devs = FlutterBluePlus.connectedDevices;
  bool scan = false;

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

  deviceCard(BluetoothDevice device, bool isConnected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: ListTile(
        tileColor: Color.fromARGB(255, 0, 0, 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        title: Text(device.localName),
        subtitle: Text(device.remoteId.str),
        trailing: SizedBox(
          width: 100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              isConnected
                  ? InkWell(
                      onTap: () {
                        //add something here later
                      },
                      child: Icon(Icons.wifi),
                    )
                  : const SizedBox(),
              const SizedBox(
                width: 10,
              ),
              InkWell(
                onTap: () async {
                  device.connectionState
                      .listen((BluetoothConnectionState state) async {
                    if (state == BluetoothConnectionState.disconnected) {
                      // typically, start a periodic timer that tries to periodically reconnect.
                      // Note: you must always re-discover services after disconnection!
                    }
                  });
                  isConnected
                      ? await device.disconnect()
                      : await device.connect(autoConnect: true);
                },
                child: Icon(
                    isConnected ? Icons.bluetooth_connected : Icons.bluetooth),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _dialogBuilder(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xff333333),
          insetPadding: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          child: Row(
            children: [
              Column(
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
                  Container(height: 200, color: Colors.black),
                  Row(
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          textStyle: Theme.of(context).textTheme.labelLarge,
                        ),
                        child: const Text('Scan Devices'),
                        onPressed: () {
                          checkBLE();
                        },
                      ),
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
                  )
                ],
              ),
            ],
          ),
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

  void startBLEscanning() {
    List<BluetoothDevice> devices = [];
    var subscription = FlutterBluePlus.scanResults.listen(
      (results) {
        for (ScanResult r in results) {
          if (r.device.platformName.isNotEmpty) {
            if (!devices.contains(r.device)) {
              devices.add(r.device);
            }
          }
        }
      },
    );

    subscription.onDone(() {});

    if (!FlutterBluePlus.isScanningNow) {
      setState(() {
        scan = true;
      });
      FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 5),
      );
      setState(() {
        scan = false;
      });
    }

    setState(() {
      availableDevices = devices;
    });
  }
}
