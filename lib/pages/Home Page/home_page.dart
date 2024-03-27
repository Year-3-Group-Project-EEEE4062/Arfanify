import 'package:flutter/material.dart';
import 'package:remote_control_ui/pages/Home%20Page/ble_section.dart';

//controller for the BLE
class HomePagecontroller {
  late void Function(List<int>) sendDataBLE;
}

class HomePage extends StatefulWidget {
  final double safeScreenHeight;
  final double safeScreenWidth;
  final Function(int) updatePageIndex;
  final Function(bool) updateTreeBLEStat;
  final Function(List<dynamic>) notifyRemoteNewBLE;
  final Function(List<dynamic>) notifyAutoNewBLE;
  final HomePagecontroller homeController;
  const HomePage({
    super.key,
    required this.safeScreenHeight,
    required this.safeScreenWidth,
    required this.updatePageIndex,
    required this.updateTreeBLEStat,
    required this.notifyRemoteNewBLE,
    required this.notifyAutoNewBLE,
    required this.homeController,
  });

  @override
  HomePageState createState() => HomePageState(homeController);
}

class HomePageState extends State<HomePage> {
  HomePageState(HomePagecontroller homeController) {
    homeController.sendDataBLE = sendBLEwidget;
  }

  //initialize controller for BLE widget
  final BLEcontroller myBLEController = BLEcontroller();

  // for better scaling of widgets with different screen sizes
  late double _safeVertical;
  late double _safeHorizontal;

  //function to change page back to home page
  void changePage(int index) {
    // home page index is 0
    widget.updatePageIndex(index);
  }

  //Use BLE widget controller to send data to BLE widget
  void sendBLEwidget(List<int> message) {
    //Send message to BLE widget
    myBLEController.sendDataBLE(message);
  }

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
            height: _safeVertical * 0.1,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ImageIcon(
            const AssetImage('assets/icons/arfanify.png'),
            color: Colors.white,
            size: _safeVertical * 8,
          ),
          Text(
            'ARFANIFY',
            style: TextStyle(
              fontSize: _safeVertical * 3,
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
          // In indexed stack, remote page is index 1
          changePage(1);
        },
        icon: Icon(
          Icons.settings_remote_sharp,
          size: _safeVertical * 7,
          color: Colors.white,
        ),
        label: Text(
          'Remote',
          style: TextStyle(fontSize: _safeHorizontal * 3, color: Colors.white),
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
          // In indexed stack, remote page is index 2
          changePage(2);
        },
        icon: Icon(
          Icons.map_outlined,
          size: _safeVertical * 7,
          color: Colors.white,
        ),
        label: Text(
          'Auto',
          style: TextStyle(fontSize: _safeHorizontal * 3, color: Colors.white),
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
            bleStat: widget.updateTreeBLEStat,
            notifyRemoteCB: widget.notifyRemoteNewBLE,
            notifyAutoCB: widget.notifyAutoNewBLE,
          ),
        ],
      ),
    );
  }
}
