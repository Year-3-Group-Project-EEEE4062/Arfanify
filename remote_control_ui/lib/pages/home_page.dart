import 'package:flutter/material.dart';
import 'package:remote_control_ui/pages/ble_section.dart';

class HomePage extends StatefulWidget {
  final Function(int) updateScaffoldBody;
  final double safeScreenHeight;
  final double safeScreenWidth;
  const HomePage(
      {super.key,
      required this.updateScaffoldBody,
      required this.safeScreenHeight,
      required this.safeScreenWidth});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final BLEcontroller myController = BLEcontroller();
  Color buttonBackgroundColor = const Color.fromARGB(255, 95, 94, 94);
  Color buttonForegroundColor = Colors.white;

  // for better scaling of widgets with different screen sizes
  late double _safeVertical;
  late double _safeHorizontal;

  void buttonPressed(int index) {
    widget.updateScaffoldBody(index);
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
          mainPageTitle(),
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
              const Text(
                "Bluetooth",
                style: TextStyle(
                    fontSize: 20,
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
            controller: myController,
            safeScreenHeight: _safeVertical,
            safeScreenWidth: _safeHorizontal,
          ),
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
              const Text(
                "Modes",
                style: TextStyle(
                    fontSize: 20,
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
          buttonPressed(1);
        },
        icon: Icon(
          Icons.settings_remote_sharp,
          size: _safeVertical * 7,
          color: Colors.white,
        ),
        label: const Text(
          'Remote',
          style: TextStyle(fontSize: 17, color: Colors.white),
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
          buttonPressed(2);
        },
        icon: Icon(
          Icons.map_outlined,
          size: _safeVertical * 7,
          color: Colors.white,
        ),
        label: const Text(
          'Auto',
          style: TextStyle(fontSize: 17, color: Colors.white),
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
  Container mainPageTitle() {
    return Container(
      height: _safeVertical * 8,
      width: _safeHorizontal * 50,
      decoration: BoxDecoration(
        color: const Color(0xff768a76),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Icon(
            Icons.directions_boat_filled,
            color: Colors.white,
            size: _safeVertical * 5,
          ),
          const Text(
            'Arfanify',
            style: TextStyle(
              fontSize: 30,
              color: Colors.white,
            ),
          )
        ],
      ),
    );
  }
}
