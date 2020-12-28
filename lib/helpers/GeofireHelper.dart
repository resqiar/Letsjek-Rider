import 'package:uber_clone/models/NearbyDrivers.dart';

class GeofireHelper {
  // LIST OF AVAILABLE DRIVER
  static List nearbyDriverList = [];

  // REMOVE DRIVER FROM THE LIST
  static void removeDriver(String key) {
    int driverIndex =
        nearbyDriverList.indexWhere((value) => value.driverKey == key);
    nearbyDriverList.removeAt(driverIndex);
  }

  // UPDATE DRIVER LOCATION AS THEY MOVE
  static void updateDriver(NearbyDrivers nearbyDrivers) {
    int driverIndex = nearbyDriverList
        .indexWhere((value) => value.driverKey == nearbyDrivers.driverKey);

    nearbyDriverList[driverIndex].latitude = nearbyDrivers.latitude;
    nearbyDriverList[driverIndex].longitude = nearbyDrivers.longitude;
  }
}
