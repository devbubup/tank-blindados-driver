import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

String userName = "";

String googleMapKey = "AIzaSyBigH1cQcYYV1cf0wuj93ShJB59t1lXuMo";

const CameraPosition googlePlexInitialPosition = CameraPosition(
    target: LatLng(-21.92, -44.2),
    zoom: 14.4766
);

StreamSubscription<Position>? positionStreamHomePage;