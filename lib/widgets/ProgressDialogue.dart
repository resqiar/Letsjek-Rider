import 'package:flutter/material.dart';

class ProgressDialogue extends StatelessWidget {
  final String status;

  ProgressDialogue(this.status);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.3,
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 10,
              ),
              Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Colors.grey)),
              ),
              SizedBox(
                height: 20,
              ),
              Text(status,
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontFamily: 'Bolt-Semibold')),
            ],
          ),
        ),
      ),
    );
  }
}
