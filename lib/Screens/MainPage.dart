import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Main Page'),
      ),
      body: Center(
        child: MaterialButton(
          onPressed: () {
            DatabaseReference dbRef =
                FirebaseDatabase.instance.reference().child('testing_node');
            dbRef.set('IsConnectedAlready');
          },
          height: 50,
          minWidth: 300,
          color: Colors.blue,
          child: Text('Testing Connection'),
        ),
      ),
    );
  }
}
