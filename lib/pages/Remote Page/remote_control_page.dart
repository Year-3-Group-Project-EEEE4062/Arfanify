import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:remote_control_ui/converter/data_converter.dart';
import 'package:floating_snackbar/floating_snackbar.dart';

//controller for the BLE
class RemotePageController {
  late void Function(List<dynamic>) notifyBLE;
  void Function(bool)? bleStat;
}

class RemotePage extends StatefulWidget {
  final double safeScreenHeight;
  final double safeScreenWidth;
  final Function(int) updatePageIndex;
  final bool bleStat;
  final Function(List<int>) sendbLE;
  final RemotePageController notifyController;
  const RemotePage({
    super.key,
    required this.safeScreenHeight,
    required this.safeScreenWidth,
    required this.updatePageIndex,
    required this.bleStat,
    required this.sendbLE,
    required this.notifyController,
  });

  @override
  RemotePageState createState() => RemotePageState(notifyController);
}

class RemotePageState extends State<RemotePage> {
  RemotePageState(RemotePageController notifyController) {
    notifyController.notifyBLE = remoteModeNotifyBLE;
    notifyController.bleStat = updateBLEStat;
  }

  int _motion = 0;

  // List of integers that holds movement instructions for the boat
  // bleModeMovement[0] holds the remote or auto mode (0,1)
  // bleModeMovement[1] holds the motion S, A, F(0,1,2)
  // bleModeMovement[2] holds the movement F, B, R, L(0,1,2,3)
  List<int> bleModeMovement = [
    0,
    0,
  ];

  List<int> bleStop = [0];
  List<int> bleMeasure = [1];
  List<int> bleCancel = [2];

  String _status = 'Slow';
  Color _statusColor = Colors.green;

  String _liveMotion = 'None';
  Color __liveMotionColor = Colors.purple;

  String _liveMovement = 'None';
  Color __liveMovementColor = Colors.red;

  late IconData bleStatLogo;

  // for better scaling of widgets with different screen sizes
  late double _safeVertical;
  late double _safeHorizontal;

  bool isTemperatureMeasurement = false;

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //function to change page back to home page
  void changeToHomePage() {
    if (_liveMovement != 'None') {
      // Send data through BLE
      remoteModeSendBLE(bleStop);
      updateLiveSettings("None", Colors.purple, "None", Colors.purple);
    }

    // home page index is 0
    widget.updatePageIndex(0);
  }

  //callback to goes back to main_page.dart to send data through BLE
  void remoteModeSendBLE(List<int> bLERemoteCommand) {
    int remoteModeIdentifier = 0x01;

    debugPrint("Remote Mode BLE Callback Called");

    // Convert int list command to byte array
    Uint8List byteCommand =
        integerToByteArray(remoteModeIdentifier, bLERemoteCommand);

    //remote control sends a list of integers
    //each integer represents an action
    widget.sendbLE(byteCommand);
  }

  void remoteModeNotifyBLE(List<dynamic> notifybLERemote) {
    // Check if remote page mounted or not
    if (mounted) {
      debugPrint("Notified: $notifybLERemote");
      if (notifybLERemote[0] == 3) {
        showSnackBar("Temperature collected, check boat..", context);
        setState(() {
          isTemperatureMeasurement = false;
        });
      }
    }
  }

  void updateBLEStat(bool status) {
    //first check if this widget mounted in widget tree or not
    if (mounted) {
      setState(() {
        if (status) {
          bleStatLogo = Icons.bluetooth_connected;
        } else {
          bleStatLogo = Icons.bluetooth_disabled;
        }
      });
    }
  }

