import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:remote_control_ui/pages/Home%20Page/home_page.dart';
import 'package:remote_control_ui/pages/Remote%20Page/remote_control_page.dart';
import 'package:remote_control_ui/pages/Auto%20Page/autonomous_page.dart';

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
      runApp(const InitApp());
    });
  } else {
    runApp(const InitApp());
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class InitApp extends StatelessWidget {
  const InitApp({super.key});

  @override
  Widget build(BuildContext context) {
    final List<double> sizes = SizeConfig().init(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false, //remove the debug banner
      theme: ThemeData(fontFamily: 'TiltNeon'),
      home: MainApp(
        safeScreenHeight: sizes[0],
        safeScreenWidth: sizes[1],
      ),
    );
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class MainApp extends StatefulWidget {
  final double safeScreenHeight;
  final double safeScreenWidth;
  const MainApp({
    super.key,
    required this.safeScreenHeight,
    required this.safeScreenWidth,
  });

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final HomePagecontroller myHomeController = HomePagecontroller();

  final RemoteModeController myRemoteController = RemoteModeController();

  final AutoModeController myAutoController = AutoModeController();

  int _selectedIndex = 0;
  late List<Widget> _pages;

  void updatePageIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  //store ble status
  //initially false to indicate not connected
  bool bleStat = false;

  //for updating page
  //To update bleStat in homepage
  void updateTreeBLEStat(bool stat) {
    bleStat = stat;

    if (myRemoteController.bleStat != null) {
      myRemoteController.bleStat!(bleStat);
    }

    if (myAutoController.bleStat != null) {
      myAutoController.bleStat!(bleStat);
    }
  }

  //Use BLE widget controller to send data to BLE widget
  void sendBLEwidget(List<int> message) {
    //Send message to BLE widget
    myHomeController.sendDataBLE(message);
  }

  void notifyRemoteNewBLE(List<dynamic> remoteNotifyMssg) {
    myRemoteController.notifyBLE(remoteNotifyMssg);
  }

  void notifyAutoNewBLE(List<dynamic> autoNotifyMssg) {
    myAutoController.notifyBLE(autoNotifyMssg);
  }

  @override
  void initState() {
    super.initState();

    _pages = [
      HomePage(
        safeScreenHeight: widget.safeScreenHeight,
        safeScreenWidth: widget.safeScreenWidth,
        updatePageIndex: updatePageIndex,
        updateTreeBLEStat: updateTreeBLEStat,
        notifyRemoteNewBLE: notifyRemoteNewBLE,
        notifyAutoNewBLE: notifyAutoNewBLE,
        homeController: myHomeController,
      ),
      RemotePage(
        safeScreenHeight: widget.safeScreenHeight,
        safeScreenWidth: widget.safeScreenWidth,
        updatePageIndex: updatePageIndex,
        bleStat: bleStat,
        sendbLE: sendBLEwidget,
        notifyController: myRemoteController,
      ),
      AutoPage(
        safeScreenHeight: widget.safeScreenHeight,
        safeScreenWidth: widget.safeScreenWidth,
        updatePageIndex: updatePageIndex,
        bleStat: bleStat,
        sendbLE: sendBLEwidget,
        notifyController: myAutoController,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _selectedIndex,
      children: _pages,
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
