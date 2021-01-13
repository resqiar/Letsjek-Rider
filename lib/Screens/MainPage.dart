import 'dart:async';
import 'dart:math';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:uber_clone/Screens/SearchPage.dart';
import 'package:uber_clone/global.dart';
import 'package:uber_clone/helpers/GeofireHelper.dart';
import 'package:uber_clone/helpers/HttpRequestMethod.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import 'package:uber_clone/helpers/MapToolkitHelper.dart';
import 'package:uber_clone/models/NearbyDrivers.dart';
import 'package:uber_clone/models/Routes.dart';
import 'package:uber_clone/provider/AppData.dart';
import 'package:uber_clone/widgets/CashPaymentDialog.dart';
import 'package:uber_clone/widgets/ConfirmLogoutDialog.dart';
import 'package:uber_clone/widgets/ListDivider.dart';
import 'package:uber_clone/widgets/NoNearbyDriversDialog.dart';
import 'package:uber_clone/widgets/ProgressDialogue.dart';
import 'package:uber_clone/widgets/SubmitFlatButton.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:wakelock/wakelock.dart';

class MainPage extends StatefulWidget {
  static const id = 'mainpage';

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
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
    setState(() {
      isLoading = true;
    });

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
      await HttpRequestMethod.findAddressByCoord(pos, context);

      // GET AVAILABLE DRIVERS
      getAvailableDrivers();

      setState(() {
        isLoading = false;
      });
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
  bool tripSheetHigh = false;
  bool isRequesting = false;

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

  String rideRequestKey = '';
  List availableDrivers = [];

  void isNowRequesting() async {
    requestDriverNow();

    setState(() {
      searchSheetHigh = false;
      requestSheetHigh = false;
      isRequesting = true;
    });

    // POPULATE NEARBY DRIVERS LIST
    setState(() {
      availableDrivers = GeofireHelper.nearbyDriverList;
    });
  }

  void cancelRequesting() async {
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

    DatabaseReference rideRequestDB = FirebaseDatabase.instance
        .reference()
        .child('ride_request/$rideRequestKey');

    rideRequestDB.remove();

    setState(() {
      polylineCoords.clear();
      _marker.clear();
      _circle.clear();
      searchSheetHigh = true;
      requestSheetHigh = false;
      isRequesting = false;
    });
  }

  // DRIVERS STATE
  bool driversGeoQueryIsLoaded = false;
  bool isLocationEnabled = true;

  // DRIVERS ICON
  BitmapDescriptor driverIcon;

  void createDriverMarker() {
    if (driverIcon == null) {
      ImageConfiguration imageConfiguration = createLocalImageConfiguration(
        context,
        size: Size(2, 2),
      );

      // ICON IMAGE
      BitmapDescriptor.fromAssetImage(
              imageConfiguration, 'resources/images/car_android.png')
          .then((icon) {
        driverIcon = icon;
      });
    }
  }

  void showTripSheet() {
    setState(() {
      searchSheetHigh = false;
      tripSheetHigh = true;
    });
  }

  mp.LatLng onTheWayPos = mp.LatLng(0, 0);
  mp.LatLng onTheDestPos = mp.LatLng(0, 0);

  String _darkStyle;

  void changeMapMode(context) {
    // DEVICE THEME
    if (Theme.of(context).brightness == Brightness.dark) {
      setMapStyle(_darkStyle);
    } else {
      setMapStyle("[]");
    }
  }

  void changeSettingsMapMode(bool isDarkModeOn) {
    // DEVICE THEME
    if (isDarkModeOn) {
      setMapStyle(_darkStyle);
    } else {
      setMapStyle("[]");
    }
  }

  Future getMapSettings() async {
    _darkStyle =
        await rootBundle.loadString('resources/settings/map/darkMap.json');
  }

  void setMapStyle(String mapStyle) {
    mapController.setMapStyle(mapStyle);
  }

  bool isOnDarkMode;
  bool isOnLightMode;

  void getDeviceSettings() {
    if (Theme.of(context).brightness == Brightness.dark) {
      isOnDarkMode = true;
      isOnLightMode = false;
    } else {
      isOnDarkMode = false;
      isOnLightMode = true;
    }
  }

  bool isLoading = false;
  bool isInitializing = true;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    HttpRequestMethod.getCurrentUserData().whenComplete(() {
      setState(() {
        isInitializing = false;
      });
    });

