import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
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
  Position? currentUserLatLng;
  final Completer<GoogleMapController> _mapsController = Completer();
  late String _darkMapStyle;

  int maxMarkerToMarkerDistance = 100; //max 100 meters
  int maxMarkerToUserDistance = 1000; //1km
  Set<Marker> pathWaypoints = {};
  BitmapDescriptor userIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor waypointsIcon = BitmapDescriptor.defaultMarker;

  Set<Polyline> pathPolylines = {};
  ValueNotifier<Color> polylineButtonColor =
      ValueNotifier<Color>(const Color(0xff171717));
  bool isPolylinesON = false;

  double speedParameter = 0;
  String statusMssgSpeedParameter = 'Low';
  Color statusColorSpeedParameter = Colors.green;

  double frequencyParameter = 0;
  String statusMssgFrequencyParameter = 'every 10 m';
  Color statusColorFrequencyParameter = Colors.orange;

  double? totalEstimatedDistance;

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Future _loadMapStyles() async {
    _darkMapStyle = await rootBundle.loadString('assets/json/map_style.json');
  }

  Future<Position> _getUserCurrentLocation() async {
    await Geolocator.requestPermission()
        .then((value) {})
        .onError((error, stackTrace) async {
      await Geolocator.requestPermission();
      debugPrint("ERROR: $error");
    });
    return await Geolocator.getCurrentPosition();
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  @override
  void initState() {
    super.initState();
    _loadMapStyles(); //load the dark mode map json file design
    //set the map to user current location
    _getUserCurrentLocation().then((value) async {
      debugPrint(
          "User Current Location: ${value.latitude} , ${value.longitude}");
      currentUserLatLng = value;
      setState(() {}); //refresh the map with user location
    });
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
                  child: currentUserLatLng == null
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 5,
                          ),
                        )
                      : theMap(),
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
                _waypointsListViewerButton(),
                const SizedBox(height: 10), //layout spacing
              ]),
              const SizedBox(width: 10), //layout spacing
              Column(children: [
                const SizedBox(height: 10), //layout spacing
                _parameterSettingsButton(),
                const SizedBox(height: 10), //layout spacing
              ]),
              const SizedBox(width: 10),
              Column(children: [
                const SizedBox(height: 10), //layout spacing
                _summaryViewerButton(),
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
                  _getUserLocation(),
                  const SizedBox(height: 10), //layout spacing
                  _generatePolyline(),
                  const SizedBox(height: 10), //layout spacing
                  _removeAllMarkers(),
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
  void _addMarkerToMap(LatLng point) {
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
        icon: waypointsIcon,
      );
      // Add the marker to the set and update the state
      setState(() {
        debugPrint("Waypoint No.${waypointNumber + 1}");
        pathWaypoints.add(marker);

        //everytime a new marker dropped polylines reset and turned off
        if (pathPolylines.isNotEmpty) {
          pathPolylines.clear();
          _changePolylineButtonColor();
        }
      });
    });
  }

  void _checkMarkerToUser(LatLng point) {
    if (currentUserLatLng != null) {
      //first marker can only be dropped about 1 km from user current location
      //this is based on Medium's max comms range (1.1km)
      //get the distance between user and the supposed first marker
      double distance = Geolocator.distanceBetween(
        currentUserLatLng!.latitude,
        currentUserLatLng!.longitude,
        point.latitude,
        point.longitude,
      );

      //check the distance between the user and that supposed marker
      //make sure the distance is less than or equals to 1 km
      if (distance <= maxMarkerToUserDistance) {
        //add that user marker to map
        _addMarkerToMap(point);
      } else {
        debugPrint(
            "Marker dropped further than $maxMarkerToUserDistance meters of user current location");
      }
    } else {
      debugPrint("Unable to obtain user current location!!");
    }
  }

  void _checkMarkerToMarker(LatLng point) {
    //get the latest marker or the last marker
    Marker lastMarker = pathWaypoints.last;

    //get the distance between user and the supposed first marker
    double distance = Geolocator.distanceBetween(
      lastMarker.position.latitude,
      lastMarker.position.longitude,
      point.latitude,
      point.longitude,
    );

    //check the distance between the user and that supposed marker
    //make sure the distance is less than or equals to 1 km
    if (distance <= maxMarkerToMarkerDistance) {
      //add that user marker to map
      _addMarkerToMap(point);
    } else {
      debugPrint(
          "Marker dropped further than $maxMarkerToMarkerDistance m than previous marker");
    }
  }

  GoogleMap theMap() {
    return GoogleMap(
      mapType: MapType.normal,
      zoomControlsEnabled: false,
      compassEnabled: true,
      initialCameraPosition: CameraPosition(
          target:
              //add a nullcheck for each lattitude and longitude
              LatLng(currentUserLatLng!.latitude, currentUserLatLng!.longitude),
          zoom: 18),
      markers: pathWaypoints,
      polylines: pathPolylines,
      onLongPress:
          pathWaypoints.isEmpty ? _checkMarkerToUser : _checkMarkerToMarker,
      onMapCreated: (GoogleMapController controller) async {
        debugPrint("Map initialized!");

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
  Future<void> _newCameraPosition(Position value) async {
    // create a new camera position with respect to the user's location
    CameraPosition cameraPosition = CameraPosition(
      target: LatLng(value.latitude, value.longitude),
      zoom: 18,
    );

    //use future to get the object of the _mapsController to change its properties
    final GoogleMapController controller = await _mapsController.future;

    //animate the map panning to the user's current location
    controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    setState(() {});
  }

  SizedBox _getUserLocation() {
    return SizedBox(
      height: 40,
      width: 70,
      child: OutlinedButton(
        onPressed: () async {
          _getUserCurrentLocation().then((value) async {
            debugPrint(
                "User Current Location: ${value.latitude} , ${value.longitude}");
            currentUserLatLng = value; //update user current location
            _newCameraPosition(value);
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
  _setPolylinesUsingMarkers() {
    //generate a list of LatLng based on the set markers by user
    List<LatLng> markerPositions =
        pathWaypoints.map((marker) => marker.position).toList();

    debugPrint("$markerPositions");

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
      debugPrint("$pathPolylines");
    });
  }

  void _changePolylineButtonColor() {
    debugPrint("isPolylinesON: $isPolylinesON");
    if (!isPolylinesON) {
      polylineButtonColor.value = const Color.fromARGB(255, 96, 214, 99);
      isPolylinesON = true;
    } else if (isPolylinesON) {
      polylineButtonColor.value = const Color(0xff171717);
      isPolylinesON = false;
    }
  }

  SizedBox _generatePolyline() {
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
                _changePolylineButtonColor();
              } else if (isPolylinesON) {
                setState(() {
                  _changePolylineButtonColor();
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
  SizedBox _removeAllMarkers() {
    return SizedBox(
      height: 40,
      width: 70,
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            if (pathWaypoints.isNotEmpty) {
              pathWaypoints.clear();
              if (pathPolylines.isNotEmpty) {
                pathPolylines.clear();
                _changePolylineButtonColor();
              }
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
  KumiPopupWindow _waypointsListViewerPopUp(BuildContext context) {
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
                            _waypointListBuilder(pathWaypointsList, context),
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

  Future<void> _locateMarker(LatLng markerLocation) async {
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

  Expanded _waypointListBuilder(
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
                    await _locateMarker(marker.position);
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

  SizedBox _waypointsListViewerButton() {
    return SizedBox(
      height: 140,
      width: 70,
      child: OutlinedButton(
          onPressed: () {
            _waypointsListViewerPopUp(context);
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
  KumiPopupWindow _parameterSettingsPopUp(BuildContext context) {
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
              _speedSection(),
              const SizedBox(height: 10),
              _frequencySection(),
            ],
          ),
        );
      },
    );
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Container _frequencySection() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.black,
      ),
      padding: const EdgeInsets.all(10),
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Column(
            children: [
              _frequencyStatusRow(context, setState),
              _frequencySetter(context, setState),
            ],
          );
        },
      ),
    );
  }

  Row _frequencyStatusRow(BuildContext context, StateSetter setState) {
    return Row(
      children: [
        const Text(
          "Frequency: ",
          style: TextStyle(color: Colors.white),
        ),
        Text(
          statusMssgFrequencyParameter,
          style: TextStyle(color: statusColorFrequencyParameter),
        ),
      ],
    );
  }

  String _changeFrequency() {
    String label = '';
    if (frequencyParameter == 0.0) {
      label = 'every 10 m';
    } else if (frequencyParameter == 2.0) {
      label = 'every 20 m';
    } else if (frequencyParameter == 4.0) {
      label = 'every 30 m';
    }
    return label;
  }

  SliderTheme _frequencySetter(BuildContext context, StateSetter setState) {
    return SliderTheme(
      data: const SliderThemeData(
        thumbColor: Colors.white,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10),
        activeTrackColor: Color(0xff545454),
        inactiveTrackColor: Colors.grey,
        inactiveTickMarkColor: Colors.white,
        trackHeight: 10,
      ),
      child: Slider(
        value: frequencyParameter,
        min: 0.0,
        max: 4.0,
        divisions: 2,
        onChanged: (value) {
          setState(() {
            frequencyParameter = value;
            statusMssgFrequencyParameter = _changeFrequency();
          });
        },
      ),
    );
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Container _speedSection() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.black,
      ),
      padding: const EdgeInsets.all(10),
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Column(
            children: [
              _speedStatusRow(context, setState),
              _speedSetter(context, setState),
            ],
          );
        },
      ),
    );
  }

  Row _speedStatusRow(BuildContext context, StateSetter setState) {
    return Row(
      children: [
        const Text(
          "Speed: ",
          style: TextStyle(color: Colors.white),
        ),
        Text(
          statusMssgSpeedParameter,
          style: TextStyle(color: statusColorSpeedParameter),
        ),
      ],
    );
  }

  String _changeMode() {
    String label = '';
    if (speedParameter == 0.0) {
      label = 'Low';
    } else if (speedParameter == 2.0) {
      label = 'Average';
    } else if (speedParameter == 4.0) {
      label = 'Fast';
    }
    return label;
  }

  Color _changeModeColor() {
    Color modeColor = Colors.green;
    if (speedParameter == 0.0) {
      modeColor = Colors.green;
    } else if (speedParameter == 2.0) {
      modeColor = Colors.yellow;
    } else if (speedParameter == 4.0) {
      modeColor = Colors.orange;
    }
    return modeColor;
  }

  SliderTheme _speedSetter(BuildContext context, StateSetter setState) {
    return SliderTheme(
      data: const SliderThemeData(
        thumbColor: Colors.white,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10),
        activeTrackColor: Color(0xff545454),
        inactiveTrackColor: Colors.grey,
        inactiveTickMarkColor: Colors.white,
        trackHeight: 10,
      ),
      child: Slider(
        value: speedParameter,
        min: 0.0,
        max: 4.0,
        divisions: 2,
        onChanged: (value) {
          setState(() {
            speedParameter = value;
            statusMssgSpeedParameter = _changeMode();
            statusColorSpeedParameter = _changeModeColor();
          });
        },
      ),
    );
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  SizedBox _parameterSettingsButton() {
    return SizedBox(
      height: 140,
      width: 70,
      child: OutlinedButton(
          onPressed: () {
            _parameterSettingsPopUp(context);
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
  KumiPopupWindow _summaryViewerPopUp(BuildContext context) {
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
              //only show summary if user has more than 2 waypoints on the map
              (pathWaypoints.length >= 2)
                  ? _summaryContent()
                  : const SizedBox(
                      height: 250,
                      child: Center(
                        child: Text("Must have at least\ntwo waypoints set!",
                            style: TextStyle(fontSize: 20, color: Colors.grey)),
                      )),
            ],
          ),
        );
      },
    );
  }

  Container _summaryContent() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.black,
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          const Text(
            "Estimated Total Distance: ",
            style: TextStyle(
              fontSize: 15,
              color: Colors.white,
            ),
          ),
          Text(
            "${totalEstimatedDistance!.toStringAsFixed(2)} m",
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateDistance() {
    List<Marker> pathWaypointsList = pathWaypoints.toList();

    double totalDistance = 0;
    for (int i = 0; i < pathWaypointsList.length; i++) {
      if (i < pathWaypointsList.length - 1) {
        // skip the last index
        totalDistance += _getStraightLineDistance(
            pathWaypointsList[i + 1].position.latitude,
            pathWaypointsList[i + 1].position.longitude,
            pathWaypointsList[i].position.latitude,
            pathWaypointsList[i].position.longitude);
      }
    }
    return totalDistance;
  }

  //straight line distance calculation based on HaverSine formula
  double _getStraightLineDistance(lat1, lon1, lat2, lon2) {
    var R = 6371; // Radius of the earth in km
    var dLat = _deg2rad(lat2 - lat1);
    var dLon = _deg2rad(lon2 - lon1);
    var a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    var c = 2 * atan2(sqrt(a), sqrt(1 - a));
    var d = R * c; // Distance in km
    return d * 1000; //in m
  }

  dynamic _deg2rad(deg) {
    return deg * (pi / 180);
  }

  SizedBox _summaryViewerButton() {
    return SizedBox(
      height: 140,
      width: 70,
      child: OutlinedButton(
          onPressed: () {
            //only calculate the estimated total distance if there are at least two waypoints
            if (pathWaypoints.length >= 2) {
              totalEstimatedDistance = _calculateDistance();
            }
            _summaryViewerPopUp(context);
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
