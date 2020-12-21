import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uber_clone/models/Address.dart';
import 'package:uber_clone/models/PredictionsPlace.dart';
import 'package:uber_clone/provider/AppData.dart';

class PlacePredictionsTile extends StatelessWidget {
  // DATA FROM PREDICTIONS CLASS
  final PredictionsPlace predictionsPlace;

  PlacePredictionsTile(this.predictionsPlace);

  void selectedPlace(context) async {
    // UPDATE ADDRESS
    Address selectedPlace = Address();

    selectedPlace.id = predictionsPlace.placeId;
    selectedPlace.rawAdress = predictionsPlace.displayPlace;
    selectedPlace.formattedAddress = predictionsPlace.displayName;
    selectedPlace.latitude = double.parse(predictionsPlace.latitude);
    selectedPlace.longitude = double.parse(predictionsPlace.longitude);

    // UPDATE PROVIDER
    Provider.of<AppData>(context, listen: false)
        .updatePickupPoint(selectedPlace);
  }

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      padding: EdgeInsets.all(0),
      onPressed: () => {selectedPlace(context)},
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
      ),
    );
  }
}
