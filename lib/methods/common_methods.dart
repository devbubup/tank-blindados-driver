import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drivers_app/global/global_var.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../models/direction_details.dart';

class CommonMethods
{
  checkConnectivity(BuildContext context) async
  {
    var connectionResult = await Connectivity().checkConnectivity();

    if(connectionResult != ConnectivityResult.mobile && connectionResult != ConnectivityResult.wifi)
    {
      if(!context.mounted) return;
      displaySnackBar("your Internet is not Available. Check your connection. Try Again.", context);
    }
  }

  displaySnackBar(String messageText, BuildContext context)
  {
    var snackBar = SnackBar(content: Text(messageText));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  turnOffLocationUpdatesForHomePage()
  {
    positionStreamHomePage!.pause();

    Geofire.removeLocation(FirebaseAuth.instance.currentUser!.uid);
  }

  turnOnLocationUpdatesForHomePage()
  {
    positionStreamHomePage!.resume();

    Geofire.setLocation(
      FirebaseAuth.instance.currentUser!.uid,
      driverCurrentPosition!.latitude,
      driverCurrentPosition!.longitude,
    );
  }

  static sendRequestToAPI(String apiUrl) async
  {
    http.Response responseFromAPI = await http.get(Uri.parse(apiUrl));

    try
    {
      if(responseFromAPI.statusCode == 200)
      {
        String dataFromApi = responseFromAPI.body;
        var dataDecoded = jsonDecode(dataFromApi);
        return dataDecoded;
      }
      else
      {
        return "error";
      }
    }
    catch(errorMsg)
    {
      return "error";
    }
  }

  ///Directions API
  static Future<DirectionDetails?> getDirectionDetailsFromAPI(LatLng source, LatLng destination) async
  {
    String urlDirectionsAPI = "https://maps.googleapis.com/maps/api/directions/json?destination=${destination.latitude},${destination.longitude}&origin=${source.latitude},${source.longitude}&mode=driving&key=$googleMapKey";

    var responseFromDirectionsAPI = await sendRequestToAPI(urlDirectionsAPI);

    if(responseFromDirectionsAPI == "error")
    {
      return null;
    }

    DirectionDetails detailsModel = DirectionDetails();

    detailsModel.distanceTextString = responseFromDirectionsAPI["routes"][0]["legs"][0]["distance"]["text"];
    detailsModel.distanceValueDigits = responseFromDirectionsAPI["routes"][0]["legs"][0]["distance"]["value"];

    detailsModel.durationTextString = responseFromDirectionsAPI["routes"][0]["legs"][0]["duration"]["text"];
    detailsModel.durationValueDigits = responseFromDirectionsAPI["routes"][0]["legs"][0]["duration"]["value"];

    detailsModel.encodedPoints = responseFromDirectionsAPI["routes"][0]["overview_polyline"]["points"];

    return detailsModel;
  }

  Future<double> calculateFareAmount(DirectionDetails directionDetails) async {
    // Fetch the driver's service type from the database
    String driverID = FirebaseAuth.instance.currentUser!.uid;
    DatabaseReference driverRef = FirebaseDatabase.instance.ref().child("drivers").child(driverID).child("car_details");
    DataSnapshot snapshot = await driverRef.child("serviceType").get();

    if (snapshot.exists) {
      String serviceType = snapshot.value.toString();

      double distancePerKmAmount;
      double baseFareAmount;

      // Set the fare amounts based on the service type
      switch (serviceType) {
        case "Sedan Exec.":
          distancePerKmAmount = 10;
          baseFareAmount = 25;
          break;
        case "Sedan Prime":
          distancePerKmAmount = 12;
          baseFareAmount = 30;
          break;
        case "SUV Especial":
          distancePerKmAmount = 15;
          baseFareAmount = 35;
          break;
        case "SUV Prime":
          distancePerKmAmount = 17;
          baseFareAmount = 40;
          break;
        case "Mini Van":
          distancePerKmAmount = 17;
          baseFareAmount = 45;
          break;
        case "Van":
          distancePerKmAmount = 18;
          baseFareAmount = 50;
          break;
        default:
        // Default values if the service type is not recognized
          distancePerKmAmount = 15;
          baseFareAmount = 20;
      }

      double totalDistanceTravelFareAmount = (directionDetails.distanceValueDigits! / 1000) * distancePerKmAmount;

      double overAllTotalFareAmount = baseFareAmount + totalDistanceTravelFareAmount;

      return double.parse(overAllTotalFareAmount.toStringAsFixed(2));
    } else {
      throw Exception("Service type not found for driver");
    }
  }

}