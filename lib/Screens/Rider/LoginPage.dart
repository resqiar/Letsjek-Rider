import 'package:flutter/material.dart';
import 'package:uber_clone/Screens/Rider/RegisterPage.dart';
import 'package:uber_clone/widgets/SubmitFlatButton.dart';

class LoginPage extends StatelessWidget {
  static const id = 'loginpage';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  SubmitFlatButton('Sign in', Colors.green, () {}),
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
