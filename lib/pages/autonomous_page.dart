import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:interactive_bottom_sheet/interactive_bottom_sheet.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:toggle_switch/toggle_switch.dart';

class AutoPage extends StatefulWidget {
  final double safeScreenHeight;
  final double safeScreenWidth;
  final Function(List<int>) bLE;
  const AutoPage(
      {super.key,
      required this.safeScreenHeight,
      required this.safeScreenWidth,
      required this.bLE});

  @override
  State<AutoPage> createState() => _AutoPageState();
}

class _AutoPageState extends State<AutoPage> {
  // for better scaling of widgets with different screen sizes
  late double _safeVertical;
  late double _safeHorizontal;

  //Boolean to determine user has confirmed parameters for auto mode
  bool isWaypointsReady = false;
  int waypointsReadyIndex = 1;
  bool isParameterSettingsReady = false;
  int parameterSettingsReadyIndex = 1;

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

  void autoModeSendBLE(List<int> bLERemoteCommand) {
    debugPrint("Auto Mode BLE Callback Called");
    debugPrint("$bLERemoteCommand");

    //remote control sends a list of integers
    //each integer represents an action
    widget.bLE(bLERemoteCommand);
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  @override
  void initState() {
    super.initState();
    // initialize the variables
    _safeVertical = widget.safeScreenHeight;
    _safeHorizontal = widget.safeScreenWidth;

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
    debugPrint("Auto page disposed!");
    //Dispose the controller after everytime user navigates to a different page
    _mapsController.future.then((controller) {
      controller.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      bottomSheet: autoBottomSheet(context),
      body: Stack(
        children: [
          //for showing the map
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: currentUserLatLng == null
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 5,
                    ),
                  )
                // : Container(
                //     decoration: const BoxDecoration(color: Colors.blueGrey),
                //   ),
                : theMap(),
          ),

          //for positioning the home button onto the map
          Positioned(
            top: _safeVertical * 5,
            right: _safeHorizontal * 1,
            child: SizedBox(
              height: _safeVertical * 7,
              width: _safeHorizontal * 20,
              child: homeButton(context),
            ),
          ),
          //For positioning the title of the page
          Positioned(
            top: _safeVertical * 5,
            left: _safeHorizontal * 1,
            child: autoPageTitle(),
          ),

          //For positioning the map button
          Positioned(
            top: _safeVertical * 53,
            right: _safeHorizontal * 2,
            child: _getUserLocationButton(),
          ),
          Positioned(
            top: _safeVertical * 61,
            right: _safeHorizontal * 2,
            child: _generatePolylineButton(),
          ),
          Positioned(
            top: _safeVertical * 69,
            right: _safeHorizontal * 2,
            child: _removeAllMarkers(),
          )
        ],
      ),
    );
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///Bottom sheet widget
  InteractiveBottomSheet autoBottomSheet(BuildContext context) {
    return InteractiveBottomSheet(
      options: InteractiveBottomSheetOptions(
        // initialSize: _safeVertical * 0.031,
        // minimumSize: _safeHorizontal * 0.031,
        maxSize: _safeVertical * 0.114,
        snapList: [0.25, 0.5],
      ),
      draggableAreaOptions: const DraggableAreaOptions(topBorderRadius: 30),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [_waypointsListViewerSection(context)],
            ),
            SizedBox(
              height: _safeVertical * 1,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [_parameterSettingsSection(context)],
            ),
            SizedBox(
              height: _safeVertical * 1,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [_parameterSettingsSection(context)],
            ),
          ],
        ),
      ),
    );
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///for waypoint checker to work
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
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
              color: const Color(0xff171717),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 10.0,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Waypoint No.${index + 1}",
                      style: TextStyle(
                          fontSize: _safeVertical * 2,
                          fontWeight: FontWeight.bold,
                          color: Colors.red),
                    ),
                    SizedBox(
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Locate',
                              style: TextStyle(
                                fontSize: _safeVertical * 1.5,
                                color: Colors.white,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Latitude:\n${marker.position.latitude}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        "Longitude:\n${marker.position.longitude}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Container _waypointsListViewerSection(BuildContext context) {
    List<Marker> pathWaypointsList = pathWaypoints.toList();
    return Container(
        height: _safeVertical * 31,
        width: _safeHorizontal * 90,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color(0xffC8D0C8)),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Waypoints Checker",
                    style: TextStyle(
                        fontSize: _safeVertical * 2,
                        color: Colors.black,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: _safeVertical * 3.5,
                    child: ToggleSwitch(
                      customWidths: [
                        _safeHorizontal * 15,
                        _safeHorizontal * 10
                      ],
                      cornerRadius: 30.0,
                      activeBgColors: const [
                        [Colors.green],
                        [Colors.redAccent]
                      ],
                      initialLabelIndex: waypointsReadyIndex,
                      activeFgColor: Colors.white,
                      inactiveBgColor: Colors.grey,
                      inactiveFgColor: Colors.white,
                      totalSwitches: 2,
                      icons: const [Icons.check, Icons.cancel],
                      onToggle: (index) {
                        debugPrint('Waypoint Checker switched to: $index');

                        setState(() {
                          waypointsReadyIndex = index!;
                          //int 1 indicates not ready
                          //int 0 indicates ready
                          //this is due to how the toggle switch index is placed
                          //where ready button on index 0 and NOT ready button on index 1
                          if (index == 0) {
                            isWaypointsReady = true;
                          } else if (index == 1) {
                            isWaypointsReady = false;
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: _safeVertical * 0.5,
              ),
              SizedBox(
                child: Text(
                  "Number of waypoints: ${pathWaypointsList.length}",
                  style: TextStyle(
                      fontSize: _safeHorizontal * 4, color: Colors.grey),
                ),
              ),
              SizedBox(
                height: _safeVertical * 0.5,
              ),
              Container(
                height: _safeVertical * 20,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.black),
                child: (pathWaypointsList.isNotEmpty)
                    ? (!isWaypointsReady)
                        ? Flex(
                            direction: Axis.vertical,
                            children: [
                              _waypointListBuilder(pathWaypointsList, context),
                            ],
                          )
                        : Center(
                            child: Text("Confirmed Waypoints",
                                style: TextStyle(
                                    fontSize: _safeHorizontal * 5,
                                    color: Colors.white)),
                          )
                    : Center(
                        child: Text("No waypoints set!",
                            style: TextStyle(
                                fontSize: _safeHorizontal * 5,
                                color: Colors.white)),
                      ),
              ),
            ],
          ),
        ));
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///widgets in parameter settings in bottom sheet
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

  Container _parameterSettingsSection(BuildContext context) {
    return Container(
      height: _safeVertical * 31,
      width: _safeHorizontal * 90,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xffC8D0C8)),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Parameter Settings",
                  style: TextStyle(
                      fontSize: _safeVertical * 2,
                      color: Colors.black,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: _safeVertical * 3.5,
                  child: ToggleSwitch(
                    customWidths: [_safeHorizontal * 15, _safeHorizontal * 10],
                    cornerRadius: 30.0,
                    activeBgColors: const [
                      [Colors.green],
                      [Colors.redAccent]
                    ],
                    initialLabelIndex: parameterSettingsReadyIndex,
                    activeFgColor: Colors.white,
                    inactiveBgColor: Colors.grey,
                    inactiveFgColor: Colors.white,
                    totalSwitches: 2,
                    icons: const [Icons.check, Icons.cancel],
                    onToggle: (index) {
                      debugPrint('Parameter setting switched to: $index');

                      setState(() {
                        parameterSettingsReadyIndex = index!;
                        //int 1 indicates not ready
                        //int 0 indicates ready
                        //this is due to how the toggle switch index is placed
                        //where ready button on index 0 and NOT ready button on index 1
                        if (index == 0) {
                          isParameterSettingsReady = true;
                        } else if (index == 1) {
                          isParameterSettingsReady = false;
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(
              child: Column(
                children: [
                  SizedBox(
                    height: _safeVertical * 1,
                  ),
                  _speedSection(),
                  SizedBox(
                    height: _safeVertical * 1.5,
                  ),
                  _frequencySection(),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Container _summaryViewerPopUp(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      height: _safeVertical * 20,
      width: _safeHorizontal * 90,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xffC8D0C8)),
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
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///Map related features
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  // created method for getting user current location
  SizedBox _getUserLocationButton() {
    return SizedBox(
      height: _safeVertical * 7,
      width: _safeHorizontal * 20,
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
          backgroundColor: const Color.fromARGB(255, 33, 33, 33),
          shape: const CircleBorder(),
          side: const BorderSide(color: Colors.black),
        ),
        child: const Icon(
          Icons.my_location,
          color: Colors.blue,
        ),
      ),
    );
  }

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
  //Title of the page
  SizedBox autoPageTitle() {
    return SizedBox(
      height: _safeVertical * 7,
      width: _safeHorizontal * 30,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Icon(
            Icons.map_outlined,
            color: Colors.white,
            size: _safeVertical * 5,
          ),
          Text(
            '> Auto',
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
  //home button to return back to home page
  OutlinedButton homeButton(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        // Pop context to return back to the home page
        Navigator.pop(context);
      },
      style: OutlinedButton.styleFrom(
        side: const BorderSide(
          width: 3,
          color: Colors.white,
          style: BorderStyle.solid,
        ),
        backgroundColor: const Color(0xff768a76), // Outline color
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(30), // Adjust the border radius as needed
        ),
      ),
      child: Center(
        child: Icon(
          Icons.home_filled,
          color: Colors.white,
          size: _safeVertical * 4,
        ),
      ),
    );
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///Polyline button widget related
  SizedBox _generatePolylineButton() {
    return SizedBox(
      height: _safeVertical * 7,
      width: _safeHorizontal * 20,
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
              shape: const CircleBorder(),
              side: const BorderSide(color: Colors.black),
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

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///remove all marker widget related
  SizedBox _removeAllMarkers() {
    return SizedBox(
      height: _safeVertical * 7,
      width: _safeHorizontal * 20,
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            if (pathWaypoints.isNotEmpty) {
              pathWaypoints.clear();
              //reset the toggle switch for waypoints
              waypointsReadyIndex = 1;
              if (pathPolylines.isNotEmpty) {
                pathPolylines.clear();
                _changePolylineButtonColor();
              }
            }
          });
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 33, 33, 33),
          shape: const CircleBorder(),
          side: const BorderSide(color: Colors.black),
        ),
        child: const Icon(
          Icons.location_off,
          color: Colors.red,
        ),
      ),
    );
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
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
}
