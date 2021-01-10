import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:uber_clone/widgets/CustomOutlinedButton.dart';
import 'package:uber_clone/widgets/ListDivider.dart';
import 'package:uber_clone/widgets/ProgressDialogue.dart';

class CashPaymentDialog extends StatelessWidget {
  final String fares;

  CashPaymentDialog({this.fares});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Colors.white,
      child: Container(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 8,
            ),
            Text(
              'PAY CASH TO DRIVER',
              style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Bolt-Semibold',
                  color: Colors.grey),
            ),
            SizedBox(
              height: 8,
            ),
            ListDivider(),
            SizedBox(
              height: 16,
            ),
            Image.asset(
              'resources/images/taxi.png',
              height: 100,
              width: 150,
            ),
            SizedBox(
              height: 4,
            ),
            Text(
              fares,
              style: TextStyle(
                fontSize: 26,
                fontFamily: 'Bolt-Semibold',
              ),
            ),
            SizedBox(
              height: 8,
            ),
            Text(
              'This is the total amount of fares that you have to pay',
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 18,
            ),
            CustomOutlinedButton(
              color: Colors.blue,
              fontIsBold: true,
              textColor: Colors.white,
              title: 'PAY CASH',
              onpress: () {
                Navigator.pop(context, 'payed');
              },
              width: 250,
            ),
            SizedBox(
              height: 18,
            ),
          ],
        ),
      ),
    );
  }
}
