import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;

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
      children: [
        const SizedBox(height: 20),
        Center(
          child: Container(
              height: 500,
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(10)),
              child: GoogleMap(
                mapType: MapType.normal,
                zoomControlsEnabled: false,
                compassEnabled: true,
                initialCameraPosition: _intialCamPos,
                onMapCreated: (GoogleMapController controller) {
                  _mapsController = controller;
                  _mapsController.setMapStyle(_darkMapStyle);
                },
              )),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          width: 70,
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              side: const BorderSide(color: Color.fromARGB(255, 255, 255, 255)),
            ),
            child: const Icon(
              Icons.location_searching,
              color: Color.fromARGB(255, 255, 255, 255),
            ),
          ),
        )
      ],
    );
  }
}
