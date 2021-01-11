import 'package:connectivity/connectivity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uber_clone/helpers/HttpReqHelper.dart';
import 'package:uber_clone/models/Address.dart';
import 'package:uber_clone/models/CurrentUser.dart';
import 'package:uber_clone/models/Routes.dart';
import 'package:uber_clone/provider/AppData.dart';
import 'package:uber_clone/global.dart';

class HttpRequestMethod {
  static getCurrentUserData() {
    // get current user info
    firebaseAuth = FirebaseAuth.instance;
    String currentUserId = firebaseAuth.currentUser.uid;

    // firebase database;
    DatabaseReference databaseReference =
        FirebaseDatabase.instance.reference().child('users/$currentUserId');
    // get data snapshot from DB
    databaseReference.once().then((DataSnapshot userData) {
      // check if its null
      if (userData != null) {
        // save to CurrentUser model
        currentUser = CurrentUser.fromSnapshot(userData);
      }
    });
  }

  static Future findAddressByCoord(Position coord, context) async {
    // dummy var
    var address = '';

    // check either connectivity lost or not available
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return address;
    }

    // Get Data
    String URL =
        'https://us1.locationiq.com/v1/reverse.php?key=pk.423bcf21478b32ab5c909b792ec84718&lat=${coord.latitude}&lon=${coord.longitude}&format=json';

    var response = await HttpReqHelper.getRequest(URL);

    if (response != 'failed') {
      address = response['display_name'];

      // pass data to Models so it can be updated in AppData.dart
      Address addressModel = Address();
      addressModel.latitude = coord.latitude;
      addressModel.longitude = coord.longitude;
      addressModel.formattedAddress = address;

      // notify AppData that there should be an update
      Provider.of<AppData>(context, listen: false)
          .updatePickupPoint(addressModel);
    }

    return address;
  }

  static Future findRoutes(LatLng pickupPoint, LatLng destPoint) async {
    // Get Response
    var URL =
        "https://us1.locationiq.com/v1/directions/driving/${pickupPoint.longitude},${pickupPoint.latitude};${destPoint.longitude},${destPoint.latitude}?key=$locationIQKeys&overview=full";

    var response = await HttpReqHelper.getRequest(URL);

    // if response failed
    if (response == 'Failed') {
      return;
    }
    if (response == null) {
      return;
    }

    // assign value to Model
    Routes routesModels = Routes();

    routesModels.destDistanceM =
        response["routes"][0]["distance"].round().toString();
    routesModels.destDistanceKM =
        (response["routes"][0]["distance"] / 1000).round().toString();
    routesModels.destDuration =
        (response["routes"][0]["duration"] / 60).round().toString();
    routesModels.encodedPoints = response["routes"][0]["geometry"];

    return routesModels;
  }

  static calculateFares(Routes routes) {
    // BASE FARES -> RP.3000
    // DISTANCE FARES -> RP.2000
    // TIME FARES -> RP.1000
    double baseFares = 5000;
    double distFares = (double.parse(routes.destDistanceKM) * 5000);
    double timeFares = (double.parse(routes.destDuration) * 500);

    int totalCalc = (baseFares + distFares + timeFares).toInt();
    String totalFares =
        NumberFormat.currency(locale: 'id', symbol: 'IDR ', decimalDigits: 0)
            .format(totalCalc);

    return totalFares;
  }

  static calculateFreshFares(Routes routes) {
    // BASE FARES -> RP.3000
    // DISTANCE FARES -> RP.2000
    // TIME FARES -> RP.1000
    double baseFares = 5000;
    double distFares = (double.parse(routes.destDistanceKM) * 5000);
    double timeFares = (double.parse(routes.destDuration) * 500);

    int totalCalc = (baseFares + distFares + timeFares).toInt();

    return totalCalc;
  }
}
