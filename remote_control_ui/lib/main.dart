import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:remote_control_ui/pages/home_page.dart';

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

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final List<double> sizes = SizeConfig().init(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false, //remove the debug banner
      theme: ThemeData(fontFamily: 'TiltNeon'),
      home: HomePage(
        safeScreenHeight: sizes[0],
        safeScreenWidth: sizes[1],
      ),
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
