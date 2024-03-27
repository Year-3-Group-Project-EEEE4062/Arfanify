import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  final Function(int) updateScaffoldBody;
  const HomePage({super.key, required this.updateScaffoldBody});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  Color buttonBackgroundColor = const Color(0xff171717);
  Color buttonForegroundColor = const Color.fromARGB(255, 234, 228, 228);

  void buttonPressed(int index) {
    widget.updateScaffoldBody(index);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          arfanifyIcon(),
          remoteControlButton(),
          autonomousButton(),
          cloudBackupButton(),
        ],
      ),
    );
  }

  Image arfanifyIcon() {
    return const Image(
      image: AssetImage('assets/icons/Arfanify.png'),
      width: 200,
      height: 200,
      color: Colors.white,
    );
  }

  Container remoteControlButton() {
    return Container(
      margin: const EdgeInsets.all(10),
      height: 100,
      width: 160,
      child: ElevatedButton(
        onPressed: () {
          buttonPressed(1);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonBackgroundColor,
          foregroundColor: buttonForegroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.settings_remote_sharp,
                size: 60), // Adjust the size as needed
            Text(
              'Remote Control',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Container autonomousButton() {
    return Container(
      margin: const EdgeInsets.all(10),
      height: 100,
      width: 160,
      child: ElevatedButton(
        onPressed: () {
          buttonPressed(2); // Use the variable within the print statement
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonBackgroundColor,
          foregroundColor: buttonForegroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.map_outlined, size: 60), // Adjust the size as needed
            Text(
              'Autonomous',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Container cloudBackupButton() {
    return Container(
      margin: const EdgeInsets.all(10),
      height: 100,
      width: 160,
      child: ElevatedButton(
        onPressed: () {
          buttonPressed(3); // Use the variable within the print statement
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonBackgroundColor,
          foregroundColor: buttonForegroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.cloud_done, size: 60), // Adjust the size as needed
            Text(
              'Cloud Backup',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
