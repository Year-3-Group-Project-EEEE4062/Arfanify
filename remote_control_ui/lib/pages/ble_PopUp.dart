import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/material.dart';
import 'package:kumi_popup_window/kumi_popup_window.dart';

//controller for the BLE
class BLEcontroller {
  late void Function(String) sendDataBLE;
}

//Widget for BLE
class AppBarBLE extends StatefulWidget {
  final BLEcontroller controller;

  const AppBarBLE({super.key, required this.controller});

  @override
  State<AppBarBLE> createState() => AppBarBLEState(controller);
}

//a public class so that main_page.dart can call the sendDataBLE function only
class AppBarBLEState extends State<AppBarBLE> {
  AppBarBLEState(BLEcontroller controller) {
    controller.sendDataBLE = sendDataBLE;
  }

  //variable used to let user visually see the BLE connection status
  ValueNotifier<Color> connectionColor =
      ValueNotifier<Color>(const Color.fromARGB(255, 224, 80, 70));

  //variables for the action box to alert users of current happenings in BLE
  ValueNotifier<String> actionMssg = ValueNotifier<String>('Idle');
  ValueNotifier<String> timeMssg = ValueNotifier<String>('-');

  //variables used to keep track of the phone's bluetooth state
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;

  //variables to keep track of BLE scan results
  final List<ScanResult> _scanResults = [];
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;

  //variable used to check the services available by connected device
  List<BluetoothService> _services = [];

  //Medium remote ID for comparison when finding Medium
  //Might vary for different Mediums
  final List<DeviceIdentifier> mediumId = [
    const DeviceIdentifier('D8:3A:DD:5C:97:CD'),
  ];

  //to store the Medium found
  late BluetoothDevice mediumDevice;

  //indicator if a medium has been found
  bool mediumFound = false;
  bool mediumConnected = false;

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  void resetVariables() {
    _scanResults.clear(); //reset scan as Bluetooth state changes
    _services.clear(); //reset services as Bluetooth state changes
    mediumFound = false; //reset back to medium not found
    mediumConnected = false;
  }

  //this function can only be called by main_page.dart
  //other pages have to go through main_page.dart to call this function to send data to Medium
  void sendDataBLE(String dataToBeSent) async {
    debugPrint("Medium Connection: $mediumConnected");
    if (mediumConnected) {
      writeCharacteristics(dataToBeSent);
    }
  }

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
      //mediumConnected = false;
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
          height: 400,
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
  void timeActionMssg() {
    DateTime now = DateTime.now();
    int hour = now.hour;
    int minute = now.minute;

    // Convert the hour and minute to strings
    String hourString = hour.toString();
    String minuteString = minute.toString();

    // Add a leading zero if the minute is less than 10
    if (minute < 10) {
      minuteString = '0$minuteString';
    }

    // Update the time when Action Mssg was called
    // Concatenate the hour and minute with a colon
    timeMssg.value = '$hourString:$minuteString';
  }

  void editActionMssg(String newMssg) {
    actionMssg.value = newMssg;
    timeActionMssg();
  }

  Row contextBox(BuildContext context) {
    return Row(textBaseline: TextBaseline.alphabetic, children: [
      const SizedBox(width: 24),
      Container(
        height: 150,
        width: 200,
        decoration: BoxDecoration(
            color: const Color.fromARGB(255, 33, 33, 33),
            borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 60,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                  //border: Border.all(width: 2, color: Colors.white)
                ),
                child: Center(
                  child: ValueListenableBuilder(
                      valueListenable: timeMssg,
                      builder: (context, value, _) {
                        return Text(timeMssg.value,
                            softWrap: true,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 20));
                      }),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ValueListenableBuilder(
                  valueListenable: actionMssg,
                  builder: (context, value, _) {
                    return Text(actionMssg.value,
                        softWrap: true,
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 20));
                  }),
            )
          ],
        ),
      )
    ]);
  }

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Future<void> disconnectToMedium() async {
    if (mediumConnected) {
      editActionMssg("Attempting disconnection...");

      // Connect to the device
      try {
        await mediumDevice.disconnect();
      } catch (e) {
        debugPrint("$e");
        editActionMssg("Unable to disconnect!");
      }
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
  Future<void> readCharacteristics() async {
    //Read the characteristic in the 3rd service (the user defined characteristic)
    List<BluetoothCharacteristic> characteristics =
        _services[2].characteristics;
    BluetoothCharacteristic c = characteristics[1];
    String inputData;
    List<int> value;

    //read the characteristic message
    value = await c.read();

    //make it human readable instead of list of integers
    inputData = utf8.decode(value);

    //debug printing of what characteristic is read
    debugPrint("Read: $inputData");
  }

  Future<void> writeCharacteristics(String command) async {
    //Take the characteristic in the 3rd service (the user defined characteristic)
    List<BluetoothCharacteristic> characteristics =
        _services[2].characteristics;
    BluetoothCharacteristic c = characteristics[1];
    List<int> sendData;

    //Encode the command as utf8
    sendData = utf8.encode(command);

    //send the data through BLE to the Medium
    try {
      await c.write(sendData, allowLongWrite: true);
    } catch (e) {
      debugPrint("Does not Work!!!");
      debugPrint("$e");
    }
  }

  Future<void> connectToMedium() async {
    if (mediumFound && !mediumConnected) {
      editActionMssg("Attempting \nconnection....");

      // Connect to the device
      try {
        await mediumDevice.connect();
      } catch (e) {
        debugPrint('$e');
        editActionMssg("Problem with connecting..");
      }

      // listen for disconnection
      mediumDevice.connectionState
          .listen((BluetoothConnectionState state) async {
        if (state == BluetoothConnectionState.connected) {
          //connected change the icon color to green
          connectionColor.value = const Color.fromARGB(255, 128, 232, 80);

          editActionMssg("Medium Connected..\n Stay Safe!!");

          //set that Medium has been found
          mediumConnected = true;

          // Very important!
          //request the maxium transmission unit (MTU) of 512 bytes
          if (Platform.isAndroid) {
            await mediumDevice.requestMtu(512);
          }

          //Discover the services of the Medium
          _services = await mediumDevice.discoverServices();

          readCharacteristics();

          //for debugging purpose to know if Medium connected or not
          debugPrint("Medium Connected!");
        } else if (state == BluetoothConnectionState.disconnected) {
          //change the connection color to red
          connectionColor.value = const Color.fromARGB(255, 224, 80, 70);
          _services.clear(); //must rediscover services after disconnection
          editActionMssg("Disconnected from Medium...");
          resetVariables();
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
  Future<void> scanningStopCallback() async {
    await FlutterBluePlus.stopScan();

    if (mediumFound) {
      //show user in context box that medium detected
      editActionMssg("Scan Stopped... \nMedium Found!");
    } else {
      editActionMssg("Scan Stopped... \nNo Medium Detected!");
    }
  }

  Future<void> onScanPressed() async {
    Duration timeoutt = const Duration(seconds: 1);

    //only do the scanning if the Medium is not connected to app
    if (!mediumConnected) {
      try {
        resetVariables();

        //start scanning
        await FlutterBluePlus.startScan();

        //initialize timer to stop scanning and alert usert
        Timer(timeoutt, scanningStopCallback);
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
