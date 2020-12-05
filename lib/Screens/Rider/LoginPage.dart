import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
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
                  FlatButton(
                    height: 40,
                    minWidth: 300,
                    onPressed: () {},
                    color: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text('Sign in',
                        style: TextStyle(
                          fontFamily: 'Bolt-Semibold',
                          color: Colors.white,
                        )),
                  ),
                  FlatButton(
                    onPressed: () {},
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
