import 'package:connectivity/connectivity.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uber_clone/helpers/HttpReqHelper.dart';
import 'package:uber_clone/models/Address.dart';
import 'package:uber_clone/models/Routes.dart';
import 'package:uber_clone/provider/AppData.dart';
import 'package:uber_clone/global.dart' as global;

class HttpRequestMethod {
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

  static Future<Routes> findRoutes(LatLng pickupPoint, LatLng destPoint) async {
    // Get Response
    var URL =
        "https://us1.locationiq.com/v1/directions/driving/${pickupPoint.longitude},${pickupPoint.latitude};${destPoint.longitude},${destPoint.latitude}?key=${global.locationIQKeys}&overview=full";

    var response = await HttpReqHelper.getRequest(URL);

    // if response failed
    if (response == 'failed') return null;

    // assign value to Model
    Routes routesModels = Routes();

    routesModels.destDistanceM = response["routes"][0]["distance"].toString();
    routesModels.destDistanceKM =
        (response["routes"][0]["distance"] / 1000).round().toStringAsFixed(0);
    routesModels.destDuration =
        (response["routes"][0]["duration"] / 60).round().toStringAsFixed(0);
    routesModels.encodedPoints = response["routes"][0]["geometry"];

    return routesModels;
  }
}
