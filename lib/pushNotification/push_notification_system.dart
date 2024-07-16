import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/trip_details.dart';
import '../widgets/loading_dialog.dart';
import '../widgets/notification_dialog.dart';

class PushNotificationSystem
{
  FirebaseMessaging firebaseCloudMessaging = FirebaseMessaging.instance;

  Future<void> generateDeviceRegistrationToken() async {
    // Solicita permissão para notificações
    NotificationSettings settings = await firebaseCloudMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    print("Permissão de notificação concedida: ${settings.authorizationStatus}");

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Aguarda a obtenção do token APNS
      String? apnsToken = await firebaseCloudMessaging.getAPNSToken();
      print("APNS Token: $apnsToken");

      if (apnsToken != null) {
        // Aguarda a obtenção do token Firebase
        String? deviceToken = await firebaseCloudMessaging.getToken();
        print("Firebase Token: $deviceToken");

        if (deviceToken != null) {
          try {
            DatabaseReference tokenRef = FirebaseDatabase.instance.ref()
                .child("drivers")
                .child(FirebaseAuth.instance.currentUser!.uid)
                .child("deviceToken");

            await tokenRef.set(deviceToken);
            print("Token salvo com sucesso.");
            firebaseCloudMessaging.subscribeToTopic("drivers");
            firebaseCloudMessaging.subscribeToTopic("users");
          } catch (e) {
            print("Erro ao salvar token: $e");
          }
        } else {
          print("Token de dispositivo Firebase é nulo.");
        }
      } else {
        print("APNS token é nulo. Verifique as configurações de notificação e certificados.");
      }
    } else {
      print("Autorização de notificação não concedida.");
    }
  }

  startListeningForNewNotification(BuildContext context) async
  {

    /// 1. Terminated

    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? messageRemote)
    {
      if(messageRemote != null)
      {
        String tripID = messageRemote!.data["tripID"];
        retrieveTripRequestInfo(tripID, context);
      }
    });

    /// 2. Foreground

    FirebaseMessaging.onMessage.listen((RemoteMessage? messageRemote)
    {
      String tripID = messageRemote!.data["tripID"];
      retrieveTripRequestInfo(tripID, context);
    });

    /// 3. Background

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? messageRemote)
    {
      String tripID = messageRemote!.data["tripID"];
      retrieveTripRequestInfo(tripID, context);
    });

  }

  retrieveTripRequestInfo(String tripID, BuildContext context)
  {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => LoadingDialog(messageText: "Coletando detalhes...")
    );

   DatabaseReference tripRequestsRef = FirebaseDatabase.instance.ref().child("tripRequests").child("tripID");

   tripRequestsRef.once().then((dataSnapshot)
   {
      Navigator.pop(context);

      //Notification Sound

      TripDetails tripDetailsInfo = TripDetails();
      double pickUpLat = double.parse((dataSnapshot.snapshot.value! as Map)["pickUpLatLng"]["latitude"]);
      double pickUpLng = double.parse((dataSnapshot.snapshot.value! as Map)["pickUpLatLng"]["longitude"]);
      tripDetailsInfo.pickUpLatLng = LatLng(pickUpLat, pickUpLng);

      tripDetailsInfo.pickupAddress = (dataSnapshot.snapshot.value! as Map)["pickUpAddress"];

      double dropOffLat = double.parse((dataSnapshot.snapshot.value! as Map)["dropOffLatLng"]["latitude"]);
      double dropOffLng = double.parse((dataSnapshot.snapshot.value! as Map)["dropOffLatLng"]["longitude"]);
      tripDetailsInfo.dropOffLatLng = LatLng(dropOffLat, dropOffLng);

      tripDetailsInfo.dropOffAddress = (dataSnapshot.snapshot.value! as Map)["dropOffAddress"];

      tripDetailsInfo.userName = (dataSnapshot.snapshot.value! as Map)["userName"];
      tripDetailsInfo.dropOffAddress = (dataSnapshot.snapshot.value! as Map)["userPhone"];

      tripDetailsInfo.tripID = tripID;

      showDialog(
        context: context,
        builder: (BuildContext context) => NotificationDialog(tripDetailsInfo: tripDetailsInfo,)
      );
   });
  }
}