    //
    Wakelock.enable();
    WidgetsBinding.instance.addObserver(this);
    getMapSettings();
  }

  @override
  Widget build(BuildContext context) {
    HttpRequestMethod.getCurrentUserData();
    getDeviceSettings();
    createDriverMarker();
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
                padding: EdgeInsets.all(18),
                child: Row(
                  children: [
                    (isLoading)
                        ? CircularProgressIndicator(
                            backgroundColor: (Theme.of(context).brightness ==
                                    Brightness.dark)
                                ? Colors.deepPurple
                                : Colors.deepOrange,
                          )
                        : Image.asset(
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
                          (isInitializing)
                              ? Text(
                                  '',
                                  style: TextStyle(
                                    fontFamily: 'Bolt-Semibold',
                                    fontSize: 16,
                                  ),
                                )
                              : Text(
                                  currentUser.userFullname,
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
              CheckboxListTile(
                secondary: Icon(Icons.nights_stay_outlined),
                title: Text('Dark Mode'),
                value: (isOnDarkMode) ? true : false,
                onChanged: (bool value) {
                  setState(() {
                    isOnDarkMode = value;
                    changeSettingsMapMode(isOnDarkMode);
                    AdaptiveTheme.of(context).toggleThemeMode();
                  });
                },
                subtitle: Text(
                  'Reduces eye strain',
                  style: TextStyle(fontSize: 12),
                ),
                activeColor: Colors.white,
                checkColor: Colors.black,
              ),
              ListTile(
                leading: Icon(Icons.support_agent_outlined),
                title: Text('Support'),
              ),
              ListTile(
                leading: Icon(Icons.exit_to_app),
                title: Text('Sign Out'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) => ConfirmLogoutDialog(
                      onpress: () async {
                        await FirebaseAuth.instance.signOut();

                        // if everything is okay then push user to MainPage
                        Navigator.pushNamedAndRemoveUntil(
                            context, 'loginpage', (route) => false);
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(
              bottom: (searchSheetHigh == false)
                  ? MediaQuery.of(context).size.height * 0.31
                  : MediaQuery.of(context).size.height * 0.39,
              left: (requestSheetHigh == false) ? 8 : 56,
              right: 8,
              top: 30,
            ),
            mapType: MapType.normal,
            myLocationEnabled: isLocationEnabled,
            compassEnabled: false,
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
              changeMapMode(context);

              // ! After map ready bind user's current locations
              getCurrentPos();
            },
          ),
          (searchSheetHigh)
              ? Positioned(
                  top: 35,
                  left: 12,
                  child: GestureDetector(
                    onTap: () {
                      _scaffoldKey.currentState.openDrawer();
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
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
                )
              : Container(),
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
                  color: (Theme.of(context).brightness == Brightness.dark)
                      ? Theme.of(context).primaryColor
                      : Colors.white,
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
                        onTap: (!isLoading)
                            ? () async {
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
                              }
                            : () {},
                        child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (Theme.of(context).brightness ==
                                    Brightness.dark)
                                ? Colors.black38
                                : Colors.white,
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
                              (isLoading)
                                  ? CircularProgressIndicator(
                                      backgroundColor:
                                          (Theme.of(context).brightness ==
                                                  Brightness.dark)
                                              ? Colors.deepPurple
                                              : Colors.deepOrange,
                                    )
                                  : Icon(Icons.search, color: Colors.grey),
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
                  color: Theme.of(context).primaryColor,
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
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            Text(
                              'from',
                              style: TextStyle(fontSize: 12),
                            ),
                            SizedBox(
                              width: 2,
                            ),
                            Container(
                              padding: EdgeInsets.all(0),
                              width: 90,
                              child: Text(
                                (Provider.of<AppData>(context).pickupPoint !=
                                        null)
                                    ? Provider.of<AppData>(context)
                                        .pickupPoint
                                        .formattedAddress
                                    : '',
                                style: TextStyle(
                                    fontSize: 12, fontFamily: 'Bolt-Semibold'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              'to',
                              style: TextStyle(fontSize: 12),
                            ),
                            SizedBox(
                              width: 4,
                            ),
                            Container(
                              padding: EdgeInsets.all(0),
                              width: 150,
                              child: Text(
                                (Provider.of<AppData>(context).destPoint !=
                                        null)
                                    ? Provider.of<AppData>(context)
                                        .destPoint
                                        .formattedAddress
                                    : '',
                                style: TextStyle(
                                    fontSize: 12, fontFamily: 'Bolt-Semibold'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        color: (Theme.of(context).brightness == Brightness.dark)
                            ? Colors.deepPurple
                            : Colors.orangeAccent[100],
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
                                        fontFamily: 'Bolt-Semibold'),
                                  ),
                                ],
                              ),
                              Expanded(child: Container()),
                              Text(
                                (_routes != null)
                                    ? '${HttpRequestMethod.calculateFares(_routes)},-'
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
                          (Theme.of(context).brightness == Brightness.dark)
                              ? Colors.deepPurple
                              : Colors.deepOrangeAccent,
                          () {
                            isNowRequesting();

                            //! WHY THIS NEED TIMER?
                            // I JUST FIGURED OUT THAT isNowRequesting() NEEDS SOME TIMES TO FINISH
                            // SO IT WOULD BE REALISTIC TO WAIT A LITTLE BIT AND THEN START FIND DRIVER
                            Timer(Duration(seconds: 3), () {
                              selectNearbyDrivers();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          (isRequesting == true)
              ? Positioned(
                  bottom: MediaQuery.of(context).size.height * 0.26,
                  left: 12,
                  child: GestureDetector(
                    onTap: () {
                      cancelRequesting();
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange,
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
                      child: Text(
                        'CANCEL RIDE',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Bolt-Semibold'),
                      ),
                    ),
                  ),
                )
              : Container(),
          (isRequesting == true)
              ? Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.25,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 18.0,
                          spreadRadius: 0.8,
                          offset: Offset(0.8, 0.8),
                        ),
                      ],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 28),
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.grey),
                          ),
                          SizedBox(height: 8),
                          RotateAnimatedTextKit(
                            duration: Duration(milliseconds: 700),
                            repeatForever: true,
                            textStyle: TextStyle(
                              fontSize: 18,
                              fontFamily: 'Bolt-Semibold',
                              color: Colors.grey,
                            ),
                            text: [
                              'REQUESTING DRIVERS',
                              'NOTIFYING DRIVERS',
                              'CALLING DRIVERS'
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : Container(),
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
                        color: Theme.of(context).primaryColor,
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
                      child: Icon(Icons.close_rounded),
                    ),
                  ),
                )
              : Container(),

          //! TRIP SHEET
          /// Trip Sheet
          (tripSheetHigh)
              ? Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedSize(
                    vsync: this,
                    duration: Duration(milliseconds: 150),
                    curve: Curves.easeIn,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 15.0, // soften the shadow
                            spreadRadius: 0.5, //extend the shadow
                            offset: Offset(
                              0.7, // Move to right 10  horizontally
                              0.7, // Move to bottom 10 Vertically
                            ),
                          )
                        ],
                      ),
                      height: MediaQuery.of(context).size.height * 0.335,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  tripStatusText,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                    fontFamily: 'Bolt-Semibold',
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 8,
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 2),
                              width: double.infinity,
                              color: (Theme.of(context).brightness ==
                                      Brightness.dark)
                                  ? Colors.deepPurple
                                  : Colors.orangeAccent[100],
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        height: 14,
                                      ),
                                      Text(
                                        tripDriverFullName,
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontFamily: 'Bolt-Semibold'),
                                      ),
                                      Text(
                                        '$tripDriverCarBrand - $tripDriverCarPlate - $tripDriverCarColor',
                                        style: TextStyle(
                                            fontFamily: 'Bolt-Semibold'),
                                      ),
                                      Text(
                                        (double.parse(tripDriverEstimatedKM) <
                                                1)
                                            ? 'Estimated $tripDriverEstimatedM Meters/$tripDriverEstimatedTime Minutes'
                                            : 'Estimated $tripDriverEstimatedKM KM/$tripDriverEstimatedTime Minutes',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontFamily: 'Bolt-Semibold',
                                            color: Colors.grey),
                                      ),
                                      SizedBox(
                                        height: 16,
                                      ),
                                    ],
                                  ),
                                  (tripDriverProfileURL != null)
                                      ? Container(
                                          child: FadeInImage.memoryNetwork(
                                            placeholder: kTransparentImage,
                                            image: tripDriverProfileURL,
                                            height: 100,
                                            width: 100,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Container(),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 12,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      height: 50,
                                      width: 50,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular((25))),
                                        border: Border.all(
                                            width: 1.5,
                                            color:
                                                (Theme.of(context).brightness ==
                                                        Brightness.dark)
                                                    ? Colors.deepPurple
                                                    : Colors.orangeAccent[100]),
                                      ),
                                      child: Icon(
                                        Icons.call,
                                        color: (Theme.of(context).brightness ==
                                                Brightness.dark)
                                            ? Colors.deepPurple
                                            : Colors.orangeAccent[100],
                                      ),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Text(
                                      'Call',
                                      style: TextStyle(
                                        color: Colors.deepOrangeAccent,
                                        fontFamily: 'Bolt-Semibold',
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      height: 50,
                                      width: 50,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular((25))),
                                        border: Border.all(
                                            width: 1.5,
                                            color:
                                                (Theme.of(context).brightness ==
                                                        Brightness.dark)
                                                    ? Colors.deepPurple
                                                    : Colors.orangeAccent[100]),
                                      ),
                                      child: Icon(Icons.list,
                                          color:
                                              (Theme.of(context).brightness ==
                                                      Brightness.dark)
                                                  ? Colors.deepPurple
                                                  : Colors.orangeAccent[100]),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Text(
                                      'Details',
                                      style: TextStyle(
                                        color: Colors.deepOrangeAccent,
                                        fontFamily: 'Bolt-Semibold',
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      height: 50,
                                      width: 50,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular((25))),
                                        border: Border.all(
                                            width: 1.5, color: Colors.grey),
                                      ),
                                      child:
                                          Icon(Icons.clear, color: Colors.red),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontFamily: 'Bolt-Semibold',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : Container(),
        ],
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // TODO: implement didChangeAppLifecycleState
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      if (Theme.of(context).brightness == Brightness.dark) {
        mapController.setMapStyle(_darkStyle);
      } else {
        mapController.setMapStyle("[]");
      }
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    mapController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    Wakelock.disable();
    super.dispose();
  }

  ////

  void selectNearbyDrivers() {
    if (availableDrivers.length == 0) {
      cancelRequesting();

      // SHOW DIALOG
      showDialog(
        context: context,
        builder: (BuildContext context) => NoNearbyDriversDialog(),
        barrierDismissible: false,
      );

      return;
    }

    var nearbyDriver = availableDrivers[0];
    availableDrivers.removeAt(0);

    notifySelectedDriver(nearbyDriver);
  }

  void notifySelectedDriver(NearbyDrivers driver) {
    // GET DRIVER STATUS
    DatabaseReference driverStatusRef = FirebaseDatabase.instance
        .reference()
        .child('drivers/${driver.driverKey}/trip');

    // ! SET DRIVER STATUS TO TRIP REQUEST ID
    driverStatusRef.set(rideRequestKey);

    // GET DRIVER TOKEN
    DatabaseReference driverTokenRef = FirebaseDatabase.instance
        .reference()
        .child('drivers/${driver.driverKey}/token');

    // RETRIEVE TOKEN
    driverTokenRef.once().then((DataSnapshot dataSnapshot) {
      if (dataSnapshot != null) {
        String driverToken = dataSnapshot.value.toString();

        // SEND NOTIFICATIONS TO DRIVER BY ITS TOKEN
        HttpRequestMethod.sendMessageToDrivers(driverToken, rideRequestKey);
      } else {
        return;
      }

      const onSec = Duration(seconds: 1);

      // SET TIMER
      var timer = Timer.periodic(onSec, (timer) {
        timerCountdown--;

        // check if user is no longer requesting
        if (!isRequesting) {
          driverStatusRef.set('cancelled');
          driverStatusRef.onDisconnect();

          // disable timer
          timer.cancel();
          timerCountdown = 15;
        }

        // if DRIVER accepted the request then stop the countdown
        driverStatusRef.onValue.listen((event) {
          if (event.snapshot.value.toString() == 'accepted') {
            driverStatusRef.onDisconnect();

            // disable timer
            timer.cancel();
            timerCountdown = 15;
          }
        });

        // if timer countdown == 0 set request to timedOut
        if (timerCountdown == 0) {
          driverStatusRef.set('timeout');
          driverStatusRef.onDisconnect();

          // disable timer
          timer.cancel();
          timerCountdown = 15;

          // select another driver
          selectNearbyDrivers();
        }
      });
    });
  }

  void getAvailableDrivers() {
    // listening db
    Geofire.initialize('available_drivers');

    // geo queries
    Geofire.queryAtLocation(
            currentPosition.latitude, currentPosition.longitude, 20)
        .listen((map) {
      /////////////////////////////////////////////////
      if (map != null) {
        var callBack = map['callBack'];

        //latitude will be retrieved from map['latitude']
        //longitude will be retrieved from map['longitude']

        switch (callBack) {
          case Geofire.onKeyEntered:

            // PASS THE VALUE TO DATA MODELS
            NearbyDrivers nearbyDriversModel = NearbyDrivers();
            nearbyDriversModel.driverKey = map['key'];
            nearbyDriversModel.latitude = map['latitude'];
            nearbyDriversModel.longitude = map['longitude'];

            // add all to list
            GeofireHelper.nearbyDriverList.add(nearbyDriversModel);
            setState(() {
              availableDrivers = GeofireHelper.nearbyDriverList;
            });

            // check if geo query is loaded or not
            if (driversGeoQueryIsLoaded) {
              updateDriversMarker();
            }

            break;

          case Geofire.onKeyExited:
            GeofireHelper.removeDriver(map['key']);
            setState(() {
              availableDrivers = GeofireHelper.nearbyDriverList;
            });
            updateDriversMarker();

            break;

          case Geofire.onKeyMoved:
            // PASS THE VALUE TO DATA MODELS
            NearbyDrivers nearbyDriversModel = NearbyDrivers();
            nearbyDriversModel.driverKey = map['key'];
            nearbyDriversModel.latitude = map['latitude'];
            nearbyDriversModel.longitude = map['longitude'];

            // Update your key's location
            GeofireHelper.updateDriver(nearbyDriversModel);
            updateDriversMarker();

            break;

          case Geofire.onGeoQueryReady:
            driversGeoQueryIsLoaded = true;

            // All Intial Data is loaded
            updateDriversMarker();

            break;
        }
      }
    });
  }

  void updateDriversMarker() {
    // Clear All Marker First
    setState(() {
      _marker.clear();
    });

    // make new set of Marker
    Set<Marker> temporaryMarkers = Set<Marker>();

    // loop to get all drivers LAT & LNG
    for (NearbyDrivers nearbyDrivers in GeofireHelper.nearbyDriverList) {
      LatLng driversPosition =
          LatLng(nearbyDrivers.latitude, nearbyDrivers.longitude);

      Marker thisMarker = Marker(
        markerId: MarkerId('driver'),
        position: driversPosition,
        icon: driverIcon,
        rotation: Random().nextInt(360).toDouble(),
      );

      temporaryMarkers.add(thisMarker);
    }

    setState(() {
      _marker = temporaryMarkers;
    });
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
        color: (Theme.of(context).brightness == Brightness.dark)
            ? Colors.white
            : Colors.deepPurple,
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
      // _marker.add(pickupMarker);
      _marker.add(destMarker);
      _circle.add(pickupCircle);
      _circle.add(destCircle);
    });
  }

  void requestDriverNow() async {
    var requestDBRef =
        FirebaseDatabase.instance.reference().child('ride_request').push();

    var pickup = Provider.of<AppData>(context, listen: false).pickupPoint;
    var dest = Provider.of<AppData>(context, listen: false).destPoint;
    var fares = await HttpRequestMethod.calculateFreshFares(_routes);

    Map pickupCoord = {
      'latitude': pickup.latitude.toString(),
      'longitude': pickup.longitude.toString()
    };

    Map destCoord = {
      'latitude': dest.latitude.toString(),
      'longitude': dest.longitude.toString()
    };

    // ADD DATA TO DB
    Map rideRequestDetails = {
      'rider_name': currentUser.userFullname,
      'rider_phone': currentUser.userPhone,
      'pickup_address': pickup.formattedAddress,
      'dest_address': dest.formattedAddress,
      'created_at': DateTime.now().toString(),
      'pickup_coord': pickupCoord,
      'dest_coord': destCoord,
      'fares_price': fares.toString(),
      'payment': 'cash',
      'driver_id': 'waiting',
      'driver_info': null,
      'status': 'waiting',
    };

    // SAVE TO DB
    requestDBRef.set(rideRequestDetails).whenComplete(() {
      setState(() {
        rideRequestKey = requestDBRef.key;
      });
    });

    // ! LISTEN TO CHANGED VALUE
    driverStatusRef = requestDBRef.onValue.listen((event) async {
      // null safety
      if (event.snapshot.value == null) {
        return;
      }

      if (event.snapshot.value['status'] != null) {
        tripStatus = event.snapshot.value['status'].toString();
      }

      if (tripStatus == 'accepted') {
        // ! DRIVER ID
        if (event.snapshot.value['driver_id'].toString() != 'waiting') {
          var driverID = event.snapshot.value['driver_id'].toString();
          var driverProfile = await getDriverProfile(driverID);

          setState(() {
            tripDriverProfileURL = driverProfile;
          });
        }

        // ! DRIVER NAME
        if (event.snapshot.value['driver_info']['driver_name'] != null) {
          setState(() {
            tripDriverFullName =
                event.snapshot.value['driver_info']['driver_name'].toString();
          });
        }

        // ! DRIVER PHONE
        if (event.snapshot.value['driver_info']['driver_phone'] != null) {
          setState(() {
            tripDriverPhoneNumber =
                event.snapshot.value['driver_info']['driver_phone'].toString();
          });
        }

        // ! DRIVER CAR BRAND
        if (event.snapshot.value['driver_info']['vehicle_name'] != null) {
          setState(() {
            tripDriverCarBrand =
                event.snapshot.value['driver_info']['vehicle_name'].toString();
          });
        }

        // ! DRIVER CAR PLATE NUMBER
        if (event.snapshot.value['driver_info']['vehicle_number'] != null) {
          setState(() {
            tripDriverCarPlate = event
                .snapshot.value['driver_info']['vehicle_number']
                .toString();
          });
        }

        // ! DRIVER CAR COLOR
        if (event.snapshot.value['driver_info']['vehicle_color'] != null) {
          setState(() {
            tripDriverCarColor =
                event.snapshot.value['driver_info']['vehicle_color'].toString();
          });
        }

        // ! SAVE DRIVER COORDS
        double driverLocLat = double.parse(event
            .snapshot.value['driver_info']['driver_coords']['latitude']
            .toString());
        double driverLocLng = double.parse(event
            .snapshot.value['driver_info']['driver_coords']['longitude']
            .toString());

        driverCoords = LatLng(driverLocLat, driverLocLng);
        await updateDriverArrivalCoordsInfo(driverCoords);
        updateOnTheWayDriver(driverCoords);

        setState(() {
          tripStatusText = 'Driver is on the way';
          isRequesting = false;
        });

        if (!tripSheetHigh) {
          showTripSheet();
          Geofire.stopListener();

          _marker.removeWhere(
              (element) => element.markerId.value.toString() == 'driver');
        }
      }

      if (tripStatus == 'picked') {
        setState(() {
          tripStatusText = 'Driver is arrived';
        });
      }

      if (tripStatus == 'transporting') {
        setState(() {
          tripStatusText = 'On the way to destination';
        });

        // ! SAVE DRIVER COORDS
        double driverLocLat = double.parse(event
            .snapshot.value['driver_info']['driver_coords']['latitude']
            .toString());
        double driverLocLng = double.parse(event
            .snapshot.value['driver_info']['driver_coords']['longitude']
            .toString());

        driverCoords = LatLng(driverLocLat, driverLocLng);
        await updateDestinationArrivalCoordsInfo(driverCoords);
        getLocationsUpdate(driverCoords);
      }

      if (tripStatus == 'arrived') {
        setState(() {
          tripStatusText = 'You have arrived';
        });

        if (event.snapshot.value['fares_price'] != null) {
          var fares = event.snapshot.value['fares_price'];
          String formattedFares = NumberFormat.currency(
            locale: 'id',
            symbol: 'IDR ',
            decimalDigits: 0,
          ).format(int.parse(fares));

          var response = await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) =>
                CashPaymentDialog(fares: formattedFares),
          );

          if (response == 'payed') {
            setState(() {
              _marker.clear();
              polylineCoords.clear();
              _circle.clear();
              isLocationEnabled = true;
            });

            resetApp();
          }
        }
      }
    });
  }

  Future<String> getDriverProfile(String driverID) async {
    DatabaseReference driverDBRef = FirebaseDatabase.instance
        .reference()
        .child('drivers/$driverID/profile_url');

    var profileURL = await driverDBRef.once().then((DataSnapshot dataSnapshot) {
      if (dataSnapshot != null) {
        return dataSnapshot.value.toString();
      }
    });

    return profileURL;
  }

  Future updateDriverArrivalCoordsInfo(LatLng driverCoords) async {
    var getDriverInfo = await HttpRequestMethod.findRoutes(driverCoords,
        LatLng(currentPosition.latitude, currentPosition.longitude));

    if (getDriverInfo != null) {
      setState(() {
        tripDriverEstimatedTime = getDriverInfo.destDuration;
        tripDriverEstimatedM = getDriverInfo.destDistanceM;
        tripDriverEstimatedKM = getDriverInfo.destDistanceKM;
      });
    }
  }

  Future updateDestinationArrivalCoordsInfo(LatLng currentCoords) async {
    var destPoint = Provider.of<AppData>(context, listen: false).destPoint;
    var destLatLng = LatLng(destPoint.latitude, destPoint.longitude);

    var getDriverInfo =
        await HttpRequestMethod.findRoutes(currentCoords, destLatLng);

    if (getDriverInfo != null) {
      setState(() {
        tripDriverEstimatedTime = getDriverInfo.destDuration;
        tripDriverEstimatedM = getDriverInfo.destDistanceM;
        tripDriverEstimatedKM = getDriverInfo.destDistanceKM;
      });
    }
  }

  void getLocationsUpdate(LatLng driverPositions) {
    // COMPUTED ROTATIONS
    var rotations = MapToolkitHelper.calcRotations(
        onTheDestPos,
        mp.LatLng(
          driverPositions.latitude,
          driverPositions.longitude,
        ));

    // SET MARKER
    LatLng coords = LatLng(driverPositions.latitude, driverPositions.longitude);

    Marker driverMarker = Marker(
      markerId: MarkerId('driverIcon'),
      icon: driverIcon,
      position: coords,
      rotation: rotations,
    );

    // UPDATE EVERYTHING ACCORDINGLY
    setState(() {
      isLocationEnabled = false;
      // ANIMATE CAMERA
      CameraPosition cameraPosition = CameraPosition(target: coords, zoom: 18);

      mapController
          .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

      // CLEAR DRIVERICON BEFORE ADD NEW
      _marker.removeWhere((marker) => marker.markerId.value == 'driverIcon');

      _marker.add(driverMarker);
    });

    // UPDATE DUMMY LATLNG
    onTheDestPos =
        mp.LatLng(driverPositions.latitude, driverPositions.longitude);
  }

  void updateOnTheWayDriver(LatLng driverCurrentPos) {
    // COMPUTED ROTATIONS
    var rotations = MapToolkitHelper.calcRotations(
        onTheWayPos,
        mp.LatLng(
          driverCurrentPos.latitude,
          driverCurrentPos.longitude,
        ));

    // SET MARKER
    LatLng coords =
        LatLng(driverCurrentPos.latitude, driverCurrentPos.longitude);

    Marker driverMarker = Marker(
      markerId: MarkerId('driverIcon'),
      icon: driverIcon,
      position: coords,
      rotation: rotations,
    );

    // UPDATE EVERYTHING ACCORDINGLY
    setState(() {
      // CLEAR DRIVERICON BEFORE ADD NEW
      _marker.removeWhere((marker) => marker.markerId.value == 'driverIcon');

      _marker.add(driverMarker);
    });

    // UPDATE DUMMY LATLNG
    onTheWayPos =
        mp.LatLng(driverCurrentPos.latitude, driverCurrentPos.longitude);
  }

  void resetApp() {
    setState(() {
      searchSheetHigh = true;
      tripSheetHigh = false;
      tripStatus = '';
      tripStatusText = '';
      tripDriverFullName = '';
      tripDriverPhoneNumber = '';
      tripDriverCarBrand = '';
      tripDriverCarPlate = '';
      tripDriverCarColor = '';
      tripDriverEstimatedTime = '';
      tripDriverEstimatedKM = '0';
      tripDriverEstimatedM = '';
    });

    getCurrentPos();
  }
}
