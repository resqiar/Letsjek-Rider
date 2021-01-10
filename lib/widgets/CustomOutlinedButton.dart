import 'package:flutter/material.dart';

class CustomOutlinedButton extends StatelessWidget {
  final String title;
  final Color color;
  final Color textColor;
  final Function onpress;
  final bool fontIsBold;
  final double width;

  CustomOutlinedButton(
      {this.title,
      this.textColor,
      this.color,
      this.onpress,
      this.fontIsBold,
      this.width});

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      height: 40,
      minWidth: (width != null) ? width : 300,
      onPressed: onpress,
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: (fontIsBold) ? 'Bolt-Semibold' : 'Bolt-Regular',
          color: textColor,
        ),
      ),
    );
  }
}
