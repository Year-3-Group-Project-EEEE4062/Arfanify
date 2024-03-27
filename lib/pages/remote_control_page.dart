import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class RemoteControlPage extends StatefulWidget {
  final Function(String) bLE;
  const RemoteControlPage({super.key, required this.bLE});

  @override
  RemoteControlState createState() => RemoteControlState();
}

class RemoteControlState extends State<RemoteControlPage> {
  double _motion = 0;
  String bLEremoteMode = "RMS";
  String bLEremoteDirection = "RD ";
  String _status = 'Stop';
  Color _statusColor = Colors.red;

  //callback to goes back to main_page.dart to send data through BLE
  void remoteControlSendBLE(String bLERemoteCommand) {
    debugPrint("Remote Callback Called");
    debugPrint(bLERemoteCommand);

    //remote control always sends two things
    //1st is the mode of the remote (ie. stop, low)
    //2nd is the direction of the motion (ie. forward, left, right)
    widget.bLE(bLERemoteCommand);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  //when remote control page closed, it will dispose of the variables
  void dispose() {
    // Clean up any resources here.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        modeGauge(),
        modeBar(),
        modeSetter(),
        const SizedBox(height: 40), //just empty space
        controlPad(),
        const SizedBox(height: 40),
      ],
    );
  }

  //////////////////////////////////////////////////////////////////////////////
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

  //////////////////////////////////////////////////////////////////////////////
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

  //////////////////////////////////////////////////////////////////////////////
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
  Container controlPad() {
    return Container(
      color: Colors.black,
      height: null,
      width: null,
      child: Column(
        children: [
          forward_button(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              left_button(),
              const SizedBox(
                width: 80,
              ),
              right_button(),
            ],
          ),
          backwards_button(),
        ],
      ),
    );
  }

  SizedBox forward_button() {
    return SizedBox(
      height: 100,
      width: 80,
      child: FloatingActionButton(
        heroTag: null,
        backgroundColor: const Color.fromARGB(255, 33, 33, 33),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(
          Icons.arrow_upward_outlined,
          size: 40,
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

  SizedBox backwards_button() {
    return SizedBox(
      height: 100,
      width: 80,
      child: FloatingActionButton(
        heroTag: null,
        backgroundColor: const Color.fromARGB(255, 33, 33, 33),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(
          Icons.arrow_downward_outlined,
          size: 40,
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

  SizedBox right_button() {
    return SizedBox(
      height: 80,
      width: 100,
      child: FloatingActionButton(
        heroTag: null,
        backgroundColor: const Color.fromARGB(255, 33, 33, 33),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(
          Icons.arrow_forward_outlined,
          size: 40,
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

  SizedBox left_button() {
    return SizedBox(
      height: 80,
      width: 100,
      child: FloatingActionButton(
        heroTag: null,
        backgroundColor: const Color.fromARGB(255, 33, 33, 33),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(
          Icons.arrow_back_outlined,
          size: 40,
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

  //////////////////////////////////////////////////////////////////////////////
  AppBar bar() {
    return AppBar(
      //adjust the size of the app bar
      toolbarHeight: 50,
      //styling of the text in the app bar
      title: const Text(
        'Remote Control',
        style: TextStyle(
          color: Colors.white,
          fontSize: 25,
          fontWeight: FontWeight.w300,
          height: 1.8,
        ),
      ),
      iconTheme: const IconThemeData(size: 40, color: Colors.white),
      //alignment of the text in the app bar
      centerTitle: true,
      //set background colour of AppBar
      backgroundColor: Colors.black,
    );
  }
}
