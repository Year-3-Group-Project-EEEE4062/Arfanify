import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/material.dart';
import 'package:kumi_popup_window/kumi_popup_window.dart';

class AppBarBLE extends StatefulWidget {
  const AppBarBLE({super.key});

  @override
  State<AppBarBLE> createState() => _AppBarBLEState();
}

class _AppBarBLEState extends State<AppBarBLE> {
  //These values must be able to be updated on the go
  ValueNotifier<Color> connectionColor =
      ValueNotifier<Color>(const Color.fromARGB(255, 224, 80, 70));
  ValueNotifier<String> actionMssg = ValueNotifier<String>('Idle');

  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;

  List<ScanResult> _scanResults = [];
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;

  bool mediumFound = false;

  //Medium remote ID for comparison when finding Medium
  //Might vary for different Mediums
  DeviceIdentifier mediumId = const DeviceIdentifier('3C:E9:0E:83:A6:3E');
  late BluetoothDevice mediumDevice;

  bool checkAdapterState() {
    if (_adapterState == BluetoothAdapterState.on) {
      //this pass means bluetooth is ON
      return true;
    } else {
      if (_adapterState == BluetoothAdapterState.unauthorized) {
        debugPrint("User declined Bluetooth permissions");
        editActionMssg("Check Permissions!");
      } else if (_adapterState == BluetoothAdapterState.off) {
        debugPrint("User Bluetooth is off");
        editActionMssg("Bluetooth OFF!");
      } else {
        debugPrint("User has other issue with their Bluetooth");
        editActionMssg("Unknown Error!");
      }
      _scanResults.clear(); //reset scan as Bluetooth state changes
      mediumFound = false; //reset to having user to find Medium again
      return false;
    }
  }

  void connectToMedium() async {
    // listen for disconnection
    mediumDevice.connectionState.listen((BluetoothConnectionState state) async {
      if (state == BluetoothConnectionState.connected) {
        //connected change the icon color to green
        connectionColor.value = const Color.fromARGB(255, 128, 232, 80);
        debugPrint("Medium Connected!");
      } else if (state == BluetoothConnectionState.disconnected) {
        // 1. typically, start a periodic timer that tries to
        //    periodically reconnect, or just call connect() again right now
        // 2. you must always re-discover services after disconnection!

        //change the connection color to red
        connectionColor.value = const Color.fromARGB(255, 224, 80, 70);
      }
    });

    // Connect to the device
    await mediumDevice.connect();
  }

  //initializer
  @override
  void initState() {
    super.initState();

    //check if Bluetooth is ON or OFF
    _adapterStateStateSubscription =
        FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      _adapterState = state; //assign the state variable
      checkAdapterState();
      setState(() {});
    });

    // Setup Listener for scan results
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen(
      (results) async {
        for (ScanResult r in results) {
          if (_scanResults.contains(r) == false) {
            if (r.device.remoteId == mediumId) {
              debugPrint(r.advertisementData.localName);
              _scanResults.add(r);
              editActionMssg("Medium Detected!");
              mediumDevice = r.device;
              connectToMedium();
              mediumFound = true;
            }
          }
        }
        setState(() {});
      },
    );
  }

  //dispose when pop-up closed
  @override
  void dispose() {
    //dispose listener for device bluetooth state
    _adapterStateStateSubscription.cancel();

    //dispose listener for scan results
    _scanResultsSubscription.cancel();

    super.dispose();
  }

  //building a widget
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
          height: 250,
          width: 265,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10), color: Colors.white),
          child: Column(
            children: [
              const SizedBox(height: 10), //add space between each of them
              Row(
                children: [
                  //show connection status to Medium
                  BLEStatusRow(context),

                  //allow user to test connection if connected
                  //if not connected ContextBox would alert the user
                  BLETestButton(context),
                ],
              ),
              const SizedBox(height: 10),
              ContextBox(
                  context), //show user what is currently happening in BLE
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //allow user to Scan and Connect to Medium if necessary
                  BLEScanButton(context),

                  //allow user to connect to the Medium Found
                  //BLEConnectButton(context),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Row BLEStatusRow(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 20),
        ValueListenableBuilder(
            valueListenable: connectionColor,
            builder: (context, value, _) {
              return Icon(
                Icons.circle_sharp,
                size: 20,
                color: connectionColor.value,
              );
            }),
        const SizedBox(width: 10),
        const Text(
          'Connection',
          style: TextStyle(color: Colors.black, fontSize: 20),
        ),
      ],
    );
  }

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  void editActionMssg(String newMssg) {
    actionMssg.value = newMssg;
  }

  Row ContextBox(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 24),
        Container(
            height: 100,
            width: 200,
            decoration: BoxDecoration(
                color: const Color.fromARGB(255, 197, 196, 196),
                borderRadius: BorderRadius.circular(10)),
            child: Center(
              child: ValueListenableBuilder(
                  valueListenable: actionMssg,
                  builder: (context, value, _) {
                    return Text(actionMssg.value,
                        style:
                            const TextStyle(color: Colors.black, fontSize: 20));
                  }),
            ))
      ],
    );
  }

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Future onScanPressed() async {
    //check if device bluetooth on or not
    if (checkAdapterState()) {
      if (!mediumFound) {
        try {
          await FlutterBluePlus.startScan(timeout: const Duration(seconds: 1));
        } catch (e) {
          debugPrint('$e');
        }
        setState(() {
          editActionMssg("Scanning!");
        }); // force refresh of systemDevices
      } else {
        editActionMssg("Already found!");
      }
    }
  }

  Row BLEScanButton(BuildContext context) {
    return Row(
      children: [
        //const SizedBox(width: 18),
        TextButton(
          style: TextButton.styleFrom(
            textStyle: Theme.of(context).textTheme.labelLarge,
          ),
          child: const Text(
            'Scan & Connect',
            style: TextStyle(fontSize: 20),
          ),
          onPressed: () {
            onScanPressed();
          },
        ),
      ],
    );
  }

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Row BLEConnectButton(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 18),
        TextButton(
          style: TextButton.styleFrom(
            textStyle: Theme.of(context).textTheme.labelLarge,
          ),
          child: const Text(
            'Connect',
            style: TextStyle(fontSize: 20),
          ),
          onPressed: () {},
        ),
      ],
    );
  }

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //displaying of this button depends on checkConnection()
  Row BLETestButton(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 14),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            textStyle: Theme.of(context).textTheme.labelLarge,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            side: const BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
          ),
          child: const Text(
            'Test',
            style: TextStyle(fontSize: 20),
          ),
          onPressed: () {},
        ),
      ],
    );
  }
}
