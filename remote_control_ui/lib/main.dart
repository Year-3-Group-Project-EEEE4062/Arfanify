import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:remote_control_ui/pages/autonomous_page.dart';
import 'package:remote_control_ui/pages/home_page.dart';
import 'package:remote_control_ui/pages/remote_control_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  //lock the orientation to potrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  //check if android platform and ask permissions if it is
  if (Platform.isAndroid) {
    WidgetsFlutterBinding.ensureInitialized();
    [
      Permission.location,
      Permission.storage,
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan
    ].request().then((status) {
      runApp(const MainApp());
    });
  } else {
    runApp(const MainApp());
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, //remove the debug banner
      theme: ThemeData(fontFamily: 'TiltNeon'),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  ////////////////////////variables
  int _selectedIndex = 0;

  //update the selected index based on which page user wants to go to
  _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  _updateDeviceBLE(String command) {}

  //return widget based on what user wants
  Widget goToPage(double height, double width) {
    if (_selectedIndex == 0) {
      return HomePage(
        updateScaffoldBody: _onItemTapped,
        safeScreenHeight: height,
        safeScreenWidth: width,
      );
    } else if (_selectedIndex == 1) {
      return RemoteControlPage(bLE: _updateDeviceBLE);
    } else if (_selectedIndex == 2) {
      return const AutonomousPagee();
    }

    // null safety
    return const Scaffold();
  }

  ////////////////////////Scaffold
  @override
  Widget build(BuildContext context) {
    final List<double> sizes = SizeConfig().init(context);

    return goToPage(
      sizes[0],
      sizes[1],
    );
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///Class for determining screen size
class SizeConfig {
  late MediaQueryData _mediaQueryData;
  late double screenWidth;
  late double screenHeight;
  late double blockSizeHorizontal;
  late double blockSizeVertical;
  late double _safeAreaHorizontal;
  late double _safeAreaVertical;
  late double safeBlockHorizontal;
  late double safeBlockVertical;

  List<double> init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;
    _safeAreaHorizontal =
        _mediaQueryData.padding.left + _mediaQueryData.padding.right;
    _safeAreaVertical =
        _mediaQueryData.padding.top + _mediaQueryData.padding.bottom;
    safeBlockHorizontal = (screenWidth - _safeAreaHorizontal) / 100;
    safeBlockVertical = (screenHeight - _safeAreaVertical) / 100;

    return [safeBlockVertical, safeBlockHorizontal];
  }
}
