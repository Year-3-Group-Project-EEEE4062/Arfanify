import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kumi_popup_window/kumi_popup_window.dart';
import 'package:flutter/services.dart' show rootBundle;

class AutonomousPagee extends StatefulWidget {
  const AutonomousPagee({super.key});

  @override
  State<AutonomousPagee> createState() => _AutonomousPagee();
}

class _AutonomousPagee extends State<AutonomousPagee> {
  static const _intialCamPos =
      CameraPosition(target: LatLng(3.2085263, 101.7792612), zoom: 0);

  final Completer<GoogleMapController> _mapsController = Completer();
  late String _darkMapStyle;
  Set<Marker> pathWaypoints = {};
  Set<Polyline> pathPolylines = {};
  ValueNotifier<Color> polylineButtonColor =
      ValueNotifier<Color>(const Color(0xff171717));
  bool isPolylinesON = false;

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
    //Dispose the controller after everytime user navigates to a different page
    _mapsController.future.then((controller) {
      controller.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
            height: 500,
            decoration: BoxDecoration(
              color: const Color(0xff171717),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Expanded(
                  child: theMap(),
                ),
                const SizedBox(height: 20),
              ],
            )),
        const SizedBox(height: 20), //spacing between map and controls
        Container(
          decoration: BoxDecoration(
            color: const Color(0xff171717),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 10), //layout spacing
              Column(children: [
                const SizedBox(height: 10), //layout spacing
                waypointsListViewerButton(),
                const SizedBox(height: 10), //layout spacing
              ]),
              const SizedBox(width: 10), //layout spacing
              Column(children: [
                const SizedBox(height: 10), //layout spacing
                parameterSettingsButton(),
                const SizedBox(height: 10), //layout spacing
              ]),
              const SizedBox(width: 10),
              Column(children: [
                const SizedBox(height: 10), //layout spacing
                summaryViewerButton(),
                const SizedBox(height: 10), //layout spacing
              ]),
              const SizedBox(width: 10), //layout spacing
              Container(
                height: 140,
                width: 3,
                decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 121, 121, 121),
                    borderRadius: BorderRadius.circular(20)),
              ),
              const SizedBox(width: 10), //layout spacing
              Column(
                children: [
                  const SizedBox(height: 10), //layout spacing
                  getUserLocation(),
                  const SizedBox(height: 10), //layout spacing
                  generatePolyline(),
                  const SizedBox(height: 10), //layout spacing
                  removeAllMarkers(),
                  const SizedBox(height: 10), //layout spacing
                ],
              ),
              const SizedBox(width: 10), //layout spacing
            ],
          ),
        )
      ],
    );
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  _addMarkerToMap(LatLng point) {
    //get how many markers have been dropped so far
    int waypointNumber = pathWaypoints.length;

    setState(() {
      // Create a new marker with a unique id and the given position
      Marker marker = Marker(
        markerId: MarkerId("Waypoint No.${waypointNumber + 1}"),
        position: point,
        //icon: BitmapDescriptor.fromBytes(iconDataToBytes(Icon(Icons.directions_boat_filled,))),
        infoWindow: InfoWindow(
            title: "Waypoint No.${waypointNumber + 1}",
            snippet: "Lat: ${point.latitude}, Lng: ${point.longitude}"),
      );
      // Add the marker to the set and update the state
      setState(() {
        debugPrint("Waypoint No.${waypointNumber + 1}");
        pathWaypoints.add(marker);

        //everytime a new marker dropped polylines reset and turned off
        if (pathPolylines.isNotEmpty) {
          pathPolylines.clear();
          changePolylineButtonColor();
        }
      });
    });
  }

  GoogleMap theMap() {
    return GoogleMap(
      mapType: MapType.normal,
      zoomControlsEnabled: false,
      compassEnabled: true,
      initialCameraPosition: _intialCamPos,
      markers: pathWaypoints,
      polylines: pathPolylines,
      onLongPress: _addMarkerToMap,
      onMapCreated: (GoogleMapController controller) async {
        //assigning the controller
        _mapsController.complete(controller);

        //use future to get the object of the _mapsController to change its properties
        final GoogleMapController settingMapStyle =
            await _mapsController.future;
        //use the object to set the Map's theme
        settingMapStyle.setMapStyle(_darkMapStyle);
      },
    );
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  // created method for getting user current location
  Future<Position> getUserCurrentLocation() async {
    await Geolocator.requestPermission()
        .then((value) {})
        .onError((error, stackTrace) async {
      await Geolocator.requestPermission();
      debugPrint("ERROR: $error");
    });
    return await Geolocator.getCurrentPosition();
  }

  SizedBox getUserLocation() {
    return SizedBox(
      height: 40,
      width: 70,
      child: OutlinedButton(
        onPressed: () async {
          getUserCurrentLocation().then((value) async {
            debugPrint(
                "User Current Location: ${value.latitude} , ${value.longitude}");

            // create a new camera position with respect to the user's location
            CameraPosition cameraPosition = CameraPosition(
              target: LatLng(value.latitude, value.longitude),
              zoom: 18,
            );

            //use future to get the object of the _mapsController to change its properties
            final GoogleMapController controller = await _mapsController.future;

            //animate the map panning to the user's current location
            controller
                .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
            setState(() {});
          });
        },
        style: OutlinedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          side: const BorderSide(color: Color.fromARGB(255, 255, 255, 255)),
        ),
        child: const Icon(
          Icons.my_location,
          color: Colors.blue,
        ),
      ),
    );
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  SizedBox removeAllMarkers() {
    return SizedBox(
      height: 40,
      width: 70,
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            if (pathWaypoints.isNotEmpty) {
              pathWaypoints.clear();
              pathPolylines.clear();
              changePolylineButtonColor();
            }
          });
        },
        style: OutlinedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          side: const BorderSide(color: Color.fromARGB(255, 255, 255, 255)),
        ),
        child: const Icon(
          Icons.location_off,
          color: Colors.red,
        ),
      ),
    );
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  _setPolylinesUsingMarkers() {
    //generate a list of LatLng based on the set markers by user
    List<LatLng> markerPositions =
        pathWaypoints.map((marker) => marker.position).toList();

    //generate the polylines
    Polyline polyline = Polyline(
      polylineId: const PolylineId('polyline'),
      points: markerPositions,
      width: 2,
      color: const Color.fromARGB(255, 96, 214, 99),
    );

    //refresh widget
    setState(() {
      debugPrint("Polylines generated!");
      pathPolylines.add(polyline);
    });
  }

  void changePolylineButtonColor() {
    if (!isPolylinesON) {
      polylineButtonColor.value = const Color.fromARGB(255, 96, 214, 99);
      isPolylinesON = true;
    } else {
      polylineButtonColor.value = const Color(0xff171717);
      isPolylinesON = false;
    }
  }

  SizedBox generatePolyline() {
    return SizedBox(
      height: 40,
      width: 70,
      child: ValueListenableBuilder(
        valueListenable: polylineButtonColor,
        builder: (context, value, _) {
          return OutlinedButton(
            onPressed: () {
              //only generate polylines if there are at least 2 markers on the map
              if (pathWaypoints.length >= 2 && !isPolylinesON) {
                debugPrint("Generating Polylines");

                //generate the polylines
                _setPolylinesUsingMarkers();

                //alert user of polyline change of state
                changePolylineButtonColor();
              } else if (isPolylinesON) {
                setState(() {
                  changePolylineButtonColor();
                  pathPolylines.clear();
                });
              }
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: polylineButtonColor.value,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              side: const BorderSide(color: Color.fromARGB(255, 255, 255, 255)),
            ),
            child: const Icon(
              Icons.polyline,
              color: Colors.yellow,
            ),
          );
        },
      ),
    );
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  KumiPopupWindow waypointsListViewerPopUp(BuildContext context) {
    List<Marker> pathWaypointsList = pathWaypoints.toList();

    return showPopupWindow(
      context,
      gravity: KumiPopupGravity.center,
      clickOutDismiss: true,
      clickBackDismiss: true,
      customAnimation: false,
      customPop: false,
      customPage: false,
      needSafeDisplay: true,
      underStatusBar: false,
      underAppBar: true,
      offsetX: 0,
      offsetY: -70,
      duration: const Duration(milliseconds: 200),
      childFun: (pop) {
        return Container(
            key: GlobalKey(),
            padding: const EdgeInsets.all(10),
            height: 350,
            width: 300,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10), color: Colors.white),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.black,
                  ),
                  padding: const EdgeInsets.all(10),
                  child: const Text(
                    "Waypoints Checker",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  child: Text(
                    "Number of waypoints: ${pathWaypointsList.length}",
                    style: const TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  height: 250,
                  decoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(10)),
                  child: (pathWaypointsList.isNotEmpty)
                      ? Flex(
                          direction: Axis.vertical,
                          children: [
                            waypointListBuilder(pathWaypointsList, context),
                          ],
                        )
                      : const Center(
                          child: Text("No waypoints set!",
                              style:
                                  TextStyle(fontSize: 20, color: Colors.grey)),
                        ),
                ),
              ],
            ));
      },
    );
  }

  Future<void> locateMarker(LatLng markerLocation) async {
    // create a new camera position with respect to the user's location
    CameraPosition cameraPosition = CameraPosition(
      target: LatLng(markerLocation.latitude, markerLocation.longitude),
      zoom: 20,
    );

    //use future to get the object of the _mapsController to change its properties
    final GoogleMapController controller = await _mapsController.future;

    //animate the map panning to the user's current location
    controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    setState(() {});
  }

  Expanded waypointListBuilder(
      List<Marker> pathWaypointsList, BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: pathWaypointsList.length,
        itemBuilder: (BuildContext context, int index) {
          Marker marker = pathWaypointsList[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 10,
            shadowColor: Colors.black,
            color: const Color(0xff171717),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.only(top: 5, bottom: 5, left: 15, right: 15),
              title: Text(
                "Waypoint No.${index + 1}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.red),
              ),
              subtitle: Text(
                "Latitude:\n${marker.position.latitude}\n\nLongitude:\n${marker.position.longitude}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white),
              ),
              trailing: SizedBox(
                height: 60,
                width: 60,
                child: OutlinedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await locateMarker(marker.position);
                  }, //do something here
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    side: const BorderSide(
                        color: Color.fromARGB(255, 255, 255, 255)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.location_searching,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  SizedBox waypointsListViewerButton() {
    return SizedBox(
      height: 140,
      width: 70,
      child: OutlinedButton(
          onPressed: () {
            waypointsListViewerPopUp(context);
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            side: const BorderSide(color: Color.fromARGB(255, 255, 255, 255)),
          ),
          child: const Center(
            child: Icon(
              Icons.edit_location_alt,
              color: Color.fromARGB(255, 255, 255, 255),
              size: 40,
            ),
          )),
    );
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  KumiPopupWindow parameterSettingsPopUp(BuildContext context) {
    return showPopupWindow(
      context,
      gravity: KumiPopupGravity.center,
      clickOutDismiss: true,
      clickBackDismiss: true,
      customAnimation: false,
      customPop: false,
      customPage: false,
      needSafeDisplay: true,
      underStatusBar: false,
      underAppBar: true,
      offsetX: 0,
      offsetY: -70,
      duration: const Duration(milliseconds: 200),
      childFun: (pop) {
        return Container(
          key: GlobalKey(),
          padding: const EdgeInsets.all(10),
          height: 350,
          width: 300,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10), color: Colors.white),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.black,
                ),
                padding: const EdgeInsets.all(10),
                child: const Text(
                  "Parameter Settings",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  SizedBox parameterSettingsButton() {
    return SizedBox(
      height: 140,
      width: 70,
      child: OutlinedButton(
          onPressed: () {
            parameterSettingsPopUp(context);
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            side: const BorderSide(color: Color.fromARGB(255, 255, 255, 255)),
          ),
          child: const Center(
            child: Icon(
              Icons.settings_suggest,
              color: Color.fromARGB(255, 255, 255, 255),
              size: 40,
            ),
          )),
    );
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  KumiPopupWindow summaryViewerPopUp(BuildContext context) {
    return showPopupWindow(
      context,
      gravity: KumiPopupGravity.center,
      clickOutDismiss: true,
      clickBackDismiss: true,
      customAnimation: false,
      customPop: false,
      customPage: false,
      needSafeDisplay: true,
      underStatusBar: false,
      underAppBar: true,
      offsetX: 0,
      offsetY: -70,
      duration: const Duration(milliseconds: 200),
      childFun: (pop) {
        return Container(
          key: GlobalKey(),
          padding: const EdgeInsets.all(10),
          height: 350,
          width: 300,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10), color: Colors.white),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.black,
                ),
                padding: const EdgeInsets.all(10),
                child: const Text(
                  "Summary",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  SizedBox summaryViewerButton() {
    return SizedBox(
      height: 140,
      width: 70,
      child: OutlinedButton(
          onPressed: () {
            summaryViewerPopUp(context);
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            side: const BorderSide(color: Color.fromARGB(255, 255, 255, 255)),
          ),
          child: const Center(
            child: Icon(
              Icons.summarize,
              color: Color.fromARGB(255, 255, 255, 255),
              size: 40,
            ),
          )),
    );
  }
}