  void showSnackBar(String snackMssg, BuildContext context) {
    FloatingSnackBar(
      message: snackMssg,
      context: context,
      textColor: Colors.black,
      // textStyle: const TextStyle(color: Colors.green),
      duration: const Duration(milliseconds: 2000),
      backgroundColor: Colors.grey,
    );
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  @override
  void initState() {
    super.initState();

    if (widget.bleStat) {
      bleStatLogo = Icons.bluetooth_connected;
    } else {
      bleStatLogo = Icons.bluetooth_disabled;
    }

    // initialize the variables
    _safeVertical = widget.safeScreenHeight;
    _safeHorizontal = widget.safeScreenWidth;

    debugPrint("Remote page rebuilds..");
  }

  @override
  void dispose() {
    if (_liveMovement != 'None') {
      // Send data through BLE
      remoteModeSendBLE(bleStop);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          SizedBox(
            height: _safeVertical * 5,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                remotePageTitle(),
                SizedBox(
                  height: _safeVertical * 7,
                  child: SizedBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        bleStatus(),
                        SizedBox(width: _safeHorizontal * 3), //just empty space
                        homeButton(context),
                        SizedBox(width: _safeHorizontal * 1),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: _safeVertical * 1,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 15),
            child: Column(
              children: [
                motionLayout(),
                SizedBox(height: _safeVertical * 2), //just empty space
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 15),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          (isTemperatureMeasurement)
                              ? cancelButton()
                              : measureButton(),
                          SizedBox(
                              height: _safeVertical * 2), //just empty space
                          stopButton(),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: movementsLayout(),
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  SizedBox remotePageTitle() {
    return SizedBox(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ImageIcon(
            const AssetImage('assets/icons/arfanify.png'),
            color: Colors.white,
            size: _safeVertical * 8,
          ),
          Text(
            '> Remote',
            style: TextStyle(
              fontSize: _safeVertical * 3,
              color: Colors.white,
            ),
          )
        ],
      ),
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  SizedBox bleStatus() {
    return SizedBox(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Icon(
            bleStatLogo,
            color: Colors.white,
            size: _safeVertical * 5,
          ),
        ],
      ),
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  //home button to return back to home page
  OutlinedButton homeButton(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        changeToHomePage();
      },
      style: OutlinedButton.styleFrom(
        side: const BorderSide(
          width: 3,
          color: Colors.white,
          style: BorderStyle.solid,
        ),
        backgroundColor: const Color(0xff768a76), // Outline color
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(30), // Adjust the border radius as needed
        ),
      ),
      child: Center(
        child: Icon(
          Icons.home_filled,
          color: Colors.white,
          size: _safeVertical * 4,
        ),
      ),
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  Container motionLayout() {
    return Container(
      height: _safeVertical * 51,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 33, 33, 33),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            modeGauge(),
            modeBar(),
            modeSetter(),
            SizedBox(height: _safeVertical),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: _safeVertical * 8,
                  width: _safeHorizontal * 35,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.black),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: liveMotionBar(),
                  ),
                ),
                Container(
                  height: _safeVertical * 8,
                  width: _safeHorizontal * 35,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.black),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: liveMovementBar(),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  SizedBox modeGauge() {
    return SizedBox(
      height: _safeVertical * 25,
      child: SfRadialGauge(
        axes: <RadialAxis>[
          RadialAxis(
            showLabels: false,
            minimum: -1,
            maximum: 5,
            ranges: <GaugeRange>[
              GaugeRange(startValue: -1, endValue: 1, color: Colors.green),
              GaugeRange(startValue: 1, endValue: 3, color: Colors.yellow),
              GaugeRange(startValue: 3, endValue: 5, color: Colors.red),
            ],
            pointers: <GaugePointer>[
              NeedlePointer(
                  value: _motion.toDouble(), needleColor: Colors.white),
            ],
          )
        ],
      ),
    );
  }

  SliderTheme modeSetter() {
    return SliderTheme(
      data: const SliderThemeData(
        thumbColor: Colors.white,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 15),
        activeTrackColor: Color(0xff545454),
        inactiveTrackColor: Colors.grey,
        inactiveTickMarkColor: Colors.white,
        trackHeight: 20,
      ),
      child: Slider(
        value: _motion.toDouble(),
        min: 0.0,
        max: 4.0,
        divisions: 2,
        onChanged: (value) {
          setState(() {
            _motion = value.toInt();
            debugPrint("Motion value: $_motion");
            _status = _changeMode();
            _statusColor = _changeModeColor();
          });
        },
      ),
    );
  }

  String _changeMode() {
    String label = '';
    if (_motion == 0) {
      label = 'Slow';
    } else if (_motion == 2) {
      label = 'Average';
    } else if (_motion == 4) {
      label = 'Fast';
    }

    return label;
  }

  Color _changeModeColor() {
    Color modeColor = Colors.amber;
    if (_motion == 0) {
      modeColor = Colors.green;
    } else if (_motion == 2) {
      modeColor = Colors.yellow;
    } else if (_motion == 4) {
      modeColor = Colors.red;
    }
    return modeColor;
  }

  Row modeBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Desired Motion: ',
          style: TextStyle(
              fontSize: _safeHorizontal * 5,
              fontWeight: FontWeight.bold,
              color: Colors.white),
        ),
        SizedBox(
          width: _safeHorizontal,
        ),
        Text(
          _status,
          style: TextStyle(fontSize: _safeHorizontal * 5, color: _statusColor),
        ),
      ],
    );
  }

  Column liveMotionBar() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(width: _safeHorizontal * 2),
            Text(
              'Motion: ',
              style: TextStyle(
                  fontSize: _safeHorizontal * 4,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(width: _safeHorizontal * 5),
            Text(
              _liveMotion,
              style: TextStyle(
                  fontSize: _safeHorizontal * 4, color: __liveMotionColor),
            ),
          ],
        ),
      ],
    );
  }

  Column liveMovementBar() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(width: _safeHorizontal * 2),
            Text(
              'Movement: ',
              style: TextStyle(
                  fontSize: _safeHorizontal * 4,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(width: _safeHorizontal * 5),
            Text(
              _liveMovement,
              style: TextStyle(
                  fontSize: _safeHorizontal * 4, color: __liveMovementColor),
            ),
          ],
        ),
      ],
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  SizedBox measureButton() {
    return SizedBox(
      height: _safeVertical * 16,
      width: _safeHorizontal * 40,
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: Colors.black, // Text color
          backgroundColor: const Color(0xffC8D0C8), // Background color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // Rounded corners
          ),
          // Add other properties as needed
        ),
        onPressed: () async {
          //Check if the boat has stopped or not
          //If boat is still moving, it will instruct boat to stop first
          //then send instruction to initiate temperature measurement
          if (_liveMovement != 'None') {
            remoteModeSendBLE(bleStop);
            updateLiveSettings("None", Colors.purple, "None", Colors.purple);

            //Have to add a 1 second delay before sending another instruction
            Future.delayed(const Duration(microseconds: 1000), () {
              remoteModeSendBLE(bleMeasure);
              setState(() {
                isTemperatureMeasurement = true;
              });
              setState(() {
                isTemperatureMeasurement = true;
              });
            });
          } else {
            //Otherwise, boat already stopped so initiate temperature measurement
            remoteModeSendBLE(bleMeasure);
            showSnackBar("Initiating temperature measurement!", context);
            setState(() {
              isTemperatureMeasurement = true;
            });
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ImageIcon(
              const AssetImage('assets/icons/temperature.png'),
              size: _safeVertical * 9,
            ),
            Text(
              'Measure', // Your label text
              style: TextStyle(
                  color: Colors.black,
                  fontSize: _safeVertical * 2), // Customize label style
            ),
          ],
        ),
      ),
    );
  }

  SizedBox cancelButton() {
    return SizedBox(
      height: _safeVertical * 16,
      width: _safeHorizontal * 40,
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white, // Text color
          backgroundColor: Colors.red, // Background color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // Rounded corners
          ),
          // Add other properties as needed
        ),
        onPressed: () async {
          remoteModeSendBLE(bleCancel);
          isTemperatureMeasurement = false;
          showSnackBar("Cancelling temperature measurement", context);

          setState(() {});
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.cancel_outlined, // Your desired icon
              size: _safeVertical * 7,
            ),
            SizedBox(width: _safeHorizontal * 2),
            Text(
              'CANCEL', // Your label text
              style: TextStyle(
                  color: Colors.white,
                  fontSize: _safeVertical * 2), // Customize label style
            ),
          ],
        ),
      ),
    );
  }

  SizedBox stopButton() {
    return SizedBox(
      height: _safeVertical * 15,
      width: _safeHorizontal * 40,
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: Colors.black, // Text color
          backgroundColor: Colors.red, // Background color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // Rounded corners
          ),
          // Add other properties as needed
        ),
        onPressed: () {
          // Send data through BLE
          remoteModeSendBLE(bleStop);
          updateLiveSettings("None", Colors.purple, "None", Colors.purple);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.remove_circle_outline, // Your desired icon
              size: _safeVertical * 7,
            ),
            SizedBox(width: _safeHorizontal * 2),
            Text(
              'STOP', // Your label text
              style: TextStyle(
                  color: Colors.black,
                  fontSize: _safeVertical * 2), // Customize label style
            ),
          ],
        ),
      ),
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  Container movementsLayout() {
    return Container(
      height: _safeVertical * 34,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: _safeVertical), //just empty space
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Movements",
                style: TextStyle(
                    fontSize: _safeHorizontal * 4,
                    color: Colors.black,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: _safeVertical), //just empty space
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 15),
            child: controlPad(),
          ),
        ],
      ),
    );
  }

  Column controlPad() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        forwardMovement(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            leftMovement(),
            SizedBox(
              width: _safeHorizontal * 4,
            ),
            rightMovement(),
          ],
        ),
        backwardsMovement(),
      ],
    );
  }

  void updateLiveSettings(String desiredMotion, Color desiredMotionColor,
      String movement, Color movementColor) {
    _liveMotion = desiredMotion;
    __liveMotionColor = desiredMotionColor;

    _liveMovement = movement;
    __liveMovementColor = movementColor;

    setState(() {});
  }

  SizedBox forwardMovement() {
    return SizedBox(
      height: _safeVertical * 9,
      width: _safeHorizontal * 15,
      child: FloatingActionButton(
        heroTag: null,
        backgroundColor: const Color.fromARGB(255, 33, 33, 33),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Center(
          child: Icon(
            Icons.arrow_upward_outlined,
            size: _safeVertical * 5,
          ),
        ),
        onPressed: () {
          // Change the bleModeMovement index
          bleModeMovement[0] = 0;
          bleModeMovement[1] = (_motion + 1) * 15;

          // Send data through BLE
          remoteModeSendBLE(bleModeMovement);

          updateLiveSettings(_status, _statusColor, "Forward", Colors.red);
        },
      ),
    );
  }

  SizedBox backwardsMovement() {
    return SizedBox(
      height: _safeVertical * 9,
      width: _safeHorizontal * 15,
      child: FloatingActionButton(
        heroTag: null,
        backgroundColor: const Color.fromARGB(255, 33, 33, 33),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Center(
          child: Icon(
            Icons.arrow_downward_outlined,
            size: _safeVertical * 5,
          ),
        ),
        onPressed: () {
          // Change the bleModeMovement index
          bleModeMovement[0] = 1;
          bleModeMovement[1] = (_motion + 1) * 15;

          // Send data through BLE
          remoteModeSendBLE(bleModeMovement);

          updateLiveSettings(_status, _statusColor, "Backwards", Colors.red);
        },
      ),
    );
  }

  SizedBox rightMovement() {
    return SizedBox(
      height: _safeVertical * 9,
      width: _safeHorizontal * 15,
      child: FloatingActionButton(
        heroTag: null,
        backgroundColor: const Color.fromARGB(255, 33, 33, 33),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Center(
          child: Icon(
            Icons.arrow_forward_outlined,
            size: _safeVertical * 5,
          ),
        ),
        onPressed: () {
          // Change the bleModeMovement index
          bleModeMovement[0] = 2;
          bleModeMovement[1] = (_motion + 1) * 15;

          // Send data through BLE
          remoteModeSendBLE(bleModeMovement);

          updateLiveSettings(_status, _statusColor, "Rightwards", Colors.red);
        },
      ),
    );
  }

  SizedBox leftMovement() {
    return SizedBox(
      height: _safeVertical * 9,
      width: _safeHorizontal * 15,
      child: FloatingActionButton(
        heroTag: null,
        backgroundColor: const Color.fromARGB(255, 33, 33, 33),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Center(
          child: Icon(
            Icons.arrow_back_outlined,
            size: _safeVertical * 5,
          ),
        ),
        onPressed: () {
          // Change the bleModeMovement index
          bleModeMovement[0] = 3;
          bleModeMovement[1] = (_motion + 1) * 15;

          // Send data through BLE
          remoteModeSendBLE(bleModeMovement);

          updateLiveSettings(_status, _statusColor, "Leftwards", Colors.red);
        },
      ),
    );
  }
}
