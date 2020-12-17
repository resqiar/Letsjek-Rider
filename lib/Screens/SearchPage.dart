import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uber_clone/provider/AppData.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 220,
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
                left: 26,
                right: 26,
                bottom: 24,
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
                              readOnly: true,
                              decoration: InputDecoration(
                                hintText: (Provider.of<AppData>(context)
                                            .pickupPoint !=
                                        null)
                                    ? Provider.of<AppData>(context)
                                        .pickupPoint
                                        .formattedAddress
                                    : 'Unable to reach your locations',
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
        ],
      ),
    );
  }
}
