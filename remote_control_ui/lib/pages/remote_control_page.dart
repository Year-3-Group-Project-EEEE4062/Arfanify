import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class remoteControlPage extends StatefulWidget {
  @override
  _remoteControlState createState() => _remoteControlState();
}

class _remoteControlState extends State<remoteControlPage> {
  double _mode = 0;
  String _status = 'Stop';
  Color _statusColor = Colors.amber;

  @override
  //when remote control page closed, it will dispose of the variables
  void dispose() {
    // Clean up any resources here.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: bar(),
      body: Column(
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
      ),
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  SizedBox modeGauge() {
    return SizedBox(
      //color: Colors.amber,
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
              NeedlePointer(value: _mode, needleColor: Colors.white),
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
        value: _mode,
        min: 0.0,
        max: 6.0,
        divisions: 3,
        label: _getMode(),
        onChanged: (value) {
          setState(() {
            _mode = value;
            _status = _changeMode();
            _statusColor = _changeModeColor();
            if (kDebugMode) {
              debugPrint("$_mode , $_status , $_statusColor");
            }
          });
        },
      ),
    );
  }

  String _changeMode() {
    String label = '';
    if (_mode == 0.0) {
      label = 'Stop';
    } else if (_mode == 2.0) {
      label = 'Low';
    } else if (_mode == 4.0) {
      label = 'Medium';
    } else if (_mode == 6.0) {
      label = 'High';
    }
    return label;
  }

  Color _changeModeColor() {
    Color ModeColor = Colors.amber;
    if (_mode == 0.0) {
      ModeColor = Colors.red;
    } else if (_mode == 2.0) {
      ModeColor = Colors.green;
    } else if (_mode == 4.0) {
      ModeColor = Colors.yellow;
    } else if (_mode == 6.0) {
      ModeColor = Colors.orange;
    }
    return ModeColor;
  }

  String _getMode() {
    String label = '';
    if (_mode == 0.0) {
      label = 'Stop';
    } else if (_mode == 2.0) {
      label = 'Low';
    } else if (_mode == 4.0) {
      label = 'Medium';
    } else if (_mode == 6.0) {
      label = 'High';
    }
    return label;
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
        backgroundColor: const Color(0xff545454),
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
        backgroundColor: const Color(0xff545454),
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
        backgroundColor: const Color(0xff545454),
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
        backgroundColor: const Color(0xff545454),
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
