import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:drivers_app/global/global_var.dart';
import 'package:drivers_app/models/trip_details.dart';
import 'package:drivers_app/widgets/loading_dialog.dart';
import 'package:drivers_app/widgets/notification_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Variável global para monitorar o estado da corrida
bool isTripInProgress = false;

class PushNotificationSystem {
  FirebaseMessaging firebaseCloudMessaging = FirebaseMessaging.instance;

  Future<String?> generateDeviceRegistrationToken() async {
    String? deviceRecognitionToken = await firebaseCloudMessaging.getToken();
    DatabaseReference referenceOnlineDriver = FirebaseDatabase.instance.ref()
        .child("drivers")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child("deviceToken");

    referenceOnlineDriver.set(deviceRecognitionToken);

    firebaseCloudMessaging.subscribeToTopic("drivers");
    firebaseCloudMessaging.subscribeToTopic("users");
  }

  startListeningForNewNotification(BuildContext context) async {
    // Terminated
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? messageRemote) {
      if (messageRemote != null) {
        String tripID = messageRemote.data["tripID"];
        retrieveTripRequestInfo(tripID, context);
      }
    });

    // Foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage? messageRemote) {
      if (messageRemote != null) {
        String tripID = messageRemote.data["tripID"];
        retrieveTripRequestInfo(tripID, context);
      }
    });

    // Background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? messageRemote) {
      if (messageRemote != null) {
        String tripID = messageRemote.data["tripID"];
        retrieveTripRequestInfo(tripID, context);
      }
    });
  }

  retrieveTripRequestInfo(String tripID, BuildContext context) {
    if (isTripInProgress) {
      return;
    }

    isTripInProgress = true;

    final currentContext = context; // Captura o contexto atual antes de operações assíncronas

    showDialog(
      context: currentContext,
      barrierDismissible: false,
      builder: (BuildContext context) => LoadingDialog(messageText: "Coletando detalhes..."),
    );

    DatabaseReference tripRequestsRef = FirebaseDatabase.instance.ref().child("tripRequests").child(tripID);

    tripRequestsRef.once().then((dataSnapshot) {
      Navigator.pop(currentContext); // Usa o contexto capturado anteriormente

      if (dataSnapshot.snapshot.value != null) {
        Map<String, dynamic> valueMap = Map<String, dynamic>.from(dataSnapshot.snapshot.value as Map);
        TripDetails tripDetailsInfo = TripDetails();

        // Safe extraction and conversion of latitude and longitude
        Map pickUpLatLng = valueMap["pickUpLatLng"] ?? {};
        Map dropOffLatLng = valueMap["dropOffLatLng"] ?? {};

        double pickUpLat = double.tryParse(pickUpLatLng["latitude"]?.toString() ?? '0.0') ?? 0.0;
        double pickUpLng = double.tryParse(pickUpLatLng["longitude"]?.toString() ?? '0.0') ?? 0.0;
        double dropOffLat = double.tryParse(dropOffLatLng["latitude"]?.toString() ?? '0.0') ?? 0.0;
        double dropOffLng = double.tryParse(dropOffLatLng["longitude"]?.toString() ?? '0.0') ?? 0.0;

        tripDetailsInfo.pickUpLatLng = LatLng(pickUpLat, pickUpLng);
        tripDetailsInfo.pickupAddress = valueMap["pickUpAddress"] ?? "Endereço Desconhecido";
        tripDetailsInfo.dropOffLatLng = LatLng(dropOffLat, dropOffLng);
        tripDetailsInfo.dropOffAddress = valueMap["dropOffAddress"] ?? "Endereço Desconhecido";
        tripDetailsInfo.userName = valueMap["userName"] ?? "Unknown user";
        tripDetailsInfo.userPhone = valueMap["userPhone"] ?? "Unknown phone";
        tripDetailsInfo.tripID = tripID;

        showDialog(
          context: currentContext, // Usa o contexto capturado anteriormente
          builder: (BuildContext context) => NotificationDialog(tripDetailsInfo: tripDetailsInfo),
        ).then((_) {
          // Reset the trip in progress status when the notification dialog is dismissed
          isTripInProgress = false;
        });
      } else {
        // Handle null case appropriately, e.g., show an error dialog
        showDialog(
          context: currentContext, // Usa o contexto capturado anteriormente
          builder: (BuildContext context) => AlertDialog(
            title: Text('Erro'),
            content: Text('Falha nas informações da viagem.'),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                  isTripInProgress = false;
                },
              ),
            ],
          ),
        );
      }
    }).catchError((error) {
      Navigator.pop(currentContext); // Usa o contexto capturado anteriormente
      showDialog(
        context: currentContext, // Usa o contexto capturado anteriormente
        builder: (BuildContext context) => AlertDialog(
          title: Text('Error'),
          content: Text('An error occurred: $error'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                isTripInProgress = false;
              },
            ),
          ],
        ),
      );
    });
  }
}
