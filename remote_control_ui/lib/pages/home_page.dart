import 'package:flutter/material.dart';
import 'package:remote_control_ui/pages/ble_section.dart';
import 'package:remote_control_ui/pages/remote_control_page.dart';
import 'package:remote_control_ui/pages/autonomous_page.dart';

class HomePage extends StatefulWidget {
  final double safeScreenHeight;
  final double safeScreenWidth;
  const HomePage({
    super.key,
    required this.safeScreenHeight,
    required this.safeScreenWidth,
  });

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final PageStorageBucket _bucket = PageStorageBucket();

  //initialize controller for BLE widget
  final BLEcontroller myBLEController = BLEcontroller();

  final remoteModeController myRemoteController = remoteModeController();

  final autoModeController myAutoController = autoModeController();

  // for better scaling of widgets with different screen sizes
  late double _safeVertical;
  late double _safeHorizontal;

  //Use BLE widget controller to send data to BLE widget
  void sendBLEwidget(List<int> message) {
    //Send message to BLE widget
    myBLEController.sendDataBLE(message);
  }

  void sendToRemotePage() {}

  @override
  void initState() {
    super.initState();

    // initialize the variables
    _safeVertical = widget.safeScreenHeight;
    _safeHorizontal = widget.safeScreenWidth;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          SizedBox(
            height: _safeVertical * 5,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              mainPageTitle(),
            ],
          ),
          SizedBox(
            height: _safeVertical * 2,
          ),
          Center(
            child: modeSection(),
          ),
          SizedBox(
            height: _safeVertical * 2,
          ),
          Center(
            child: bleSection(),
          )
        ],
      ),
    );
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  SizedBox mainPageTitle() {
    return SizedBox(
      height: _safeVertical * 7,
      width: _safeHorizontal * 37,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Icon(
            Icons.directions_boat_filled,
            color: Colors.white,
            size: _safeVertical * 5,
          ),
          Text(
            'ARFANIFY',
            style: TextStyle(
              fontSize: _safeVertical * 2,
              color: Colors.white,
            ),
          )
        ],
      ),
    );
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Container modeSection() {
    return Container(
      height: _safeVertical * 23,
      width: _safeHorizontal * 100,
      decoration: BoxDecoration(
        color: const Color(0xffC8D0C8),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          SizedBox(
            height: _safeVertical,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                width: _safeVertical * 4,
              ),
              Text(
                "Modes",
                style: TextStyle(
                    fontSize: _safeHorizontal * 5,
                    color: Colors.black,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(
            height: _safeVertical,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              remotePageButton(),
              autoPageButton(),
            ],
          )
        ],
      ),
    );
  }

  SizedBox remotePageButton() {
    return SizedBox(
      height: _safeVertical * 15,
      width: _safeHorizontal * 40,
      child: ElevatedButton.icon(
        onPressed: () {
          //navigate to a remote page
          //navigate to the auto page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RemotePage(
                safeScreenHeight: _safeVertical,
                safeScreenWidth: _safeHorizontal,
                sendbLE: sendBLEwidget,
                notifyController: myRemoteController,
              ),
            ),
          );
        },
        icon: Icon(
          Icons.settings_remote_sharp,
          size: _safeVertical * 7,
          color: Colors.white,
        ),
        label: Text(
          'Remote',
          style: TextStyle(fontSize: _safeHorizontal * 4, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff768a76),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
        ),
      ),
    );
  }

  SizedBox autoPageButton() {
    return SizedBox(
      height: _safeVertical * 15,
      width: _safeHorizontal * 40,
      child: ElevatedButton.icon(
        onPressed: () {
          //navigate to the auto page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PageStorage(
                bucket: _bucket,
                child: AutoPage(
                  safeScreenHeight: _safeVertical,
                  safeScreenWidth: _safeHorizontal,
                  sendbLE: sendBLEwidget,
                  notifyController: myAutoController,
                ),
              ),
            ),
          );
        },
        icon: Icon(
          Icons.map_outlined,
          size: _safeVertical * 7,
          color: Colors.white,
        ),
        label: Text(
          'Auto',
          style: TextStyle(fontSize: _safeHorizontal * 4, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff768a76),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
        ),
      ),
    );
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Container bleSection() {
    return Container(
      height: _safeVertical * 63,
      width: _safeHorizontal * 100,
      decoration: BoxDecoration(
        color: const Color(0xffC8D0C8),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          SizedBox(
            height: _safeVertical,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                width: _safeVertical * 4,
              ),
              Text(
                "Bluetooth",
                style: TextStyle(
                    fontSize: _safeHorizontal * 5,
                    color: Colors.black,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(
            height: _safeVertical,
          ),
          // Defined in another class
          AppBarBLE(
            bleController: myBLEController,
            safeScreenHeight: _safeVertical,
            safeScreenWidth: _safeHorizontal,
          ),
        ],
      ),
    );
  }
}
