import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class RemotePage extends StatefulWidget {
  final double safeScreenHeight;
  final double safeScreenWidth;
  final Function(String) bLE;
  const RemotePage(
      {super.key,
      required this.bLE,
      required this.safeScreenHeight,
      required this.safeScreenWidth});

  @override
  RemotePageState createState() => RemotePageState();
}

class RemotePageState extends State<RemotePage> {
  double _motion = 0;
  String bLEremoteMode = "RMS";
  String bLEremoteDirection = "RD ";
  String _status = 'Stop';
  Color _statusColor = Colors.red;

  // for better scaling of widgets with different screen sizes
  late double _safeVertical;
  late double _safeHorizontal;

  //callback to goes back to main_page.dart to send data through BLE
  void remoteControlSendBLE(String bLERemoteCommand) {
    debugPrint("Remote Callback Called");
    debugPrint(bLERemoteCommand);

    //remote control sends a list of integers
    //each integer represents an action
    widget.bLE(bLERemoteCommand);
  }

  @override
  void initState() {
    super.initState();

    // initialize the variables
    _safeVertical = widget.safeScreenHeight;
    _safeHorizontal = widget.safeScreenWidth;
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
              featuresLayout(),
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
      height: _safeVertical * 42,
      width: _safeHorizontal * 40,
      decoration: BoxDecoration(
        color: const Color(0xffC8D0C8),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Features",
                style: TextStyle(
                    fontSize: 22,
                    color: Colors.black,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(
            height: _safeVertical * 15,
            width: _safeHorizontal * 33,
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white, // Text color
                backgroundColor: const Color(0xff768a76), // Background color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20), // Rounded corners
                ),
                // Add other properties as needed
              ),
              onPressed: () {
                // Add your button action here
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.thermostat, // Your desired icon
                    size: _safeVertical * 8,
                  ),
                  Text(
                    'Measure', // Your label text
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: _safeVertical * 2), // Customize label style
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: _safeVertical * 2), //just empty space
          SizedBox(
            height: _safeVertical * 15,
            width: _safeHorizontal * 33,
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white, // Text color
                backgroundColor: const Color(0xff768a76), // Background color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20), // Rounded corners
                ),
                // Add other properties as needed
              ),
              onPressed: () {
                // Add your button action here
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.home_filled, // Your desired icon
                    size: _safeVertical * 8,
                  ),
                  Text(
                    'Go Home', // Your label text
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: _safeVertical * 2), // Customize label style
                  ),
                ],
              ),
            ),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          modeGauge(),
          modeBar(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: _safeHorizontal * 80,
                child: modeSetter(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  SizedBox modeGauge() {
    return SizedBox(
      height: 250,
      child: SfRadialGauge(
        axes: <RadialAxis>[
          RadialAxis(
            showLabels: false,
            minimum: -1,
            maximum: 7,
            ranges: <GaugeRange>[
              GaugeRange(startValue: -1, endValue: 1, color: Colors.red),
              GaugeRange(startValue: 1, endValue: 3, color: Colors.green),
              GaugeRange(startValue: 3, endValue: 5, color: Colors.yellow),
              GaugeRange(startValue: 5, endValue: 7, color: Colors.orange),
            ],
            pointers: <GaugePointer>[
              NeedlePointer(value: _motion, needleColor: Colors.white),
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
        value: _motion,
        min: 0.0,
        max: 6.0,
        divisions: 3,
        onChanged: (value) {
          setState(() {
            _motion = value;
            _status = _changeMode();
            _statusColor = _changeModeColor();
          });
        },
      ),
    );
  }

  String _changeMode() {
    String label = '';
    if (_motion == 0.0) {
      label = 'Stop';
      bLEremoteMode = bLEremoteMode.replaceRange(2, 3, "S");
    } else if (_motion == 2.0) {
      label = 'Low';
      bLEremoteMode = bLEremoteMode.replaceRange(2, 3, "L");
    } else if (_motion == 4.0) {
      label = 'Average';
      bLEremoteMode = bLEremoteMode.replaceRange(2, 3, "A");
    } else if (_motion == 6.0) {
      label = 'Fast';
      bLEremoteMode = bLEremoteMode.replaceRange(2, 3, "F");
    }

    //send data through bLE
    remoteControlSendBLE(bLEremoteMode);
    return label;
  }

  Color _changeModeColor() {
    Color modeColor = Colors.amber;
    if (_motion == 0.0) {
      modeColor = Colors.red;
    } else if (_motion == 2.0) {
      modeColor = Colors.green;
    } else if (_motion == 4.0) {
      modeColor = Colors.yellow;
    } else if (_motion == 6.0) {
      modeColor = Colors.orange;
    }
    return modeColor;
  }

  Row modeBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Motion: ',
          style: TextStyle(
              fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Text(
          _status,
          style: TextStyle(fontSize: 25, color: _statusColor),
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Movements",
                style: TextStyle(
                    fontSize: 22,
                    color: Colors.black,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
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

  SizedBox forwardMovement() {
    return SizedBox(
      height: _safeVertical * 11,
      width: _safeHorizontal * 15,
      child: FloatingActionButton(
        heroTag: null,
        backgroundColor: const Color.fromARGB(255, 33, 33, 33),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Center(
          child: Icon(
            Icons.arrow_upward_outlined,
            size: 40,
          ),
        ),
        onPressed: () {
          if (kDebugMode) {
            debugPrint("Forward button pressed");
          }

          //send data through BLE
          bLEremoteDirection = bLEremoteDirection.replaceRange(2, 3, "F");
          remoteControlSendBLE(bLEremoteDirection);
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
        child: const Center(
          child: Icon(
            Icons.arrow_downward_outlined,
            size: 40,
          ),
        ),
        onPressed: () {
          if (kDebugMode) {
            debugPrint("Backwards button pressed");
          }

          //send data through BLE
          bLEremoteDirection = bLEremoteDirection.replaceRange(2, 3, "B");
          remoteControlSendBLE(bLEremoteDirection);
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
        child: const Center(
          child: Icon(
            Icons.arrow_forward_outlined,
            size: 40,
          ),
        ),
        onPressed: () {
          if (kDebugMode) {
            debugPrint("Right button pressed");
          }

          //send data through BLE
          bLEremoteDirection = bLEremoteDirection.replaceRange(2, 3, "R");
          remoteControlSendBLE(bLEremoteDirection);
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
        child: const Center(
          child: Icon(
            Icons.arrow_back_outlined,
            size: 40,
          ),
        ),
        onPressed: () {
          if (kDebugMode) {
            debugPrint("Left button pressed");
          }

          //send data through BLE
          bLEremoteDirection = bLEremoteDirection.replaceRange(2, 3, "L");
          remoteControlSendBLE(bLEremoteDirection);
        },
      ),
    );
  }
}
