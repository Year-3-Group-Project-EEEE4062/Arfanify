import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:interactive_bottom_sheet/interactive_bottom_sheet.dart';
import 'package:flutter/services.dart' show ByteData, Uint8List, rootBundle;
import 'package:remote_control_ui/converter/data_converter.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:floating_snackbar/floating_snackbar.dart';
import 'dart:ui' as ui;

//controller for the BLE
class AutoModeController {
  late void Function(List<dynamic>) notifyBLE;
  void Function(bool)? bleStat;
}

class AutoPage extends StatefulWidget {
  final double safeScreenHeight;
  final double safeScreenWidth;
  final Function(int) updatePageIndex;
  final bool bleStat;
  final Function(List<int>) sendbLE;
  final AutoModeController notifyController;
  const AutoPage({
    super.key,
    required this.safeScreenHeight,
    required this.safeScreenWidth,
    required this.updatePageIndex,
    required this.bleStat,
    required this.sendbLE,
    required this.notifyController,
  });

  @override
  State<AutoPage> createState() => _AutoPageState(notifyController);
}

class _AutoPageState extends State<AutoPage> {
  _AutoPageState(AutoModeController notifyController) {
    notifyController.notifyBLE = autoModeNotifyBLE;
    notifyController.bleStat = updateBLEStat;
  }

  // for better scaling of widgets with different screen sizes
  late double _safeVertical;
  late double _safeHorizontal;

  late IconData bleStatLogo;

  //Boolean to determine user has confirmed parameters for auto mode
  bool isWaypointsReady = false;
  int waypointsReadyIndex = 1;

  Position? currentUserLatLng;
  final Completer<GoogleMapController> _mapsController = Completer();
  late String _darkMapStyle;

  int maxMarkerToMarkerDistance = 100; //max 100 meters
  int maxMarkerToUserDistance = 1000; //1km
  Set<Marker> pathWaypoints = {};
  int markerCounter = 0;
  late int userMarkerIndex;
  late Uint8List userIcon;
  late Uint8List markerIcon;
  late Uint8List boatIcon;
  late int boatMarkerIndex;

  List<LatLng> markersLatLng = [];

  Set<Polyline> pathPolylines = {};
  ValueNotifier<Color> polylineButtonColor = ValueNotifier<Color>(Colors.black);
  bool isPolylinesON = false;

  Timer? sendTimer;
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //function to change page back to home page
  void changeToHomePage() {
    // home page index is 0
    widget.updatePageIndex(0);
  }

  void updateBLEStat(bool status) {
    //first check if this widget mounted in widget tree or not
    if (mounted) {
      setState(() {
        if (status) {
          bleStatLogo = Icons.bluetooth_connected;
        } else {
          bleStatLogo = Icons.bluetooth_disabled;
        }
      });
    }
  }

  void autoModeSendBLE(var bLEAutoCommand, int dataType) {
    int autoModeIdentifier = 0x02;

    debugPrint("Auto Mode BLE Callback Called");

    Uint8List byteCommand;

    //dataType = 0 indicates that sending integers (instructions)
    //dataType = 1 indicates that sending doubles (waypoints)
    if (dataType == 0) {
      // Convert int list command to byte array
      byteCommand = integerToByteArray(autoModeIdentifier, bLEAutoCommand);
    } else {
      // Convert int list command to byte array
      byteCommand = floatToByteArray(autoModeIdentifier, bLEAutoCommand);
    }

    //remote control sends a list of integers
    //each integer represents an action
    widget.sendbLE(byteCommand);
  }

