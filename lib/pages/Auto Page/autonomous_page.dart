import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart' show ByteData, Uint8List, rootBundle;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:remote_control_ui/converter/data_converter.dart';
import 'package:remote_control_ui/pages/Auto%20Page/send_pop_up.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:floating_snackbar/floating_snackbar.dart';
import 'package:excel/excel.dart' as xcel;

//controller for the BLE
class AutoPageController {
  late void Function(List<dynamic>) notifyBLE;
  void Function(bool)? bleStat;
}

class AutoPage extends StatefulWidget {
  final double safeScreenHeight;
  final double safeScreenWidth;
  final Function(int) updatePageIndex;
  final bool bleStat;
  final Function(List<int>) sendbLE;
  final AutoPageController notifyController;
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
  _AutoPageState(AutoPageController notifyController) {
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

  late StreamSubscription<Position> positionStream;
  LatLng? currentUserLoc;
  final Completer<GoogleMapController> _mapsController = Completer();
  late String _darkMapStyle;

  Set<Marker> mapMarkers = {};
  int markerCounter = 0;
  late Uint8List userIcon;
  late Uint8List markerIcon;
  late Uint8List boatIcon;

  List<LatLng> markersLatLng = [];

  LatLng? currentBoatLoc;
  List<LatLng> boatpathLatLng = [];

  Polyline? lakeBoundary;

  Set<Polyline> pathPolylines = {};
  ValueNotifier<Color> polylineButtonColor = ValueNotifier<Color>(Colors.black);
  bool isPolylinesON = false;

  Timer? sendTimer;
  SendAlertDialogController mySendDialog = SendAlertDialogController();
  bool autonomousStart = false;
  int boatCompleted = 0;
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
    debugPrint("Some: $notifybLEAuto");
    // First check if auto page mounted or not
    if (mounted) {
      debugPrint("New data for auto page");
      //Check what type of message is it
      if (notifybLEAuto[0] == 0) {
        // Message contains boat's location
        currentBoatLoc = LatLng(notifybLEAuto[1], notifybLEAuto[2]);

        if (autonomousStart) boatpathLatLng.add(currentBoatLoc!);
        await _addBoatMarker(currentBoatLoc!);
        await _newCameraPosition(currentBoatLoc!);
      } else if (notifybLEAuto[0] == 1) {
        // Message contains how many waypoints boat has gotten so far
        mySendDialog.updateCounter(notifybLEAuto[1]);
      } else if (notifybLEAuto[0] == 2) {
        // Message contains the boat alerting user that all waypoints have been received
        // And the boat will start autonomous operation
        autonomousStart = true;
        showSnackBar("Boat will start auto operation");
      } else if (notifybLEAuto[0] == 3) {
        // Message indicates boat failed to receive all waypoints
        showSnackBar("Boat failed to received all waypoints, send again..");
      } else if (notifybLEAuto[0] == 4) {
        // Message indicates cancel operation successful
        autonomousStart = false;
        showSnackBar("Operation cancelled");
        setState(() {});
      } else if (notifybLEAuto[0] == 5) {
        // Message indicates that auto mode finished already
        autonomousStart = false;
        showSnackBar("Autonomous operation finished");
        setState(() {});
      } else if (notifybLEAuto[0] == 6) {
        // Message indicates how many waypoints boat has finished
        boatCompleted = notifybLEAuto[1];
        showSnackBar("Autonomous operation finished");
        setState(() {});
      }
    }
  }

