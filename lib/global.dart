import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uber_clone/models/CurrentUser.dart';

String gmapsKey = "AIzaSyCM4XZY3uKnCmrIL3hatqO1drjqp-RhC6g";
String locationIQKeys = "pk.423bcf21478b32ab5c909b792ec84718";

FirebaseAuth firebaseAuth;

CurrentUser currentUser;

// FCM SERVER KEY
String FCM_SERVER_KEYS =
    'key=AAAA2gFOnu4:APA91bFjftBJMzX5QuBCce850T1_HCLMSA1BlqQ2B_agxZ4a8tOObJyHF7RfNVHck_sdCd6UEnP8QF-aJWNsZxPb0lRXe4_sM3CF-FQUbapa_LsSIwc4UrZD7AMJP95IUoj2K79ctZBk';

int timerCountdown = 15;

// TODO: MONITORING TRIP REQUEST
StreamSubscription<Event> driverStatusRef;
LatLng driverCoords;
String tripStatus = '';
String tripStatusText = '';
String tripDriverFullName = '';
String tripDriverPhoneNumber = '';
String tripDriverCarBrand = '';
String tripDriverCarPlate = '';
String tripDriverCarColor = '';
String tripDriverEstimatedTime = '';
String tripDriverEstimatedKM = '0';
String tripDriverEstimatedM = '';