  void autoModeNotifyBLE(List<dynamic> notifybLEAuto) async {
    // First check if auto page mounted or not
    if (mounted) {
      debugPrint("New data for auto page");
      debugPrint("${notifybLEAuto[0]}");
      debugPrint("Data type: ${notifybLEAuto[0].runtimeType}");

      //Check what type of message is it
      if (notifybLEAuto[0] == 0) {
        // Message contains boat's location
        List<double> boatCoordinates = notifybLEAuto[1];
        LatLng boatLatLng = LatLng(boatCoordinates[0], boatCoordinates[1]);

        //means it is the location of the boat
        await _addBoatMarker(boatLatLng);
        await _newCameraPosition(boatLatLng);
      } else if (notifybLEAuto[0] == 1) {
        // Message contains how many waypoints boat has gotten so far
        List<int> current = notifybLEAuto[1];
        showSnackBar("Succesfuly sent waypoint No.${current[0]}", context);
      } else if (notifybLEAuto[0] == 2) {
        // Message contains the boat alerting user that all waypoints have been received
        // And the boat will start autonomous operation
        showSnackBar("Boat will start auto operation", context);
      }
    }
  }

  void showSnackBar(String snackMssg, BuildContext context) {
    FloatingSnackBar(
      message: snackMssg,
      context: context,
      textColor: Colors.black,
      // textStyle: const TextStyle(color: Colors.green),
      duration: const Duration(milliseconds: 2000),
      backgroundColor: const Color.fromARGB(255, 0, 221, 255),
    );
  }

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

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  Future<void> setCustomMarkerIcon() async {
    markerIcon = await getBytesFromAsset('assets/icons/pin.png', 200);
    boatIcon = await getBytesFromAsset('assets/icons/boatboat.png', 150);
    userIcon = await getBytesFromAsset('assets/icons/user.png', 150);
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  @override
  void initState() {
    super.initState();
    // initialize the variables
    _safeVertical = widget.safeScreenHeight;
    _safeHorizontal = widget.safeScreenWidth;

    //Set ble icon status
    if (widget.bleStat) {
      bleStatLogo = Icons.bluetooth_connected;
    } else {
      bleStatLogo = Icons.bluetooth_disabled;
    }

    _loadMapStyles(); //load the dark mode map json file design

    setCustomMarkerIcon(); //get the custom markers

    //set the map to user current location
    _getUserCurrentLocation().then((value) async {
      currentUserLatLng = value;
      _addUserMarker(LatLng(value.latitude, value.longitude));
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
                : theMap(),
          ),

          //for positioning the home button onto the map
          Positioned(
            top: _safeVertical * 5,
            right: _safeHorizontal * 1,
            child: SizedBox(
              height: _safeVertical * 7,
              width: _safeHorizontal * 48,
              child: SizedBox(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    bleStatus(),
                    SizedBox(width: _safeHorizontal * 3), //just empty space
                    homeButton(context),
                    SizedBox(width: _safeHorizontal * 1),
                  ],
                ),
              ),
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
            top: _safeVertical * 45,
            right: _safeHorizontal * 2,
            child: _getUserLocationButton(),
          ),

          Positioned(
            top: _safeVertical * 53,
            right: _safeHorizontal * 2,
            child: _getBoatLocationButton(),
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
        backgroundColor: Colors.white,
        maxSize: _safeVertical * 0.09,
        snapList: [0.25, _safeVertical * 0.09],
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
              children: [_summaryViewerPopUp(context)],
            ),
          ],
        ),
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
            currentUserLatLng = value; //update user current location
            _addUserMarker(LatLng(value.latitude, value.longitude));
            _newCameraPosition(LatLng(value.latitude, value.longitude));
          });
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: const CircleBorder(),
          side: const BorderSide(color: Colors.white),
        ),
        child: const Icon(
          Icons.my_location,
          color: Colors.blue,
        ),
      ),
    );
  }

  void _addUserMarker(LatLng point) {
    setState(
      () {
        userMarkerIndex = pathWaypoints.length;
        // Create a new marker with a unique id and the given position
        Marker marker = Marker(
          markerId: const MarkerId("User"),
          position: point,
          //icon: BitmapDescriptor.fromBytes(iconDataToBytes(Icon(Icons.directions_boat_filled,))),
          infoWindow: InfoWindow(
              title: "Last updated user location",
              snippet:
                  "Lat: ${point.latitude.toStringAsFixed(6)}, Lng: ${point.longitude.toStringAsFixed(6)}"),
          icon: BitmapDescriptor.fromBytes(userIcon),
        );
        // Add the marker to the set and update the state
        setState(
          () {
            pathWaypoints.add(marker);
          },
        );
      },
    );
  }

  // created method for getting user current location
  SizedBox _getBoatLocationButton() {
    return SizedBox(
      height: _safeVertical * 7,
      width: _safeHorizontal * 20,
      child: OutlinedButton(
        onPressed: () async {
          List<int> mssg = [0];
          //do something in here
          autoModeSendBLE(mssg, 0);
          showSnackBar("Fetching boat location...", context);
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: const CircleBorder(),
          side: const BorderSide(color: Colors.white),
        ),
        child: const Icon(
          Icons.directions_boat_filled,
          color: Colors.yellow,
        ),
      ),
    );
  }

  Future<void> _addBoatMarker(LatLng point) async {
    boatMarkerIndex = pathWaypoints.length;

    // Create a new marker with a unique id and the given position
    Marker marker = Marker(
      markerId: const MarkerId("Boatboat"),
      position: point,
      //icon: BitmapDescriptor.fromBytes(iconDataToBytes(Icon(Icons.directions_boat_filled,))),
      infoWindow: InfoWindow(
          title: "Last known Boatboat location",
          snippet:
              "Lat: ${point.latitude.toStringAsFixed(6)}, Lng: ${point.longitude.toStringAsFixed(6)}"),
      icon: BitmapDescriptor.fromBytes(boatIcon),
    );
    // Add the marker to the set and update the state
    setState(
      () {
        pathWaypoints.add(marker);
      },
    );
  }

  Future<void> _newCameraPosition(LatLng value) async {
    // create a new camera position with respect to the user's location
    CameraPosition cameraPosition = CameraPosition(
      target: value,
      zoom: 18,
    );

    //use future to get the object of the _mapsController to change its properties
    final GoogleMapController controller = await _mapsController.future;

    //animate the map panning to the user's current location
    controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    setState(() {});
  }

  void _addMarkerToMap(LatLng point) {
    if (!isWaypointsReady) {
      setState(
        () {
          markerCounter++;
          // Create a new marker with a unique id and the given position
          Marker marker = Marker(
            markerId: MarkerId("Waypoint No.$markerCounter"),
            position: point,
            //icon: BitmapDescriptor.fromBytes(iconDataToBytes(Icon(Icons.directions_boat_filled,))),
            infoWindow: InfoWindow(
                title: "Waypoint No.$markerCounter",
                snippet:
                    "Lat: ${point.latitude.toStringAsFixed(6)}, Lng: ${point.longitude.toStringAsFixed(6)}"),
            icon: BitmapDescriptor.fromBytes(markerIcon),
          );
          // Add the marker to the set and update the state
          setState(
            () {
              pathWaypoints.add(marker);
              markersLatLng.add(point);
            },
          );
        },
      );
    } else {
      showSnackBar("Cannot add as waypoints confirmed!", context);
    }
  }

  void _checkMarkerToUser(LatLng point) {
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
      showSnackBar("Marker dropped further than 1 km of user", context);
    }
  }

  GoogleMap theMap() {
    return GoogleMap(
      style: _darkMapStyle,
      buildingsEnabled: false,
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
      onLongPress: _checkMarkerToUser,
      onMapCreated: (GoogleMapController controller) async {
        //assigning the controller
        _mapsController.complete(controller);
      },
    );
  }

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Title of the page
  SizedBox autoPageTitle() {
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
            '> Auto',
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
  SizedBox bleStatus() {
    return SizedBox(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Icon(
            bleStatLogo,
            color: Colors.white,
            size: _safeVertical * 5,
          ),
        ],
      ),
    );
  }

