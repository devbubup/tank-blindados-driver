import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drivers_app/global/global_var.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import '../models/direction_details.dart';

class CommonMethods {
  checkConnectivity(BuildContext context) async {
    var connectionResult = await Connectivity().checkConnectivity();

    if (connectionResult != ConnectivityResult.mobile &&
        connectionResult != ConnectivityResult.wifi) {
      if (!context.mounted) return;
      displaySnackBar(
          "Sua internet não está disponível. Verifique sua conexão e tente novamente.",
          context);
    }
  }

  displaySnackBar(String messageText, BuildContext context) {
    var snackBar = SnackBar(content: Text(messageText));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Método displayToastMessage implementado
  displayToastMessage(String message, BuildContext context) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: Colors.black54,
      textColor: Colors.white,
      gravity: ToastGravity.BOTTOM,
      fontSize: 16.0,
    );
  }

  turnOffLocationUpdatesForHomePage() {
    positionStreamHomePage?.pause();

    Geofire.removeLocation(FirebaseAuth.instance.currentUser!.uid);
  }

  turnOnLocationUpdatesForHomePage() {
    positionStreamHomePage?.resume();

    Geofire.setLocation(
      FirebaseAuth.instance.currentUser!.uid,
      driverCurrentPosition!.latitude,
      driverCurrentPosition!.longitude,
    );
  }

  static sendRequestToAPI(String apiUrl) async {
    http.Response responseFromAPI = await http.get(Uri.parse(apiUrl));

    try {
      if (responseFromAPI.statusCode == 200) {
        String dataFromApi = responseFromAPI.body;
        var dataDecoded = jsonDecode(dataFromApi);
        return dataDecoded;
      } else {
        return "error";
      }
    } catch (errorMsg) {
      return "error";
    }
  }

  /// Directions API
  static Future<DirectionDetails?> getDirectionDetailsFromAPI(
      LatLng source, LatLng destination) async {
    String urlDirectionsAPI =
        "https://maps.googleapis.com/maps/api/directions/json?destination=${destination.latitude},${destination.longitude}&origin=${source.latitude},${source.longitude}&mode=driving&key=$googleMapKey";

    var responseFromDirectionsAPI = await sendRequestToAPI(urlDirectionsAPI);

    if (responseFromDirectionsAPI == "error") {
      return null;
    }

    DirectionDetails detailsModel = DirectionDetails();

    detailsModel.distanceTextString = responseFromDirectionsAPI["routes"][0]
    ["legs"][0]["distance"]["text"];
    detailsModel.distanceValueDigits = responseFromDirectionsAPI["routes"][0]
    ["legs"][0]["distance"]["value"];

    detailsModel.durationTextString = responseFromDirectionsAPI["routes"][0]
    ["legs"][0]["duration"]["text"];
    detailsModel.durationValueDigits = responseFromDirectionsAPI["routes"][0]
    ["legs"][0]["duration"]["value"];

    detailsModel.encodedPoints =
    responseFromDirectionsAPI["routes"][0]["overview_polyline"]["points"];

    return detailsModel;
  }

  Future<double> calculateFareAmount(DirectionDetails directionDetails) async {
    // Obter o tipo de serviço do motorista do banco de dados
    String driverID = FirebaseAuth.instance.currentUser!.uid;
    DatabaseReference driverRef = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(driverID)
        .child("car_details");
    DataSnapshot snapshot = await driverRef.child("serviceType").get();

    if (snapshot.exists) {
      String serviceType = snapshot.value.toString();

      double distancePerKmAmount;
      double baseFareAmount;

      // Definir os valores das tarifas com base no tipo de serviço
      switch (serviceType) {
        case "Sedan Exec.":
          distancePerKmAmount = 0.1;
          baseFareAmount = 1;
          break;
        case "Sedan Prime":
          distancePerKmAmount = 0.2;
          baseFareAmount = 1;
          break;
        case "SUV Especial":
          distancePerKmAmount = 0.2;
          baseFareAmount = 1;
          break;
        case "SUV Prime":
          distancePerKmAmount = 0.3;
          baseFareAmount = 1;
          break;
        default:
        // Valores padrão se o tipo de serviço não for reconhecido
          distancePerKmAmount = 0.1;
          baseFareAmount = 1;
      }

      double totalDistanceTravelFareAmount =
          (directionDetails.distanceValueDigits! / 1000) *
              distancePerKmAmount;

      double overAllTotalFareAmount =
          baseFareAmount + totalDistanceTravelFareAmount;

      return double.parse(overAllTotalFareAmount.toStringAsFixed(0));
    } else {
      throw Exception("Tipo de serviço não encontrado para o motorista");
    }
  }
}
