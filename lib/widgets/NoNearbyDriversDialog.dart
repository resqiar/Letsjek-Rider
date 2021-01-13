import 'package:flutter/material.dart';
import 'package:uber_clone/widgets/ListDivider.dart';
import 'package:uber_clone/widgets/SubmitFlatButton.dart';

class NoNearbyDriversDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Theme.of(context).primaryColor,
      child: Container(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 8,
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'No Nearby Drivers Found',
                style: TextStyle(fontSize: 22, fontFamily: 'Bolt-Semibold'),
              ),
            ),
            SizedBox(
              height: 8,
            ),
            ListDivider(),
            SizedBox(
              height: 8,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'There are no nearby drivers within 20km away, we suggest you to try again later!',
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontFamily: 'Bolt-Semibold'),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              height: 8,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SubmitFlatButton(
                  'CLOSE',
                  (Theme.of(context).brightness == Brightness.dark)
                      ? Colors.deepPurple
                      : Colors.deepOrange, () {
                Navigator.pop(context);
              }),
            ),
            SizedBox(
              height: 8,
            ),
          ],
        ),
      ),
    );
  }
}
