import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  @override
  _homePageState createState() => _homePageState();
}

class _homePageState extends State<HomePage> {
 
  @override
  Widget build(BuildContext context) {
    return Center(
      // mainAxisAlignment: MainAxisAlignment.center,
      // crossAxisAlignment: CrossAxisAlignment.stretch,
      child: Column(
        children: [
          arfanifyIcon(),
          remoteControlButton(),
          autonomousButton(),
          cloudBackupButton()
        ],
      )
    );
  }
}

Image arfanifyIcon() {
  return const Image(
      image: AssetImage('assets/icons/Arfanify.png'),
      width: 150,
      height: 150,
      color: Colors.white,
    );
}


Container remoteControlButton(){
  return Container(
    margin: const EdgeInsets.all(10),
    height: 120,
    width: 180,
    
    child: ElevatedButton(
      onPressed: () {
        print("remote control pressed");
      },
      style: ElevatedButton.styleFrom (
        backgroundColor: const Color(0xff545454),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),  
      ),
       child: const Column(
        mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.settings_remote_sharp, size: 70), // Adjust the size as needed
            Text(
              'Remote Control',
              style: TextStyle(fontSize: 20),
            ),
          ],
      ),
    ),
  );
}

Container autonomousButton(){
  return Container(
    margin: const EdgeInsets.all(10),
    height: 110,
    width: 180,
    
    child: ElevatedButton(
      onPressed: () {
        print("autonomous button pressed"); // Use the variable within the print statement
      },
      style: ElevatedButton.styleFrom (
        backgroundColor: const Color(0xff545454),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),  
      ),
       child: const Column(
        mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.map_outlined, size: 70), // Adjust the size as needed
            Text(
              'Autonomous',
              style: TextStyle(fontSize: 20),
            ),
          ],
      ),
    ),
  );
}

Container cloudBackupButton(){
  return Container(
    margin: const EdgeInsets.all(10),
    height: 110,
    width: 180,
    
    child: ElevatedButton(
      onPressed: () {
        print("cloud backup button pressed"); // Use the variable within the print statement
      },
      style: ElevatedButton.styleFrom (
        backgroundColor: const Color(0xff545454),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),  
      ),
       child: const Column(
        mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.cloud_done, size: 70), // Adjust the size as needed
            Text(
              'Cloud Backup',
              style: TextStyle(fontSize: 20),
            ),
          ],
      ),
    ),
  );
}