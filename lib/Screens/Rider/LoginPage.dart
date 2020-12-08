import 'package:connectivity/connectivity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uber_clone/Screens/Rider/RegisterPage.dart';
import 'package:uber_clone/widgets/SubmitFlatButton.dart';

class LoginPage extends StatefulWidget {
  static const id = 'loginpage';

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();

  final passwordController = TextEditingController();

  void loginUser() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: emailController.text, password: passwordController.text);

      // if there is no error push user to mainpage
      Navigator.pushNamedAndRemoveUntil(context, 'mainpage', (route) => false);
    } on FirebaseException catch (e) {
      if (e.code == 'user-not-found') {
        showSnackbar('No user found for that email');
      } else if (e.code == 'wrong-password') {
        showSnackbar('Wrong password provided');
      }
    }
  }

  // snackbar setup
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
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 80,
            ),
            Image(
              alignment: Alignment.center,
              height: 100,
              width: 100,
              image: AssetImage('resources/images/logo.png'),
            ),
            SizedBox(
              height: 40,
            ),
            Text(
              'Sign in as a rider',
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
                    controller: passwordController,
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
                  SubmitFlatButton('Sign in', Colors.green, () async {
                    // check internet connectivity
                    final conResult = await Connectivity().checkConnectivity();
                    if (conResult == ConnectivityResult.none) {
                      showSnackbar(
                          "Please check your internet connection and try again");
                      return;
                    }

                    // check if all data has been filled
                    if (emailController.text.isEmpty ||
                        passwordController.text.isEmpty) {
                      showSnackbar("Please provide a valid data");
                      return;
                    }

                    // Login then
                    loginUser();
                  }),
                  FlatButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                          context, RegisterPage.id, (route) => false);
                    },
                    child: Text('Dont have account yet? signup here'),
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
