import 'package:flutter/material.dart';
import 'package:remote_control_ui/pages/home_page.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false, //remove the debug banner
        theme: ThemeData(fontFamily: 'YoungSerif'),
        home: const homePage());
  }
}
