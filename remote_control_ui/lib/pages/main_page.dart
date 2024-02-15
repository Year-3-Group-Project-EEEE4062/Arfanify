import 'package:flutter/material.dart';
import 'package:remote_control_ui/pages/autonomous_page.dart';
import 'package:remote_control_ui/pages/home_page.dart';
import 'package:remote_control_ui/pages/remote_control_page.dart';

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
