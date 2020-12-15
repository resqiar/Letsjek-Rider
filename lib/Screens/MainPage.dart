import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uber_clone/widgets/ListDivider.dart';

class MainPage extends StatefulWidget {
  static const id = 'mainpage';

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
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
            child: Container(
              height: MediaQuery.of(context).size.height * 0.38,
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
                      style:
                          TextStyle(fontFamily: 'Bolt-Semibold', fontSize: 18),
                    ),
                    SizedBox(height: 16),
                    Container(
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
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey),
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
        ],
      ),
    );
  }
}
