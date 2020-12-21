class PredictionsPlace {
  String placeId;
  String displayName;
  String displayPlace;
  String latitude;
  String longitude;

  PredictionsPlace({
    this.placeId,
    this.displayName,
    this.displayPlace,
    this.latitude,
    this.longitude,
  });

  // RETRIEVE JSON
  PredictionsPlace.fromJson(Map<String, dynamic> json) {
    placeId = json["place_id"];
    displayName = json["display_name"];
    displayPlace = json["display_place"];
    latitude = json["lat"];
    longitude = json["lon"];
  }
}
