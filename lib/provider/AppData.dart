import 'package:flutter/widgets.dart';
import 'package:uber_clone/models/Address.dart';

class AppData extends ChangeNotifier {
  // ! Everthing in here will be available all around app

  /******************************************/
  // save user pickup point
  Address pickupPoint;

  // method to save and update pickupPoint
  void updatePickupPoint(Address point) {
    this.pickupPoint = point;
    notifyListeners();
  }
  /******************************************/
}
