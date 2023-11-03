import 'dart:async';
import 'dart:convert';
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
  //These values must be able to be updated on the go
  ValueNotifier<Color> connectionColor =
      ValueNotifier<Color>(const Color.fromARGB(255, 224, 80, 70));
  ValueNotifier<String> actionMssg = ValueNotifier<String>('Idle');

  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;

  List<ScanResult> _scanResults = [];
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;

  bool _isScanning = false;
  late StreamSubscription<bool> _isScanningSubscription;

  List<BluetoothService> _services = [];

  //Medium remote ID for comparison when finding Medium
  //Might vary for different Mediums
  final List<DeviceIdentifier> mediumId = [
    const DeviceIdentifier('3C:E9:0E:83:A6:3E'),
    const DeviceIdentifier('0C:B8:15:F2:C9:36')
  ];

  //to store the Medium found
  late BluetoothDevice mediumDevice;

  //indicator if a medium has been found
  //ValueNotifier<bool> mediumFound = ValueNotifier<bool>(false);
  bool mediumFound = false;
  bool mediumConnected = false;

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
      mediumFound = false; //reset back to medium not found
      mediumConnected = false;
      return false;
    }
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //initializer
  @override
  void initState() {
    super.initState();

    //check if Bluetooth is ON or OFF
    _adapterStateStateSubscription =
        FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      _adapterState = state; //assign the state variable
      checkAdapterState(); //check what is the current BLE state and act accordingly
      setState(() {});
    });

    // Setup Listener for scan results
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen(
      (results) async {
        for (ScanResult r in results) {
          //check if detected device has already been detected before
          if (_scanResults.contains(r) == false) {
            //check if it is a valid Medium remote ID or has a Medium name
            if (mediumId.contains(r.device.remoteId) == true) {
              //Print detected onto console for debugging purpose
              debugPrint(r.advertisementData.localName);
              debugPrint('${r.device.remoteId}');

              //medium detected and add to list
              _scanResults.add(r);

              //show user in context box that medium detected
              editActionMssg("Medium Detected!");

              //assign the device to mediumDevice for later connection
              mediumDevice = r.device;

              //change bool variable keeping track of whether medium has been found or not
              mediumFound = true;
            }
          }
        }
        setState(() {});
      },
    );

    //Listener for if the BLE scan is on or not
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //dispose when pop-up closed
  @override
  void dispose() {
    //dispose listener for device bluetooth state
    _adapterStateStateSubscription.cancel();

    //dispose listener for scan results
    _scanResultsSubscription.cancel();

    super.dispose();
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //building a widget
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 20, right: 10),
      child: OutlinedButton(
        onPressed: () {
          blePopUp(context);
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

  KumiPopupWindow blePopUp(BuildContext context) {
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
          height: 350,
          width: 265,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10), color: Colors.white),
          child: Column(
            children: [
              const SizedBox(height: 10), //add space between each of them
              Row(
                children: [
                  //show connection status to Medium
                  bleStatusRow(context),

                  //allow user to test connection if connected
                  //if not connected ContextBox would alert the user
                  bleTestButton(context),
                ],
              ),
              const SizedBox(height: 10),
              contextBox(
                  context), //show user what is currently happening in BLE
              const SizedBox(height: 10),
              Column(
                //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  //allow user to Scan and Connect to Medium if necessary
                  bleScanButton(context),
                  bleConnectButton(context),
                  bleDisconnectButton(context),
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
  Row bleStatusRow(BuildContext context) {
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

  Row contextBox(BuildContext context) {
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
  Future<void> disconnectToMedium() async {
    if (mediumConnected) {
      // Connect to the device
      await mediumDevice.disconnect();
    }
  }

  Row bleDisconnectButton(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 18),
        TextButton(
          style: TextButton.styleFrom(
            textStyle: Theme.of(context).textTheme.labelLarge,
          ),
          child: const Text(
            'Disconnect',
            style: TextStyle(fontSize: 20),
          ),
          onPressed: () async {
            //only do something if bluetooth ON and working
            if (checkAdapterState()) {
              disconnectToMedium();
            }
          },
        ),
      ],
    );
  }

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Future<void> connectToMedium() async {
    if (mediumFound && !mediumConnected) {
      // Connect to the device
      await mediumDevice.connect();

      // listen for disconnection
      mediumDevice.connectionState
          .listen((BluetoothConnectionState state) async {
        if (state == BluetoothConnectionState.connected) {
          //connected change the icon color to green
          connectionColor.value = const Color.fromARGB(255, 128, 232, 80);

          //set that Medium has been found
          mediumConnected = true;

          // Very important!
          //request the maxium transmission unit (MTU) of 512 bytes
          if (Platform.isAndroid) {
            await mediumDevice.requestMtu(512);
          }

          //Discover the services of the Medium
          _services = await mediumDevice.discoverServices();

          //Read the characteristic in the 3rd service (the one i defined in Medium)
          var characteristics = _services[2].characteristics;
          //access the values stored in the characteristic
          for (BluetoothCharacteristic c in characteristics) {
            if (c.properties.read) {
              //read the characteristic message
              List<int> value = await c.read();

              //make it human readable instead of list of integers
              String data = utf8.decode(value);

              //debug printing of what characteristic is read
              debugPrint(data);
            }
          }

          debugPrint('${_services.length}');

          //for debugging purpose to know if Medium connected or not
          debugPrint("Medium Connected!");
        } else if (state == BluetoothConnectionState.disconnected) {
          //change the connection color to red
          connectionColor.value = const Color.fromARGB(255, 224, 80, 70);
          _services.clear(); //must rediscover services after disconnection
          mediumConnected = false;
          debugPrint("Medium Disconnected!");
        }
      });
    }
  }

  Row bleConnectButton(BuildContext context) {
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
          onPressed: () async {
            //only do the scanning and connecting if bluetooth ON and working
            if (checkAdapterState()) {
              connectToMedium();
            }
          },
        ),
      ],
    );
  }

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  Future<void> onScanPressed() async {
    //only do the scanning if the Medium is not found
    if (!mediumFound) {
      try {
        await FlutterBluePlus.startScan(timeout: const Duration(seconds: 1));
      } catch (e) {
        debugPrint('$e');
      }
      setState(() {
        editActionMssg("Scanning!");
      }); // force refresh of systemDevices
    }
  }

  Row bleScanButton(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 16),
        TextButton(
          style: TextButton.styleFrom(
            textStyle: Theme.of(context).textTheme.labelLarge,
          ),
          child: const Text(
            'Scan',
            style: TextStyle(fontSize: 20),
          ),
          onPressed: () async {
            //only do the scanning and connecting if bluetooth ON and working
            if (checkAdapterState()) {
              onScanPressed();
            }
          },
        ),
      ],
    );
  }

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //displaying of this button depends on checkConnection()
  Row bleTestButton(BuildContext context) {
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
