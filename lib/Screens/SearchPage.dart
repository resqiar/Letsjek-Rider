import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uber_clone/helpers/HttpReqHelper.dart';
import 'package:uber_clone/models/PredictionsPlace.dart';
import 'package:uber_clone/provider/AppData.dart';
import 'package:uber_clone/global.dart' as global;
import 'package:uber_clone/widgets/ListDivider.dart';
import 'package:uber_clone/widgets/PlacePredictionsTile.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  var pickupTextController = TextEditingController();
  var destTextController = TextEditingController();

  // ! DUMMY PREDICTIONS LIST ! //
  List<PredictionsPlace> predictionsList = [];

  // ? Search Place Method ? //
  void searchPlace(String place) async {
    // URL
    String URL =
        "https://api.locationiq.com/v1/autocomplete.php?key=${global.locationIQKeys}&q=$place&limit=5&countrycodes=id";

    // CHECK IF NULL
    if (place.length < 1) return;

    // GET RESPONSE
    var response = await HttpReqHelper.getRequest(URL);

    // CHECK IF FAILED
    if (response == 'failed' || response == null) {
      return;
    } else {
      // CONVERT JSON RESPONSE TO A LIST
      final convertToList =
          (response as List).map((e) => PredictionsPlace.fromJson(e)).toList();

      setState(() {
        predictionsList = convertToList;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // address from AppData
    String address =
        Provider.of<AppData>(context).pickupPoint.formattedAddress ?? '';
    pickupTextController.text = address;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.31,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    spreadRadius: 0.5,
                    blurRadius: 5.0,
                    offset: Offset(0.7, 0.7),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 28,
                  left: 16,
                  right: 16,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 14,
                    ),
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Icon(Icons.arrow_back_ios),
                        ),
                        Center(
                          child: Text(
                            'Search Destination',
                            style: TextStyle(
                              fontFamily: 'Bolt-semibold',
                              fontSize: 18,
                            ),
                          ),
                        )
                      ],
                    ),
                    SizedBox(
                      height: 18,
                    ),
                    Row(
                      children: [
                        Image.asset(
                          'resources/images/pickicon.png',
                          height: 16,
                          width: 16,
                        ),
                        SizedBox(
                          width: 18,
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.lightGreen[50],
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: TextField(
                                controller: pickupTextController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  hintText: 'Pickup Location',
                                  filled: true,
                                  border: InputBorder.none,
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 18),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    Row(
                      children: [
                        Image.asset(
                          'resources/images/desticon.png',
                          height: 16,
                          width: 16,
                        ),
                        SizedBox(
                          width: 18,
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.lightBlue[50],
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: TextField(
                                controller: destTextController,
                                onChanged: (value) => searchPlace(value),
                                autofocus: true,
                                decoration: InputDecoration(
                                  hintText: 'Where to?',
                                  hintStyle:
                                      TextStyle(fontFamily: 'Bolt-Semibold'),
                                  filled: true,
                                  border: InputBorder.none,
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 18),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            (predictionsList.length > 0)
                ? ListView.separated(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                    itemBuilder: (context, index) {
                      return PlacePredictionsTile(predictionsList[index]);
                    },
                    separatorBuilder: (context, index) => ListDivider(),
                    itemCount: predictionsList.length,
                    shrinkWrap: true,
                    physics: ClampingScrollPhysics(),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}
