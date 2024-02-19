import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:toggle_switch/toggle_switch.dart';

//controller for the BLE
class BLEcontroller {
  late void Function(List<int>) sendDataBLE;
}

//Widget for BLE
class AppBarBLE extends StatefulWidget {
  final BLEcontroller bleController;
  final double safeScreenHeight;
  final double safeScreenWidth;
  const AppBarBLE(
      {super.key,
      required this.bleController,
      required this.safeScreenHeight,
      required this.safeScreenWidth});

  @override
  State<AppBarBLE> createState() => AppBarBLEState(bleController);
}

//a public class so that main_page.dart can call the sendDataBLE function only
class AppBarBLEState extends State<AppBarBLE> {
  AppBarBLEState(BLEcontroller blEcontroller) {
    blEcontroller.sendDataBLE = sendDataBLE;
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

  //When connecting to Medium or Boat, it targets the specific device ID
  //bleIndex used to determine which device ID to look for
  int bleIndex = 0;
  //First ID: Medium
  //Second ID: Boat
  final List<DeviceIdentifier> devicesId = [
    const DeviceIdentifier('D8:3A:DD:5C:97:CD'),
    const DeviceIdentifier('D8:3A:DD:5C:97:CD'),
  ];

  //to store the Medium found
  late BluetoothDevice deviceStats;

  //indicator if a medium has been found
  bool deviceFound = false;
  bool deviceConnected = false;

  //for better scaling of widgets with different screen sizes
  late double _safeVertical;
  late double _safeHorizontal;

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  void resetVariables() {
    //change the connection color to red
    connectionColor.value = const Color.fromARGB(255, 224, 80, 70);
    _scanResults.clear(); //reset scan as Bluetooth state changes
    _services.clear(); //reset services as Bluetooth state changes
    deviceFound = false; //reset back to medium not found
    deviceConnected = false; //reset back to medium not connected
  }

  //this function can only be called by main_page.dart
  //other pages have to go through main_page.dart to call this function to send data to Medium
  void sendDataBLE(List<int> dataToBeSent) async {
    debugPrint("Medium Connection: $deviceConnected");
    if (deviceConnected) {
      writeCharacteristics(dataToBeSent);
      editActionMssg("Sent BLE\nmessage");
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
      deviceFound = false; //reset back to medium not found
      //deviceConnected = false;
      return false;
    }
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //initializer
  @override
  void initState() {
    super.initState();

    //for scaling size of the widget
    _safeVertical = widget.safeScreenHeight;
    _safeHorizontal = widget.safeScreenWidth;

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
            //check if it is a valid device ID (Medium or Boat)
            if (devicesId[bleIndex] == r.device.remoteId) {
              //Print detected onto console for debugging purpose
              debugPrint(r.advertisementData.advName);
              debugPrint('${r.device.remoteId}');

              //medium detected and add to list
              _scanResults.add(r);

              //assign the device to deviceStats for later connection
              deviceStats = r.device;

              //change bool variable keeping track of whether medium has been found or not
              deviceFound = true;
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
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              width: _safeVertical * 4,
            ),
            //show connection status to Medium
            Container(
              height: _safeVertical * 5,
              width: _safeHorizontal * 40,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 33, 33, 33),
                borderRadius: BorderRadius.circular(30),
              ),
              child: bleStatusRow(context),
            ),
            SizedBox(
              width: _safeVertical * 10,
            ),
            bleScanButton(context)
          ],
        ),
        SizedBox(
          height: _safeVertical * 0.9,
        ),
        contextBox(context), //show user what is currently happening in BLE
        SizedBox(
          height: _safeVertical * 0.9,
        ),
        deviceToggleButton(),
        SizedBox(
          height: _safeVertical * 0.9,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            bleConnectButton(context),
            bleDisconnectButton(context),
          ],
        ),
      ],
    );
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ToggleSwitch deviceToggleButton() {
    return ToggleSwitch(
      minWidth: _safeHorizontal * 41.5,
      minHeight: _safeVertical * 5,
      fontSize: _safeHorizontal * 4,
      initialLabelIndex: bleIndex,
      activeBgColor: const [Color(0xff768a76)],
      activeFgColor: Colors.white,
      inactiveBgColor: const Color.fromARGB(255, 68, 67, 67),
      inactiveFgColor: Colors.white,
      totalSwitches: 2,
      labels: const ['Medium', 'Boat'],
      onToggle: (index) {
        debugPrint('switched to: $index');
        //update ble index
        bleIndex = index!;

        //reset connections as well to ask user to do connection again
        if (deviceFound) {
          if (deviceConnected) {
            disconnectToDevice();
            editActionMssg("Switched Device..\nScan again!");
          } else {
            editActionMssg("Switched Device..\nScan again!");
            resetVariables();
          }
        }
      },
    );
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Row bleStatusRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ValueListenableBuilder(
            valueListenable: connectionColor,
            builder: (context, value, _) {
              return Icon(
                Icons.circle_sharp,
                size: _safeVertical * 3,
                color: connectionColor.value,
              );
            }),
        Text(
          'Connection',
          style: TextStyle(color: Colors.white, fontSize: _safeHorizontal * 4),
        ),
      ],
    );
  }

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  List<int> getDateTime(int length) {
    DateTime now = DateTime.now();
    int year = now.year - 2000;
    int month = now.month;
    int day = now.day;
    int hour = now.hour;
    int minute = now.minute;
    int second = now.second;

    if (length == 2) {
      return [hour, minute];
    } else {
      return [year, month, day, hour, minute, second];
    }
  }

  void timeActionMssg() {
    // Pass integer 2 to only get the hour and minute
    List<int> time = getDateTime(2);

    // Convert the hour and minute to strings
    String hourString = time[0].toString();
    String minuteString = time[1].toString();

    // Add a leading zero if the minute is less than 10
    if (time[1] < 10) {
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
    return Row(
      textBaseline: TextBaseline.alphabetic,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SizedBox(
          width: _safeVertical * 4,
        ),
        Container(
          height: _safeVertical * 35,
          width: _safeHorizontal * 83,
          decoration: BoxDecoration(
              color: const Color.fromARGB(255, 33, 33, 33),
              borderRadius: BorderRadius.circular(10)),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: _safeHorizontal * 15,
                  height: _safeVertical * 5,
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
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: _safeHorizontal * 4));
                        }),
                  ),
                ),
              ),
              SizedBox(
                height: _safeVertical * 4,
              ),
              Center(
                child: ValueListenableBuilder(
                    valueListenable: actionMssg,
                    builder: (context, value, _) {
                      return Text(actionMssg.value,
                          softWrap: true,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: _safeHorizontal * 5));
                    }),
              )
            ],
          ),
        ),
        SizedBox(
          width: _safeVertical * 4,
        ),
      ],
    );
  }

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Future<void> disconnectToDevice() async {
    if (deviceConnected) {
      editActionMssg("Attempting disconnection...");

      // Connect to the device
      try {
        await deviceStats.disconnect();
      } catch (e) {
        debugPrint("$e");
        editActionMssg("Unable to disconnect!");
      }
    }
  }

  Row bleDisconnectButton(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            textStyle: Theme.of(context).textTheme.labelLarge,
            // Customize other properties like padding, border, etc.
            side: const BorderSide(
                color: Color.fromARGB(255, 33, 33, 33),
                width: 1.0), // Add an outline border
          ),
          onPressed: () async {
            // Only do something if Bluetooth is ON and working
            if (checkAdapterState()) {
              disconnectToDevice();
            }
          },
          child: Text(
            'Disconnect',
            style: TextStyle(fontSize: _safeHorizontal * 5),
          ),
        )
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
    // String inputData;
    List<int> value;

    //read the characteristic message
    value = await c.read();

    //make it human readable instead of list of integers
    // inputData = utf8.decode(value);

    //debug printing of what characteristic is read
    debugPrint("Read: $value");
  }

  Future<void> writeCharacteristics(List<int> command) async {
    //Take the characteristic in the 3rd service (the user defined characteristic)
    List<BluetoothCharacteristic> characteristics =
        _services[2].characteristics;
    BluetoothCharacteristic c = characteristics[1];

    //send the data through BLE to the Medium
    try {
      await c.write(command, allowLongWrite: true);
    } catch (e) {
      debugPrint("Does not Work!!!");
      debugPrint("$e");
    }
  }

  Future<void> connectToMedium() async {
    if (deviceFound && !deviceConnected) {
      editActionMssg("Attempting \nconnection....");

      // Connect to the device
      try {
        await deviceStats.connect();
      } catch (e) {
        debugPrint('$e');
        editActionMssg("Problem with connecting..");
      }

      // listen for a connection
      var subscription = deviceStats.connectionState.listen(
        (BluetoothConnectionState state) async {
          if (state == BluetoothConnectionState.connected) {
            //connected change the icon color to green
            connectionColor.value = const Color.fromARGB(255, 128, 232, 80);

            editActionMssg("Medium Connected..\n Stay Safe!!");

            //set that Medium has been found
            deviceConnected = true;

            // Very important!
            //request the maximum transmission unit (MTU) of 512 bytes
            if (Platform.isAndroid) {
              await deviceStats.requestMtu(512);
            }

            //Discover the services of the Medium
            _services = await deviceStats.discoverServices();

            //Write to characteristic to initialize the date and time
            //get the phone's current date and time
            List<int> dateAndTime = getDateTime(6);
            dateAndTime.insert(0, 3);
            writeCharacteristics(dateAndTime);

            //for debugging purpose to know if Medium connected or not
            debugPrint("Medium Connected!");
          }
          // listen for disconnection
          else if (state == BluetoothConnectionState.disconnected) {
            editActionMssg("Disconnected from Medium...");
            resetVariables();
            debugPrint("Medium Disconnected!");
          }
        },
      );

      // cleanup: cancel subscription when disconnected
      // Note: `delayed:true` lets us receive the `disconnected` event in our handler
      // Note: `next:true` means cancel on *next* disconnection. Without this, it
      //   would cancel immediately because we're already disconnected right now.
      deviceStats.cancelWhenDisconnected(subscription,
          delayed: true, next: true);
    }
  }

  Row bleConnectButton(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            textStyle: Theme.of(context).textTheme.labelLarge,
            // Customize other properties like padding, border, etc.
            side: const BorderSide(
                color: Color.fromARGB(255, 33, 33, 33),
                width: 1.0), // Add an outline border
          ),
          onPressed: () async {
            // Only do something if Bluetooth is ON and working
            if (checkAdapterState()) {
              connectToMedium();
            }
          },
          child: Text(
            'Connect',
            style: TextStyle(fontSize: _safeHorizontal * 5),
          ),
        )
      ],
    );
  }

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Future<void> scanningStopCallback() async {
    await FlutterBluePlus.stopScan();

    if (deviceFound) {
      //show user in context box that medium detected
      editActionMssg("Scan Stopped... \nMedium Found!");
    } else {
      editActionMssg("Scan Stopped... \nNo Medium Detected!");
    }
  }

  Future<void> onScanPressed() async {
    Duration timeoutt = const Duration(seconds: 1);

    //only do the scanning if the Medium is not connected to app
    if (!deviceConnected) {
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
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            textStyle: Theme.of(context).textTheme.labelLarge,
            // Customize other properties like padding, border, etc.
            side: const BorderSide(
                color: Color.fromARGB(255, 33, 33, 33),
                width: 1.0), // Add an outline border
          ),
          onPressed: () async {
            // Only do something if Bluetooth is ON and working
            if (checkAdapterState()) {
              onScanPressed();
            }
          },
          child: Text(
            'Scan',
            style: TextStyle(fontSize: _safeHorizontal * 5),
          ),
        )
      ],
    );
  }
}
