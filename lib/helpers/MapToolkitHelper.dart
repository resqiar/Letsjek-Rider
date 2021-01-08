import 'package:maps_toolkit/maps_toolkit.dart' as mp;

class MapToolkitHelper {
  static double calcRotations(mp.LatLng sourceCoords, mp.LatLng destCoords) {
    var rotation = mp.SphericalUtil.computeHeading(sourceCoords, destCoords);

    return rotation;
  }
}
