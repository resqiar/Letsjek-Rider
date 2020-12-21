import 'package:flutter/material.dart';
import 'package:uber_clone/models/PredictionsPlace.dart';

class PlacePredictionsTile extends StatelessWidget {
  // DATA FROM PREDICTIONS CLASS
  final PredictionsPlace predictionsPlace;

  PlacePredictionsTile(this.predictionsPlace);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.location_pin, color: Colors.grey),
          SizedBox(
            width: 8,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  predictionsPlace.displayPlace,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(fontSize: 16, fontFamily: 'Bolt-Semibold'),
                ),
                Text(
                  predictionsPlace.displayName,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