//home button to return back to home page
  OutlinedButton homeButton(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        changeToHomePage();
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
  SizedBox _generatePolylineButton() {
    return SizedBox(
      height: _safeVertical * 7,
      width: _safeHorizontal * 20,
      child: OutlinedButton(
        onPressed: () {
          if (pathWaypoints.length >= 2) {
            setState(() {
              if (!isPolylinesON) {
                pathPolylines.clear();
                pathPolylines.add(
                  Polyline(
                    polylineId: const PolylineId('user'),
                    points: markersLatLng,
                    width: 2,
                    color: const Color.fromARGB(255, 96, 214, 99),
                  ),
                );
                _changePolylineButtonColor();
              } else {
                pathPolylines.clear();
                _changePolylineButtonColor();
              }
            });
          } else {
            showSnackBar("Add at least 2 waypoints on map", context);
          }
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: polylineButtonColor.value,
          shape: const CircleBorder(),
          side: const BorderSide(color: Colors.white),
        ),
        child: const Icon(
          Icons.polyline,
          color: Colors.orange,
        ),
      ),
    );
  }

  void _changePolylineButtonColor() {
    if (!isPolylinesON) {
      polylineButtonColor.value = const Color.fromARGB(255, 96, 214, 99);
      isPolylinesON = true;
    } else if (isPolylinesON) {
      polylineButtonColor.value = Colors.black;
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
            if (!isWaypointsReady) {
              pathWaypoints.clear();
              markerCounter = 0;
              markersLatLng.clear();

              //reset the toggle switch for waypoints
              waypointsReadyIndex = 1;

              //reset polylines to none
              if (pathPolylines.isNotEmpty && !isPolylinesON) {
                pathPolylines.clear();
                _changePolylineButtonColor();
              }
            } else {
              showSnackBar("Cannot remove as waypoints confirmed!", context);
            }
          });
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: const CircleBorder(),
          side: const BorderSide(color: Colors.white),
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

  Expanded _waypointListBuilder(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: markersLatLng.length,
        itemBuilder: (BuildContext context, int index) {
          LatLng marker = markersLatLng[index];
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
                          await _locateMarker(marker);
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
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "Latitude:\n${marker.latitude.toStringAsFixed(6)}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(
                        width: _safeHorizontal * 15,
                      ),
                      Text(
                        "Longitude:\n${marker.longitude.toStringAsFixed(6)}",
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
    return Container(
        height: _safeVertical * 33,
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
                        setState(() {
                          //int 1 indicates not ready
                          //int 0 indicates ready
                          //this is due to how the toggle switch index is placed
                          //where ready button on index 0 and NOT ready button on index 1
                          if (index == 0) {
                            if (pathWaypoints.length >= 2) {
                              waypointsReadyIndex = 0;
                              isWaypointsReady = true;
                            } else {
                              //this means no waypoints but user still confirm
                              waypointsReadyIndex = 1;
                            }
                          } else if (index == 1) {
                            waypointsReadyIndex = 1;
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
                  "Number of waypoints: ${markersLatLng.length}",
                  style: TextStyle(
                      fontSize: _safeHorizontal * 4, color: Colors.red),
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
                child: (markersLatLng.isNotEmpty)
                    ? (!isWaypointsReady)
                        ? Flex(
                            direction: Axis.vertical,
                            children: [
                              _waypointListBuilder(context),
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
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  double _calculateDistance() {
    double totalDistance = 0;
    for (int i = 0; i < markersLatLng.length; i++) {
      if (i < markersLatLng.length - 1) {
        // skip the last index
        totalDistance += _getStraightLineDistance(
            markersLatLng[i + 1].latitude,
            markersLatLng[i + 1].longitude,
            markersLatLng[i].latitude,
            markersLatLng[i].longitude);
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

  Container _totalDistance() {
    //get the estimated total distance travel
    double totalEstimatedDistance = _calculateDistance();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xff171717),
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
            "${totalEstimatedDistance.toStringAsFixed(2)} m",
            style: const TextStyle(
              fontSize: 15,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Container _waypointFrequency() {
    //get the estimated total distance travel
    double frequency = _calculateDistance() / markerCounter;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xff171717),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          const Text(
            "Waypoint every: ",
            style: TextStyle(
              fontSize: 15,
              color: Colors.white,
            ),
          ),
          Text(
            "${frequency.toStringAsFixed(2)} m",
            style: const TextStyle(
              fontSize: 15,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Padding _summaryContent() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _totalDistance(),
          _waypointFrequency(),
        ],
      ),
    );
  }

  Container _summaryViewerPopUp(BuildContext context) {
    return Container(
      height: _safeVertical * 33,
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
                  "Summary",
                  style: TextStyle(
                      fontSize: _safeVertical * 2,
                      color: Colors.black,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(
              child: Column(
                children: [
                  SizedBox(
                    height: _safeVertical * 1,
                  ),
                  Container(
                    height: _safeVertical * 17,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.black),
                    child: (markersLatLng.length >= 2)
                        ? _summaryContent()
                        : Center(
                            child: Text("Place at least 2 waypoints!",
                                style: TextStyle(
                                    fontSize: _safeHorizontal * 5,
                                    color: Colors.white)),
                          ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: _safeVertical * 1.5,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                sendButton(context),
                cancelButton(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  SizedBox cancelButton(BuildContext context) {
    return SizedBox(
      height: _safeVertical * 5,
      width: _safeHorizontal * 35,
      child: OutlinedButton(
        onPressed: () {
          setState(
            () {
              showSnackBar("Attempting to cancel ongoing operations!", context);

              // Send out cancel instruction to boat
              autoModeSendBLE([1], 0);
            },
          );
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.red,
          side: const BorderSide(color: Colors.black),
        ),
        child: const Text(
          "Cancel",
          style: TextStyle(
            fontSize: 15,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Future<void> sendWaypoints(List<List<double>> doubleTypeWaypoint) async {
    debugPrint("Started!!");

    // Add 2 second delay asynchronously before setting a periodic timer to send
    // waypoints every 2 seconds
    sendTimer = Timer.periodic(
      const Duration(seconds: 2),
      (timer) {
        if (timer.tick <= doubleTypeWaypoint.length) {
          debugPrint("Sending: ${doubleTypeWaypoint[timer.tick - 1]}");
          autoModeSendBLE(doubleTypeWaypoint[timer.tick - 1], 1);
        } else {
          timer.cancel();
          //Send BLE to let boat know how many waypoints it should have gotten
          autoModeSendBLE([3, doubleTypeWaypoint.length], 0);
        }
      },
    );
  }

  Future<List<List<double>>> packWaypoints() async {
    List<List<double>> latLngList = [];

    for (int i = 0; i < markersLatLng.length; i++) {
      latLngList.add([
        double.parse('2'),
        double.parse(markersLatLng[i].latitude.toStringAsFixed(6)),
        double.parse(markersLatLng[i].longitude.toStringAsFixed(6)),
      ]);
    }

    return latLngList;
  }

  SizedBox sendButton(BuildContext context) {
    return SizedBox(
      height: _safeVertical * 5,
      width: _safeHorizontal * 35,
      child: OutlinedButton(
        onPressed: () async {
          if (isWaypointsReady) {
            showSnackBar("Attempting to send to Medium...", context);

            //pack the waypoints from LatLng to type of 2D double list
            List<List<double>> doubleTypeWaypoint = await packWaypoints();

            //function to send BLE data with 1 second delay in between
            await sendWaypoints(doubleTypeWaypoint);
          } else {
            showSnackBar("Please confirm waypoints first", context);
          }
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: sendButtonColor(),
          side: const BorderSide(color: Colors.black),
        ),
        child: const Text(
          "Send",
          style: TextStyle(
            fontSize: 15,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Color sendButtonColor() {
    if (isWaypointsReady && (pathWaypoints.length >= 2)) {
      return Colors.green;
    } else {
      return const Color.fromARGB(255, 33, 33, 33);
    }
  }
}
