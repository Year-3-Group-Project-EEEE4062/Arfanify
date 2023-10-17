import 'package:flutter/material.dart';
import 'package:remote_control_ui/pages/autonomous_page.dart';
import 'package:remote_control_ui/pages/home_page.dart';
import 'package:remote_control_ui/pages/remote_control_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, //remove the debug banner
      theme: ThemeData(fontFamily: 'TiltNeon'),
      initialRoute: '/home',
      routes: {
        '/home': (context) => const HomePage(),
        '/remoteControl': (context) => remoteControlPage(),
        '/autonomous': (context) => const AutonomousPage(),
        '/cloudBackup': (context) => remoteControlPage(),
      },
    );
  }
}
