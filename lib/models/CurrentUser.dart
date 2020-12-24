import 'package:firebase_database/firebase_database.dart';

class CurrentUser {
  String userId;
  String userEmail;
  String userPhone;
  String userFullname;

  CurrentUser({
    this.userId,
    this.userFullname,
    this.userEmail,
    this.userPhone,
  });

  // CONVERT SNAPSHOT
  CurrentUser.fromSnapshot(DataSnapshot userData) {
    userId = userData.key;
    userEmail = userData.value['email'];
    userFullname = userData.value['fullname'];
    userPhone = userData.value['phone'];
  }
}
