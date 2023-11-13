import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;

class AutonomousPage extends StatelessWidget {
  const AutonomousPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Icon(
          Icons.map_outlined,
          color: Colors.white,
          size: 200,
        ),
      ],
    );
  }
}

class AutonomousPagee extends StatefulWidget {
  const AutonomousPagee({super.key});

  @override
  State<AutonomousPagee> createState() => _AutonomousPagee();
}

class _AutonomousPagee extends State<AutonomousPagee> {
  static const _intialCamPos =
      CameraPosition(target: LatLng(3.2085263, 101.7792612), zoom: 20);

  late GoogleMapController _mapsController;
  late String _darkMapStyle;

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Future _loadMapStyles() async {
    _darkMapStyle = await rootBundle.loadString('assets/json/map_style.json');
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  @override
  void initState() {
    super.initState();
    _loadMapStyles(); //load the dark mode map json file design
  }

  @override
  void dispose() {
    _mapsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(
          height: 20,
        ),
        Center(
          child: Container(
              height: 500,
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(10)),
              child: GoogleMap(
                mapType: MapType.normal,
                myLocationButtonEnabled: false,
                initialCameraPosition: _intialCamPos,
                onMapCreated: (GoogleMapController controller) {
                  _mapsController = controller;
                  _mapsController.setMapStyle(_darkMapStyle);
                },
              )),
        )
      ],
    );
  }
}
