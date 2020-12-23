import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uber_clone/Screens/SearchPage.dart';
import 'package:uber_clone/helpers/HttpRequestMethod.dart';
import 'package:uber_clone/models/Routes.dart';
import 'package:uber_clone/provider/AppData.dart';
import 'package:uber_clone/widgets/ListDivider.dart';
import 'package:uber_clone/widgets/ProgressDialogue.dart';
import 'package:uber_clone/widgets/SubmitFlatButton.dart';

class MainPage extends StatefulWidget {
  static const id = 'mainpage';

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // SNACKBAR
  void showSnackbar(String messages) {
    final snackbar = SnackBar(
      content: Text(
        messages,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18, fontFamily: 'Bolt-Semibold'),
      ),
    );

    _scaffoldKey.currentState.showSnackBar(snackbar);
  }

  // ? Routes Coordinate Polylines
  List<LatLng> polylineCoords = [];
  Set<Polyline> _polylines = {};
  Set<Marker> _marker = {};
  Set<Circle> _circle = {};

  Routes _routes;

  // ! GeoLocator Get Current Position
  Position currentPosition;

  void getCurrentPos() async {
    bool serviceEnabled;
    LocationPermission locPermit;

    // check if service enabled or not
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Get user to turn on his GPS services
      locPermit = await Geolocator.requestPermission();
    }

    // check if apps denied service permanently
    locPermit = await Geolocator.checkPermission();
    if (locPermit == LocationPermission.deniedForever) {
      return showSnackbar('Location services are disabled permanently');
    }

    try {
      // get current users location
      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation);
      currentPosition = pos;

      LatLng coords = LatLng(pos.latitude, pos.longitude);
      CameraPosition mapsCamera = CameraPosition(target: coords, zoom: 18);
      mapController.animateCamera(CameraUpdate.newCameraPosition(mapsCamera));

      // GEOCODE
      String address = await HttpRequestMethod.findAddressByCoord(pos, context);
    } catch (e) {
      showSnackbar(e.toString());
    }
  }

  static final CameraPosition _defaultLocation = CameraPosition(
    target: LatLng(-6.200000, 106.816666),
    zoom: 8,
  );

  // Google map controller
  Completer<GoogleMapController> _controller = Completer();
  GoogleMapController mapController;

  // HEIGHT OF THE SHEET
  bool searchSheetHigh = true;
  bool requestSheetHigh = false;

  void showRequestSheet() async {
    // GET ROUTES
    await getRoutes();

    // SHOW SHEET
    setState(() {
      searchSheetHigh = false;
      requestSheetHigh = true;
    });
  }

  void closeRequestSheet() async {
    // RESET CAMERA POSITION
    CameraPosition pickupPointCamera = CameraPosition(
      target: LatLng(
        Provider.of<AppData>(context, listen: false).pickupPoint.latitude,
        Provider.of<AppData>(context, listen: false).pickupPoint.longitude,
      ),
      zoom: 18,
    );

    mapController
        .animateCamera(CameraUpdate.newCameraPosition(pickupPointCamera));

    setState(() {
      polylineCoords.clear();
      _marker.clear();
      _circle.clear();
      searchSheetHigh = true;
      requestSheetHigh = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Drawer(
          // Add a ListView to the drawer. This ensures the user can scroll
          // through the options in the drawer if there isn't enough vertical
          // space to fit everything.
          child: ListView(
            children: [
              Container(
                height: 150,
                color: Colors.greenAccent,
                padding: EdgeInsets.all(8),
                child: DrawerHeader(
                  child: Row(
                    children: [
                      Image.asset(
                        'resources/images/user_icon.png',
                        height: 55,
                        width: 55,
                      ),
                      SizedBox(
                        width: 8,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Admin',
                              style: TextStyle(
                                fontFamily: 'Bolt-Semibold',
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(
                              height: 2,
                            ),
                            Text(
                              'View profile',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ListDivider(),
              SizedBox(
                height: 12,
              ),
              ListTile(
                leading: Icon(Icons.motorcycle_outlined),
                title: Text('Free Rides'),
              ),
              ListTile(
                leading: Icon(Icons.payment_outlined),
                title: Text('Payments'),
              ),
              ListTile(
                leading: Icon(Icons.history),
                title: Text('Ride History'),
              ),
              ListTile(
                leading: Icon(Icons.support_agent_outlined),
                title: Text('Support'),
              ),
              ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('About'),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.39,
              left: 8,
              right: 8,
              top: MediaQuery.of(context).size.height * 0.1,
            ),
            mapType: MapType.normal,
            myLocationEnabled: true,
            zoomControlsEnabled: true,
            zoomGesturesEnabled: true,
            myLocationButtonEnabled: true,
            polylines: _polylines,
            markers: _marker,
            circles: _circle,
            initialCameraPosition: _defaultLocation,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              mapController = controller;

              // ! After map ready bind user's current locations
              getCurrentPos();
            },
          ),
          Positioned(
            top: 35,
            left: 12,
            child: GestureDetector(
              onTap: () {
                _scaffoldKey.currentState.openDrawer();
              },
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      spreadRadius: 1.5,
                      blurRadius: 0.5,
                      offset: Offset(0.5, 0.5),
                    ),
                  ],
                ),
                child: Icon(Icons.keyboard_arrow_right),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSize(
              vsync: this,
              duration: Duration(milliseconds: 200),
              curve: Curves.easeIn,
              child: Container(
                height: (searchSheetHigh == true)
                    ? MediaQuery.of(context).size.height * 0.38
                    : 0,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 18.0,
                      spreadRadius: 0.8,
                      offset: Offset(0.8, 0.8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8),
                      Text('Nice to see you!', style: TextStyle(fontSize: 12)),
                      Text(
                        'Where are you going?',
                        style: TextStyle(
                            fontFamily: 'Bolt-Semibold', fontSize: 18),
                      ),
                      SizedBox(height: 16),
                      GestureDetector(
                        onTap: () async {
                          var response = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SearchPage()));

                          // ! WHEN USER CAME BACK FROM SEARCH || IT CARRY A TRIGGER
                          // ? What Trigger?
                          // Basically this trigger is going on to activate getRoutes() method
                          // to actually run the data that user has chosen in search page
                          // when user came back from search page, its expected to render the routes
                          if (response == 'getroutesnow') {
                            showRequestSheet();
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 0.8,
                                spreadRadius: 0.5,
                                offset: Offset(0.5, 0.5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search, color: Colors.grey),
                              SizedBox(width: 8),
                              Text(
                                'Search Destination...',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 18,
                      ),
                      Container(
                        padding: const EdgeInsets.only(left: 10, right: 10),
                        child: Row(
                          children: [
                            Icon(Icons.home_outlined, color: Colors.grey),
                            SizedBox(
                              width: 12,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Home',
                                  style: TextStyle(
                                    fontFamily: 'Bolt-Semibold',
                                  ),
                                ),
                                Text(
                                  'Your home address',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 12,
                      ),
                      ListDivider(),
                      SizedBox(
                        height: 12,
                      ),
                      Container(
                        padding: const EdgeInsets.only(left: 10, right: 10),
                        child: Row(
                          children: [
                            Icon(Icons.work_outline, color: Colors.grey),
                            SizedBox(
                              width: 12,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Work',
                                  style: TextStyle(fontFamily: 'Bolt-Semibold'),
                                ),
                                Text(
                                  'Your workspace address',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSize(
              vsync: this,
              curve: Curves.easeIn,
              duration: Duration(milliseconds: 200),
              child: Container(
                height: (requestSheetHigh == true)
                    ? MediaQuery.of(context).size.height * 0.3
                    : 0,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 18.0,
                      spreadRadius: 0.8,
                      offset: Offset(0.8, 0.8),
                    ),
                  ],
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        color: Colors.green[50],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Image.asset(
                                'resources/images/taxi.png',
                                height: 70,
                                width: 70,
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Lets-Car',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontFamily: 'Bolt-Semibold'),
                                  ),
                                  Text(
                                    (_routes != null)
                                        ? (double.parse(_routes.destDistanceM) <
                                                1000)
                                            ? '<${_routes.destDistanceKM}km/${_routes.destDistanceM}m'
                                            : '${_routes.destDistanceKM}km/${_routes.destDistanceM}m'
                                        : '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              Expanded(child: Container()),
                              Text(
                                (_routes != null)
                                    ? 'Rp${HttpRequestMethod.calculateFares(_routes)},-'
                                    : '',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontFamily: 'Bolt-Semibold',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 12,
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.payment_outlined,
                              color: Colors.grey,
                            ),
                            SizedBox(
                              width: 4,
                            ),
                            Text(
                              'Cash',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 12,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SubmitFlatButton(
                          'REQUEST DRIVER',
                          Colors.green,
                          () => {},
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          (requestSheetHigh == true)
              ? Positioned(
                  bottom: MediaQuery.of(context).size.height * 0.31,
                  left: 12,
                  child: GestureDetector(
                    onTap: () {
                      closeRequestSheet();
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            spreadRadius: 1.5,
                            blurRadius: 0.5,
                            offset: Offset(0.5, 0.5),
                          ),
                        ],
                      ),
                      child: Icon(Icons.arrow_back_sharp),
                    ),
                  ),
                )
              : Container(),
        ],
      ),
    );
  }

  Future getRoutes() async {
    // GLOBAL PICKUP AND DESTINATION POINT
    var pickupPoint = Provider.of<AppData>(context, listen: false).pickupPoint;
    var destPoint = Provider.of<AppData>(context, listen: false).destPoint;

    var pickupLatLng = LatLng(pickupPoint.latitude, pickupPoint.longitude);
    var destLatLng = LatLng(destPoint.latitude, destPoint.longitude);

    // SHOW LOADING SCREEN FIRST
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProgressDialogue("Please wait..."),
    );

    // CALL THE HELPER METHOD TO GET ROUTES/DETAILS
    var getRoutes =
        await HttpRequestMethod.findRoutes(pickupLatLng, destLatLng);

    setState(() {
      _routes = getRoutes;
    });

    // !: RENDER ROUTES :!
    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> result =
        polylinePoints.decodePolyline(getRoutes.encodedPoints);

    // clear available RESULT first
    polylineCoords.clear();

    if (result.isNotEmpty) {
      // LOOP RESULT + ADD to LIST
      result.forEach((PointLatLng points) {
        polylineCoords.add(LatLng(points.latitude, points.longitude));
      });
    }

    // PROPERTY of POLYLINE
    // clear available polyline first
    _polylines.clear();

    setState(() {
      Polyline polyline = Polyline(
        polylineId: PolylineId('routes'),
        color: Colors.purple,
        points: polylineCoords,
        jointType: JointType.round,
        width: 4,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      // add to Set
      _polylines.add(polyline);
    });

    // DISMISS LOADING
    Navigator.pop(context);

    // ANIMATE MAPS CAMERA
    LatLngBounds bounds;

    if (pickupLatLng.latitude > destLatLng.latitude &&
        pickupLatLng.longitude > destLatLng.longitude) {
      bounds = LatLngBounds(southwest: destLatLng, northeast: pickupLatLng);
    } else if (pickupLatLng.latitude > destLatLng.latitude) {
      bounds = LatLngBounds(
        southwest: LatLng(destLatLng.latitude, pickupLatLng.longitude),
        northeast: LatLng(pickupLatLng.latitude, destLatLng.longitude),
      );
    } else if (pickupLatLng.longitude > destLatLng.longitude) {
      bounds = LatLngBounds(
        southwest: LatLng(pickupLatLng.latitude, destLatLng.longitude),
        northeast: LatLng(destLatLng.latitude, pickupLatLng.longitude),
      );
    } else {
      bounds = LatLngBounds(southwest: pickupLatLng, northeast: destLatLng);
    }

    // UPDATE CAMERA
    mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));

    // ADD A MARKER
    Marker pickupMarker = Marker(
      markerId: MarkerId('pickup'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(
        title: pickupPoint.formattedAddress,
        snippet: 'Lat: ${pickupPoint.latitude}; Lng: ${pickupPoint.longitude}',
      ),
      position: pickupLatLng,
    );

    Marker destMarker = Marker(
      markerId: MarkerId('dest'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(
        title: destPoint.formattedAddress,
        snippet: 'Lat: ${destPoint.latitude};Lng: ${destPoint.longitude}',
      ),
      position: destLatLng,
    );

    // ADD a CIRCLE
    Circle pickupCircle = Circle(
      circleId: CircleId('pickup'),
      center: pickupLatLng,
      strokeWidth: 3,
      radius: 12,
      strokeColor: Colors.green,
      fillColor: Colors.greenAccent,
    );

    Circle destCircle = Circle(
      circleId: CircleId('dest'),
      center: destLatLng,
      strokeWidth: 3,
      radius: 8,
      strokeColor: Colors.red,
      fillColor: Colors.redAccent,
    );

    setState(() {
      _marker.add(pickupMarker);
      _marker.add(destMarker);
      _circle.add(pickupCircle);
      _circle.add(destCircle);
    });
  }
}
