import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:uber_clone/widgets/CustomOutlinedButton.dart';

class ConfirmLogoutDialog extends StatelessWidget {
  final Function onpress;

  ConfirmLogoutDialog({this.onpress});
  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Theme.of(context).primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'resources/images/taxi.png',
              height: 100,
              width: 150,
            ),
            Text(
              'SIGN OUT',
              style: TextStyle(fontSize: 16, fontFamily: 'Bolt-Semibold'),
            ),
            SizedBox(
              height: 8,
            ),
            Text(
              'You are about to sign out and redirected to authentications page. Are you sure?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'Bolt-Semibold',
                color: Colors.grey,
              ),
            ),
            SizedBox(
              height: 24,
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: CustomOutlinedButton(
                      color: Colors.deepPurple,
                      fontIsBold: true,
                      textColor: Colors.white,
                      title: 'CANCEL',
                      onpress: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  Expanded(
                    child: CustomOutlinedButton(
                      color: Theme.of(context).primaryColor,
                      fontIsBold: false,
                      textColor: Colors.grey,
                      title: 'Logout',
                      onpress: onpress,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 4,
            ),
          ],
        ),
      ),
    );
  }
}
