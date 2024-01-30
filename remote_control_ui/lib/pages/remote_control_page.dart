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
  String bLEremoteCommand = "R S  ";
  String _status = 'Stop';
  Color _statusColor = Colors.red;

  //callback to goes back to main_page.dart to send data through BLE
  void remoteControlSendBLE() {
    debugPrint("Remote Callback Called");
    debugPrint(bLEremoteCommand);
    widget.bLE(bLEremoteCommand);
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
            if (kDebugMode) {
              debugPrint("$_motion , $_status , $_statusColor");
            }
          });
        },
      ),
    );
  }

  String _changeMode() {
    String label = '';
    if (_motion == 0.0) {
      label = 'Stop';
      bLEremoteCommand = bLEremoteCommand.replaceRange(2, 2 + 1, 'S');
      remoteControlSendBLE();
    } else if (_motion == 2.0) {
      label = 'Low';
      bLEremoteCommand = bLEremoteCommand.replaceRange(2, 2 + 1, 'L');
      remoteControlSendBLE();
    } else if (_motion == 4.0) {
      label = 'Average';
    } else if (_motion == 6.0) {
      label = 'Fast';
    }
    return label;
  }

  Color _changeModeColor() {
    Color ModeColor = Colors.amber;
    if (_motion == 0.0) {
      ModeColor = Colors.red;
    } else if (_motion == 2.0) {
      ModeColor = Colors.green;
    } else if (_motion == 4.0) {
      ModeColor = Colors.yellow;
    } else if (_motion == 6.0) {
      ModeColor = Colors.orange;
    }
    return ModeColor;
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
          bLEremoteCommand = bLEremoteCommand.replaceRange(4, 4 + 1, 'F');
          remoteControlSendBLE();
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