  void showSnackBar(String snackMssg) {
    FloatingSnackBar(
      message: snackMssg,
      context: context,
      textColor: Colors.black,
      // textStyle: const TextStyle(color: Colors.green),
      duration: const Duration(milliseconds: 2000),
      backgroundColor: Colors.grey,
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

  // Extract lat and lng from excel file
  Future<void> getLakeBoundary() async {
    List<LatLng> lakeBoundaryLatLng = [];
    ByteData data = await rootBundle.load('assets/Lake Boundary.xlsx');
    var bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    var excel = xcel.Excel.decodeBytes(bytes);

    for (var table in excel.tables.keys) {
      for (var row in excel.tables[table]!.rows) {
        final value1 = row[1]!.value;
        final value2 = row[2]!.value;
        final double lakeLat =
            value1 != null ? double.tryParse(value1.toString()) ?? 0.0 : 0.0;
        final double lakeLng =
            value2 != null ? double.tryParse(value2.toString()) ?? 0.0 : 0.0;
        debugPrint('$lakeLat, $lakeLng');
        lakeBoundaryLatLng.add(LatLng(lakeLat, lakeLng));
      }
    }

    lakeBoundaryLatLng.removeAt(0);

    lakeBoundary = Polyline(
      polylineId: const PolylineId('lake'),
      points: lakeBoundaryLatLng,
      width: 2,
      color: const Color.fromARGB(255, 255, 13, 13),
    );
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

    //load the dark mode map json file design
    _loadMapStyles();

    //get the custom markers
    setCustomMarkerIcon();

    // Draw Nottingham lake boundary onto map
    getLakeBoundary();

    //set the map to user current location
    _getUserCurrentLocation().then((value) async {
      currentUserLoc = LatLng(value.latitude, value.longitude);
      _addUserMarker(currentUserLoc!);
      setState(() {}); //refresh the map with user location
    });

    positionStream = Geolocator.getPositionStream().listen((Position position) {
      currentUserLoc = LatLng(position.latitude, position.longitude);
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
      body: Stack(
        children: [
          //for showing the map
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: currentUserLoc == null
                ? Center(
                    child: LoadingAnimationWidget.stretchedDots(
                      color: Colors.white,
                      size: 60,
                    ),
                  )
                : theMap(),
          ),

          //for positioning the home button onto the map
          Positioned(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Column(
                children: [
                  SizedBox(
                    height: _safeVertical * 5,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      autoPageTitle(),
                      SizedBox(
                        height: _safeVertical * 7,
                        width: _safeHorizontal * 48,
                        child: SizedBox(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              bleStatus(),
                              SizedBox(
                                  width:
                                      _safeHorizontal * 3), //just empty space
                              homeButton(context),
                              SizedBox(width: _safeHorizontal * 1),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
              child: liveMarkerCounter(),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
              child: showSheet(),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
              child: (autonomousStart)
                  ? (boatCompleted == markersLatLng.length)
                      ? autofinished()
                      : inProgress()
                  : notStarted(),
            ),
          ),
        ],
      ),
    );
  }

  Container liveMarkerCounter() {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Wrap(
          children: [
            const ImageIcon(
              AssetImage('assets/icons/pin.png'),
              size: 24,
            ),
            SizedBox(
              height: _safeHorizontal * 5,
            ),
            Text(
              ": ${markersLatLng.length}",
              style: const TextStyle(fontSize: 24),
            )
          ],
        ),
      ),
    );
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /// Container to show user current progress in autonomous mode
  Container notStarted() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.white,
      ),
      child: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          "Not started",
          style: TextStyle(fontSize: 23),
        ),
      ),
    );
  }

