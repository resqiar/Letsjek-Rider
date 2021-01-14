import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:uber_clone/Screens/Auth/LoginPage.dart';
import 'package:uber_clone/widgets/ProgressDialogue.dart';
import 'package:uber_clone/widgets/SubmitFlatButton.dart';
import 'package:connectivity/connectivity.dart';

class RegisterPage extends StatefulWidget {
  static const id = 'registerpage';

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final fullnameController = TextEditingController();

  final emailController = TextEditingController();

  final phoneController = TextEditingController();

  final passController = TextEditingController();

  void registerUser() async {
    // show loading circular bar
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => ProgressDialogue("Please wait..."),
    );

    try {
      UserCredential user = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: emailController.text, password: passController.text);

      // adding additional data to user's database
      final DatabaseReference dbRef =
          FirebaseDatabase.instance.reference().child('users/${user.user.uid}');

      // prepare to save all the data
      Map userDataMap = {
        'fullname': fullnameController.text,
        'email': emailController.text,
        'phone': phoneController.text
      };

      // push data to db
      dbRef.set(userDataMap);

      // if everything is okay then push user to MainPage
      Navigator.pushNamedAndRemoveUntil(context, 'mainpage', (route) => false);
    } on FirebaseException catch (e) {
      // if there is an error - hide loading screen - show error snackbar
      Navigator.pop(context);

      // show error from firebase callback code
      if (e.code == 'weak-password') {
        showSnackbar("Password too weak");
      } else if (e.code == 'email-already-in-use') {
        showSnackbar("Email already registered");
      }
    } catch (e) {
      showSnackbar(e.toString());
    }
  }

  // Snackbar

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  void showSnackbar(String messages) {
    final snackbar = SnackBar(
      content: Text(
        messages,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18, fontFamily: 'Bolt-Semibold'),
      ),
    );

    scaffoldKey.currentState.showSnackBar(snackbar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Theme.of(context).primaryColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 80,
            ),
            Image(
              alignment: Alignment.center,
              height: 200,
              width: 200,
              image: (Theme.of(context).brightness == Brightness.light)
                  ? AssetImage('resources/images/icon_removed_bg.png')
                  : AssetImage('resources/images/icon_light.png'),
            ),
            Text(
              'Sign up new rider\'s account',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontFamily: 'Bolt-Semibold',
              ),
            ),
            Container(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  TextField(
                    controller: fullnameController,
                    keyboardType: TextInputType.text,
                    style: TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                        labelText: 'Fullname',
                        labelStyle: TextStyle(
                          fontSize: 14,
                        ),
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        hintText: 'enter your fullname'),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                        labelText: 'Email Adress',
                        labelStyle: TextStyle(
                          fontSize: 14,
                        ),
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        hintText: 'yourusername@email.com'),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                        labelText: 'Phone Number',
                        labelStyle: TextStyle(
                          fontSize: 14,
                        ),
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        hintText: '+62xxxxxxx'),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: passController,
                    obscureText: true,
                    keyboardType: TextInputType.text,
                    style: TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(
                          fontSize: 14,
                        ),
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        hintText: 'enter password'),
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  SubmitFlatButton("Sign up", Colors.deepPurple, () async {
                    // check network validation
                    final connectivityResult =
                        await Connectivity().checkConnectivity();
                    if (connectivityResult != ConnectivityResult.mobile &&
                        connectivityResult != ConnectivityResult.wifi) {
                      showSnackbar(
                          'Check your internet connection and try again');
                      return;
                    }

                    // check everything is fil
                    if (fullnameController.text.isEmpty ||
                        emailController.text.isEmpty ||
                        phoneController.text.isEmpty ||
                        passController.text.isEmpty) {
                      showSnackbar("Please fill all the forms");
                      return;
                    }

                    // check username if < 3
                    if (fullnameController.text.length < 3) {
                      showSnackbar("Fullname atleast contains 3 characters");
                      return;
                    }

                    // check email is valid
                    if (!emailController.text.contains('@')) {
                      showSnackbar("Please provide a valid email address");
                      return;
                    }

                    // check if phone is valid
                    if (phoneController.text.length < 10) {
                      showSnackbar("Please provide a valid phone number");
                      return;
                    }
                    // check password is >= 8 characters
                    if (passController.text.length < 8) {
                      showSnackbar("Password atleast contains 8 characters");
                      return;
                    }

                    registerUser();
                  }),
                  FlatButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                          context, LoginPage.id, (route) => false);
                    },
                    child: Text('Already have an account? sign in here'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
