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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => LoadingDialog(messageText: "Getting details..."),
    );

    DatabaseReference tripRequestsRef = FirebaseDatabase.instance.ref().child("tripRequests").child(tripID);

    tripRequestsRef.once().then((dataSnapshot) {
      Navigator.pop(context);

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
        tripDetailsInfo.pickupAddress = valueMap["pickUpAddress"] ?? "Unknown address";
        tripDetailsInfo.dropOffLatLng = LatLng(dropOffLat, dropOffLng);
        tripDetailsInfo.dropOffAddress = valueMap["dropOffAddress"] ?? "Unknown address";
        tripDetailsInfo.userName = valueMap["userName"] ?? "Unknown user";
        tripDetailsInfo.userPhone = valueMap["userPhone"] ?? "Unknown phone";
        tripDetailsInfo.tripID = tripID;

        showDialog(
          context: context,
          builder: (BuildContext context) => NotificationDialog(tripDetailsInfo: tripDetailsInfo),
        );
      } else {
        // Handle null case appropriately, e.g., show an error dialog
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text('Error'),
            content: Text('Failed to retrieve trip details.'),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }).catchError((error) {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text('Error'),
          content: Text('An error occurred: $error'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    });
  }
}