  Container inProgress() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.cyan,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          "In progress: $boatCompleted/${markersLatLng.length}",
          style: const TextStyle(fontSize: 23),
        ),
      ),
    );
  }

  Container autofinished() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: const Color.fromARGB(255, 103, 234, 107),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          "Completed $boatCompleted/${markersLatLng.length}",
          style: const TextStyle(fontSize: 23),
        ),
      ),
    );
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///Bottom sheet widget
  SizedBox showSheet() {
    return SizedBox(
      child: OutlinedButton(
        onPressed: () async {
          autoModeBottomSheet();
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
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
          child: Icon(
            Icons.list_alt,
            color: Colors.white,
            size: _safeVertical * 6,
          ),
        ),
      ),
    );
  }

  Future<dynamic> autoModeBottomSheet() {
    return showModalBottomSheet(
      backgroundColor: Colors.black,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setInnerState) => Padding(
            padding: const EdgeInsets.all(10),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Container(
                          width: _safeHorizontal * 90,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.white),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _getUserLocationButton(),
                                _getBoatLocationButton(),
                                _generatePolylineButton(setInnerState),
                                _removeAllMarkers(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: _safeVertical * 1,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [_waypointsListViewerSection(setInnerState)],
                    ),
                    SizedBox(
                      height: _safeVertical * 1,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [_summaryViewerPopUp()],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///Map related features
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// created method for getting user current location
  Future<void> _newCameraPosition(LatLng value) async {
    // create a new camera position with respect to the user's location
    CameraPosition cameraPosition = CameraPosition(
      target: value,
      zoom: 25,
    );

    //use future to get the object of the _mapsController to change its properties
    final GoogleMapController controller = await _mapsController.future;

    //animate the map panning to the user's current location
    controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    setState(() {});
  }

  SizedBox _getUserLocationButton() {
    return SizedBox(
      height: _safeVertical * 7,
      width: _safeHorizontal * 20,
      child: OutlinedButton(
        onPressed: () async {
          Navigator.pop(context);
          _newCameraPosition(currentUserLoc!);
          _addUserMarker(currentUserLoc!);
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.black,
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

  void _addUserMarker(LatLng point) {
    setState(
      () {
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
            mapMarkers.add(marker);
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
          Navigator.pop(context);
          List<int> mssg = [0];
          autoModeSendBLE(mssg, 0);
          showSnackBar("Fetching boat location...");
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: const CircleBorder(),
          side: const BorderSide(color: Colors.black),
        ),
        child: const Icon(
          Icons.directions_boat_filled,
          color: Colors.yellow,
        ),
      ),
    );
  }

  Future<void> _addBoatMarker(LatLng point) async {
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
        mapMarkers.add(marker);
      },
    );
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
                title: "Waypoint",
                snippet:
                    "Lat: ${point.latitude.toStringAsFixed(6)}, Lng: ${point.longitude.toStringAsFixed(6)}"),
            icon: BitmapDescriptor.fromBytes(markerIcon),
            // draggable: true,
          );
          // Add the marker to the set and update the state
          setState(
            () {
              mapMarkers.add(marker);
              markersLatLng.add(point);
            },
          );
        },
      );
    } else {
      showSnackBar("Cannot add as waypoints confirmed!");
    }
  }

  bool _checkMarkerToMarker(LatLng point) {
    int maxDistance = 20; //max 20 meters
    int minDistance = 3; //min 3 meters

    //get the latest marker or the last marker
    LatLng lastMarker = markersLatLng.last;

    double distance = Geolocator.distanceBetween(
      lastMarker.latitude,
      lastMarker.longitude,
      point.latitude,
      point.longitude,
    );

    //check the distance between the user and that supposed marker
    //make sure the distance is less than or equals to 1 km
    if (distance >= minDistance && distance <= maxDistance) {
      return true;
    } else {
      return false;
    }
  }

  bool _checkMarkerToUser(LatLng point) {
    int maxMarkerToUserDistance = 1000; //1km

    //first marker can only be dropped about 1 km from user current location
    //this is based on Medium's max comms range (1.1km)
    //get the distance between user and the supposed first marker
    double distance = Geolocator.distanceBetween(
      currentUserLoc!.latitude,
      currentUserLoc!.longitude,
      point.latitude,
      point.longitude,
    );

    //check the distance between the user and that supposed marker
    //make sure the distance is less than or equals to 1 km
    if (distance <= maxMarkerToUserDistance) {
      return true;
    } else {
      return false;
    }
  }

  void _checkMarkerDistance(LatLng point) {
    // Have to make sure user dropping markers based on below conditions
    // each marker is less than 10 m and more than 3 m in distance between each other
    // each marker is less than 1 km from user's last known location

    // Check marker distance to user
    bool distanceToUser = _checkMarkerToUser(point);

    if (distanceToUser) {
      // Now check if first marker or not
      // Check if this is the first waypoint
      if (markersLatLng.isEmpty) {
        // This means it is the first waypoint
        _addMarkerToMap(point);
      } else {
        // Means this is not the first waypoint
        // Now check marker to previous marker distance
        bool distanceToPreviousMarker = _checkMarkerToMarker(point);

        if (distanceToPreviousMarker) {
          _addMarkerToMap(point);
        } else {
          showSnackBar("Marker not between 3-20 m from previous marker");
        }
      }
    } else {
      showSnackBar("Marker further than 1 km from user last location");
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
              LatLng(currentUserLoc!.latitude, currentUserLoc!.longitude),
          zoom: 25),
      markers: mapMarkers,
      polylines: pathPolylines,
      onLongPress: _checkMarkerDistance,
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
  SizedBox _generatePolylineButton(StateSetter setInnerState) {
    return SizedBox(
      height: _safeVertical * 7,
      width: _safeHorizontal * 20,
      child: OutlinedButton(
        onPressed: () {
          setInnerState(() {
            Navigator.pop(context);
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
                pathPolylines.add(
                  Polyline(
                    polylineId: const PolylineId('boat'),
                    points: boatpathLatLng,
                    width: 2,
                    color: const Color.fromARGB(255, 84, 246, 255),
                  ),
                );
                pathPolylines.add(lakeBoundary!);
                _changePolylineButtonColor();
              } else {
                pathPolylines.clear();
                _changePolylineButtonColor();
              }
            });
          });
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: polylineButtonColor.value,
          shape: const CircleBorder(),
          side: const BorderSide(color: Colors.black),
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
          Navigator.pop(context);
          setState(() {
            if (!isWaypointsReady) {
              mapMarkers.clear();
              markerCounter = 0;
              markersLatLng.clear();
              boatpathLatLng.clear();

              //reset the toggle switch for waypoints
              waypointsReadyIndex = 1;

              //reset polylines to none
              if (pathPolylines.isNotEmpty && !isPolylinesON) {
                pathPolylines.clear();
                _changePolylineButtonColor();
              }
            } else {
              showSnackBar("Cannot remove as waypoints confirmed!");
            }
          });
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.black,
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
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///for waypoint checker to work
  Future<void> _locateMarker(LatLng markerLocation) async {
    // create a new camera position with respect to the user's location
    CameraPosition cameraPosition = CameraPosition(
      target: LatLng(markerLocation.latitude, markerLocation.longitude),
      zoom: 30,
    );

    //use future to get the object of the _mapsController to change its properties
    final GoogleMapController controller = await _mapsController.future;

    //animate the map panning to the user's current location
    controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    setState(() {});
  }

  void _removeMarker(int index) {
    int waypointCount = 0;
    Marker? markerToRemove;

    for (Marker marker in mapMarkers) {
      if (marker.markerId.value.startsWith("Waypoint")) {
        waypointCount++;
        if (waypointCount == index + 1) {
          markerToRemove = marker;
          break;
        }
      }
    }

    mapMarkers.remove(markerToRemove);
  }

  Expanded _waypointListBuilder() {
    return Expanded(
      child: ListView.builder(
        itemCount: markersLatLng.length,
        itemBuilder: (BuildContext context, int index) {
          LatLng marker = markersLatLng[index];
          return Padding(
            padding:
                const EdgeInsets.only(top: 5, bottom: 5, right: 10, left: 10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                color: const Color.fromARGB(255, 55, 55, 55),
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                    top: 10, bottom: 10, right: 20, left: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            Text(
                              "Waypoint No.${index + 1}",
                              style: TextStyle(
                                  fontSize: _safeVertical * 2,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red),
                            ),
                            SizedBox(
                              height: _safeVertical,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(5),
                                      child: Text(
                                        "Lat: ${marker.latitude.toStringAsFixed(6)}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(5),
                                      child: Text(
                                        "Lng: ${marker.longitude.toStringAsFixed(6)}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          ],
                        ),
                        Column(
                          children: [
                            IconButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await _locateMarker(marker);
                                },
                                icon: const Icon(
                                  Icons.push_pin,
                                  color: Colors.deepOrange,
                                )),
                            IconButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  if (!isWaypointsReady) {
                                    setState(() {
                                      _removeMarker(index);
                                      markersLatLng.removeAt(index);
                                    });
                                  } else {
                                    showSnackBar(
                                        "Cannot remove as waypoints confirmed!");
                                  }
                                },
                                icon: const Icon(
                                  Icons.playlist_remove,
                                  color: Colors.purple,
                                )),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Container _waypointsListViewerSection(StateSetter setInnerState) {
    return Container(
        width: _safeHorizontal * 90,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10), color: Colors.white),
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
                        setInnerState(() {
                          if (!autonomousStart) {
                            //int 1 indicates not ready
                            //int 0 indicates ready
                            //this is due to how the toggle switch index is placed
                            //where ready button on index 0 and NOT ready button on index 1
                            if (index == 0) {
                              if (mapMarkers.length >= 2) {
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
                          } else {
                            Navigator.pop(context);
                            showSnackBar(
                                "Please cancel ongoing operation first..");
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
              Padding(
                padding: const EdgeInsets.only(right: 30, left: 30),
                child: Container(
                  height: _safeVertical * 30,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.black),
                  child: (markersLatLng.isNotEmpty)
                      ? Flex(
                          direction: Axis.vertical,
                          children: [
                            _waypointListBuilder(),
                          ],
                        )
                      : Center(
                          child: Text("No waypoints set!",
                              style: TextStyle(
                                  fontSize: _safeHorizontal * 5,
                                  color: Colors.white)),
                        ),
                ),
              ),
            ],
          ),
        ));
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
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

  double _calculateMarkerDistance() {
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

  Container _totalDistance() {
    //get the estimated total distance travel
    double totalEstimatedDistance = _calculateMarkerDistance();

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
    double frequency = _calculateMarkerDistance() / markerCounter;

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

  bool isMarkerIdInList(MarkerId targetId) {
    for (var marker in mapMarkers) {
      if (marker.markerId == targetId) {
        return true; // Found the marker ID in the list
      }
    }
    return false; // Marker ID not found
  }

  Container _userToBoatDistance() {
    //Check if both user and boat marker in list of markers
    bool userMarkerExists = isMarkerIdInList(const MarkerId("User"));
    bool boatMarkerExists = isMarkerIdInList(const MarkerId("Boatboat"));
    double? distance;

    if (userMarkerExists && boatMarkerExists) {
      //Get distance between user and boat
      distance = _getStraightLineDistance(
          currentUserLoc!.latitude,
          currentUserLoc!.longitude,
          currentBoatLoc!.latitude,
          currentBoatLoc!.longitude);
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xff171717),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          const Text(
            "User to Boat distance: ",
            style: TextStyle(
              fontSize: 15,
              color: Colors.white,
            ),
          ),
          (distance != null)
              ? Text(
                  "${distance.toStringAsFixed(2)} m",
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.red,
                  ),
                )
              : const Text(
                  "-",
                  style: TextStyle(
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
          SizedBox(
            height: _safeVertical * 1,
          ),
          _waypointFrequency(),
          SizedBox(
            height: _safeVertical * 1,
          ),
          _userToBoatDistance(),
        ],
      ),
    );
  }

  Container _summaryViewerPopUp() {
    return Container(
      width: _safeHorizontal * 90,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10), color: Colors.white),
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
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.black),
                    child: (markersLatLng.length >= 2)
                        ? _summaryContent()
                        : Padding(
                            padding: const EdgeInsets.all(30),
                            child: Center(
                              child: Text("Place at least 2 waypoints!",
                                  style: TextStyle(
                                      fontSize: _safeHorizontal * 5,
                                      color: Colors.white)),
                            ),
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
                sendButton(),
                cancelButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  SizedBox cancelButton() {
    return SizedBox(
      height: _safeVertical * 5,
      width: _safeHorizontal * 35,
      child: OutlinedButton(
        onPressed: () {
          Navigator.pop(context);
          setState(
            () {
              showSnackBar("Attempting to cancel ongoing operations!");

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
      const Duration(seconds: 5),
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

  SizedBox sendButton() {
    return SizedBox(
      height: _safeVertical * 5,
      width: _safeHorizontal * 35,
      child: OutlinedButton(
        onPressed: () async {
          Navigator.pop(context);
          if (isWaypointsReady) {
            // show dialog and then expected to get a return value
            // Have to wrap dialog with PopScope because dialog built on new context
            showDialog(
              barrierDismissible: false,
              context: context,
              builder: (BuildContext context) => PopScope(
                  canPop: false,
                  child: SendAlertDialog(
                    waypointLength: markersLatLng.length,
                    autoStart: autonomousStart,
                    updateCounterController: mySendDialog,
                  )),
            ).then(
              (result) {
                if (result != null && result is bool) {
                  if (!result) {
                    showSnackBar("Attempting to cancel ongoing operations!");

                    // Cancel timer for sending waypoints
                    sendTimer!.cancel();

                    // Send out cancel instruction to boat
                    autoModeSendBLE([1], 0);
                  }
                }
              },
            );

            // if autonomous already started, dont send waypoints again
            if (!autonomousStart) {
              //pack the waypoints from LatLng to type of 2D double list
              List<List<double>> doubleTypeWaypoint = await packWaypoints();

              //function to send BLE data with 1 second delay in between
              await sendWaypoints(doubleTypeWaypoint);
            }
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
    if (isWaypointsReady && (mapMarkers.length >= 2)) {
      return Colors.green;
    } else {
      return const Color.fromARGB(255, 33, 33, 33);
    }
  }
}
