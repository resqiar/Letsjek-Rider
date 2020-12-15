import 'package:connectivity/connectivity.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uber_clone/helpers/HttpReqHelper.dart';

class HttpRequestMethod {
  static Future findAddressByCoord(Position coord) async {
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
    }

    return address;
  }
}
