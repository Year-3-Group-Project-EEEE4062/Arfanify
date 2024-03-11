import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:remote_control_ui/converter/data_converter.dart';

class RemotePage extends StatefulWidget {
  final double safeScreenHeight;
  final double safeScreenWidth;
  final Function(List<int>) bLE;
  const RemotePage(
      {super.key,
      required this.bLE,
      required this.safeScreenHeight,
      required this.safeScreenWidth});

  @override
  RemotePageState createState() => RemotePageState();
}

class RemotePageState extends State<RemotePage> {
  int _motion = 0;

  // List of integers that holds movement instructions for the boat
  // bleModeMovement[0] holds the remote or auto mode (0,1)
  // bleModeMovement[1] holds the motion S, A, F(0,1,2)
  // bleModeMovement[2] holds the movement F, B, R, L(0,1,2,3)
  List<int> bleModeMovement = [
    0,
    0,
  ];

  List<int> bleStop = [
    0,
  ];

  String _status = 'Slow';
  Color _statusColor = Colors.green;

  String _liveMotion = 'None';
  Color __liveMotionColor = Colors.purple;

  String _liveMovement = 'None';
  Color __liveMovementColor = Colors.red;

  // for better scaling of widgets with different screen sizes
  late double _safeVertical;
  late double _safeHorizontal;

  // convert the data to
  //callback to goes back to main_page.dart to send data through BLE
  void remoteModeSendBLE(List<int> bLERemoteCommand) {
    int remoteModeIdentifier = 0x01;

    debugPrint("Remote Mode BLE Callback Called");

    // Convert int list command to byte array
    Uint8List byteCommand =
        integerToByteArray(remoteModeIdentifier, bLERemoteCommand);

    //remote control sends a list of integers
    //each integer represents an action
    widget.bLE(byteCommand);
  }

  @override
  void initState() {
    super.initState();

    // initialize the variables
    _safeVertical = widget.safeScreenHeight;
    _safeHorizontal = widget.safeScreenWidth;
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              remotePageTitle(),
              SizedBox(
                height: _safeVertical * 7,
                width: _safeHorizontal * 20,
                child: homeButton(context),
              ),
            ],
          ),
          SizedBox(
            height: _safeVertical * 3,
          ),
          motionLayout(),
          SizedBox(height: _safeVertical * 2), //just empty space
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(width: _safeHorizontal * 2),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  featuresLayout(),
                  SizedBox(height: _safeVertical * 2), //just empty space
                  stopButton(),
                ],
              ),
              movementsLayout(),
              SizedBox(width: _safeHorizontal * 2),
            ],
          )
        ],
      ),
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  Container featuresLayout() {
    return Container(
      height: _safeVertical * 25,
      width: _safeHorizontal * 40,
      decoration: BoxDecoration(
        color: const Color(0xffC8D0C8),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Live Settings",
                style: TextStyle(
                    fontSize: _safeHorizontal * 6,
                    color: Colors.black,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Container(
            height: _safeVertical * 8,
            width: _safeHorizontal * 35,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10), color: Colors.black),
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: liveMotionBar(),
            ),
          ),
          Container(
            height: _safeVertical * 8,
            width: _safeHorizontal * 35,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10), color: Colors.black),
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: liveMovementBar(),
            ),
          ),
          SizedBox(height: _safeVertical * 2), //just empty space
        ],
      ),
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
                  fontSize: _safeHorizontal * 5,
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
                  fontSize: _safeHorizontal * 5, color: __liveMotionColor),
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
                  fontSize: _safeHorizontal * 5,
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
                  fontSize: _safeHorizontal * 5, color: __liveMovementColor),
            ),
          ],
        ),
      ],
    );
  }

  SizedBox stopButton() {
    return SizedBox(
      height: _safeVertical * 15,
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
                  color: Colors.white,
                  fontSize: _safeVertical * 4), // Customize label style
            ),
          ],
        ),
      ),
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  //home button to return back to home page
  OutlinedButton homeButton(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        // Pop context to return back to the home page
        Navigator.pop(context);
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
  SizedBox remotePageTitle() {
    return SizedBox(
      height: _safeVertical * 7,
      width: _safeHorizontal * 35,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Icon(
            Icons.settings_remote_sharp,
            color: Colors.white,
            size: _safeVertical * 5,
          ),
          Text(
            '> Remote',
            style: TextStyle(
              fontSize: _safeVertical * 2,
              color: Colors.white,
            ),
          )
        ],
      ),
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  Container motionLayout() {
    return Container(
      height: _safeVertical * 42,
      width: _safeHorizontal * 84,
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
          ],
        ),
      ),
    );
  }

  SizedBox modeGauge() {
    return SizedBox(
      height: _safeVertical * 27,
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
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 20),
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

  //////////////////////////////////////////////////////////////////////////////
  Container movementsLayout() {
    return Container(
      height: _safeVertical * 42,
      width: _safeHorizontal * 40,
      decoration: BoxDecoration(
        color: const Color(0xffC8D0C8),
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
                    fontSize: _safeHorizontal * 6,
                    color: Colors.black,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: _safeVertical), //just empty space
          controlPad(),
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
      height: _safeVertical * 11,
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
          debugPrint("${bleModeMovement[1]}");

          // Send data through BLE
          remoteModeSendBLE(bleModeMovement);

          updateLiveSettings(_status, _statusColor, "Forward", Colors.red);
        },
      ),
    );
  }

  SizedBox backwardsMovement() {
    return SizedBox(
      height: _safeVertical * 11,
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
          if (kDebugMode) {
            debugPrint("Backwards button pressed");
          }

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
      height: _safeVertical * 12,
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
          if (kDebugMode) {
            debugPrint("Right button pressed");
          }

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
      height: _safeVertical * 12,
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
          if (kDebugMode) {
            debugPrint("Left button pressed");
          }

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
