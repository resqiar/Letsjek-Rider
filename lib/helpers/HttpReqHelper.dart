import 'dart:convert';

import 'package:http/http.dart' as http;

class HttpReqHelper {
  static Future getRequest(String url) async {
    // make a request to url
    var response = await http.get(url);

    try {
      if (response.statusCode == 200) {
        String rawData = response.body;

        // Decode Raw Data to JSON
        var decodedData = jsonDecode(rawData);
        return decodedData;
      } else {
        return 'Failed';
      }
    } catch (e) {
      return e.toString();
    }
  }
}