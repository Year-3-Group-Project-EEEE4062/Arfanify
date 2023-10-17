import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remote_control_ui/pages/main_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  //lock the orientation to potrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const MainApp());
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
