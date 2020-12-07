import 'package:flutter/material.dart';

class SubmitFlatButton extends StatelessWidget {
  final String title;
  final Color color;
  final Function onpress;

  SubmitFlatButton(this.title, this.color, this.onpress);

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      height: 40,
      minWidth: 300,
      onPressed: onpress,
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Bolt-Semibold',
          color: Colors.white,
        ),
      ),
    );
  }
}
