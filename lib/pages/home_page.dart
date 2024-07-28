import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../global/global_var.dart';
import '../pushNotification/push_notification_system.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Completer<GoogleMapController> googleMapCompleterController = Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;
  Position? currentPositionOfDriver;
  Color colorToShow = Colors.green;
  String titleToShow = "FICAR ONLINE";
  bool isDriverAvailable = false;
  DatabaseReference? newTripRequestReference;
  late StreamSubscription<DatabaseEvent> tripStatusSubscription;

  getCurrentLiveLocationOfDriver() async {
    Position positionOfUser = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
    currentPositionOfDriver = positionOfUser;
    driverCurrentPosition = currentPositionOfDriver;

    LatLng positionOfUserInLatLng = LatLng(currentPositionOfDriver!.latitude, currentPositionOfDriver!.longitude);

    CameraPosition cameraPosition = CameraPosition(target: positionOfUserInLatLng, zoom: 15);
    controllerGoogleMap!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    print("Current live location of driver obtained: $positionOfUserInLatLng");
  }

  goOnlineNow() {
    print("Attempting to go online...");
    Geofire.initialize("onlineDrivers");

    Geofire.setLocation(
      FirebaseAuth.instance.currentUser!.uid,
      currentPositionOfDriver!.latitude,
      currentPositionOfDriver!.longitude,
    ).then((_) {
      print("Driver is now online and location saved successfully!");
    });

    newTripRequestReference = FirebaseDatabase.instance.ref()
        .child("drivers")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child("newTripStatus");
    newTripRequestReference!.set("waiting");
    print("Driver newTripStatus set to waiting");

    tripStatusSubscription = newTripRequestReference!.onValue.listen((event) {
      if (event.snapshot.value != null) {
        saveDriverInfoToDatabase();
        print("New trip request received");
      }
    });
  }

  setAndGetLocationUpdates() {
    print("Setting and getting location updates...");
    positionStreamHomePage = Geolocator.getPositionStream()
        .listen((Position position) {
      currentPositionOfDriver = position;

      if (isDriverAvailable) {
        Geofire.setLocation(
          FirebaseAuth.instance.currentUser!.uid,
          currentPositionOfDriver!.latitude,
          currentPositionOfDriver!.longitude,
        ).then((_) {
          print("Updated driver location: $currentPositionOfDriver");
        });
      }

      LatLng positionLatLng = LatLng(position.latitude, position.longitude);
      controllerGoogleMap!.animateCamera(CameraUpdate.newLatLng(positionLatLng));
    });
  }

  goOfflineNow() {
    print("Attempting to go offline...");
    Geofire.removeLocation(FirebaseAuth.instance.currentUser!.uid).then((_) {
      print("Driver is now offline and location removed successfully!");
    });

    newTripRequestReference?.onDisconnect();
    newTripRequestReference?.remove();
    newTripRequestReference = null;
  }

  initializePushNotificationSystem() {
    PushNotificationSystem notificationSystem = PushNotificationSystem();
    notificationSystem.generateDeviceRegistrationToken();
    notificationSystem.startListeningForNewNotification(context);
    print("Push notification system initialized");
  }

  @override
  void initState() {
    super.initState();
    initializePushNotificationSystem();
    retrieveCurrentDriverInfo();
    listenForTripCompletion();
    print("HomePage initState called");
  }

  @override
  void dispose() {
    tripStatusSubscription.cancel();
    positionStreamHomePage?.cancel();
    super.dispose();
    print("HomePage disposed");
  }

  void listenForTripCompletion() {
    print("Listening for trip completion...");
    newTripRequestReference = FirebaseDatabase.instance.ref()
        .child("drivers")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child("newTripStatus");

    tripStatusSubscription = newTripRequestReference!.onValue.listen((event) {
      String? tripStatus = event.snapshot.value?.toString();
      print("Trip status updated: $tripStatus");
      if (tripStatus == "ended") {
        print("Trip has ended, calling resetHomePageState()");
        resetHomePageState();
      } else if (tripStatus != null) {
        print("Trip status is not ended: $tripStatus");
      } else {
        print("Trip status is null");
      }
    });
  }

  void resetHomePageState() {
    print("Resetting HomePage state after trip ended.");

    if (isDriverAvailable) {
      goOfflineNow(); // Vai offline automaticamente quando a corrida termina
      setState(() {
        isDriverAvailable = false;
        colorToShow = Colors.green;
        titleToShow = "FICAR ONLINE";
        print("Driver state set to offline");
      });
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
          (Route<dynamic> route) => false,
    ).then((_) {
      print("Navigated to HomePage after trip ended");
    });
  }

  saveDriverInfoToDatabase() async {
    DatabaseReference driverRef = FirebaseDatabase.instance.ref()
        .child("drivers")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child("tripDetails");

    Map driverTripDataMap = {
      "name": driverName,
      "phone": driverPhone,
      "photo": driverPhoto,
      "carDetails": {
        "carColor": carColor,
        "carModel": carModel,
        "carNumber": carNumber,
      }
    };

    driverRef.set(driverTripDataMap).then((_) {
      print("Driver trip details saved to database");
    });
  }

  retrieveCurrentDriverInfo() async {
    print("Retrieving current driver info...");
    await FirebaseDatabase.instance.ref()
        .child("drivers")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .once().then((snap) {
      driverName = (snap.snapshot.value as Map)["name"];
      driverPhone = (snap.snapshot.value as Map)["phone"];
      driverPhoto = (snap.snapshot.value as Map)["photo"];
      carColor = (snap.snapshot.value as Map)["car_details"]["carColor"];
      carModel = (snap.snapshot.value as Map)["car_details"]["carModel"];
      carNumber = (snap.snapshot.value as Map)["car_details"]["carNumber"];
      print("Driver info retrieved: $driverName, $driverPhone");
    });

    initializePushNotificationSystem();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ///google map
          GoogleMap(
            padding: const EdgeInsets.only(top: 136),
            mapType: MapType.normal,
            myLocationEnabled: true,
            initialCameraPosition: googlePlexInitialPosition,
            onMapCreated: (GoogleMapController mapController) {
              controllerGoogleMap = mapController;
              googleMapCompleterController.complete(controllerGoogleMap);
              getCurrentLiveLocationOfDriver();
              print("Google Map created");
            },
          ),

          Container(
            height: 136,
            width: double.infinity,
            color: Colors.black54,
          ),

          ///go online offline button
          Positioned(
            top: 61,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                        context: context,
                        isDismissible: false,
                        builder: (BuildContext context) {
                          return Container(
                            decoration: const BoxDecoration(
                              color: Colors.black87,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey,
                                  blurRadius: 5.0,
                                  spreadRadius: 0.5,
                                  offset: Offset(
                                    0.7,
                                    0.7,
                                  ),
                                ),
                              ],
                            ),
                            height: 300,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                              child: Column(
                                children: [
                                  const SizedBox(height: 11,),
                                  Text(
                                    (!isDriverAvailable) ? "FICAR ONLINE" : "FICAR OFFLINE",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 21,),
                                  Text(
                                    (!isDriverAvailable)
                                        ? "Você está prestes a ficar online, podendo receber notificação de novas corridas de usuários."
                                        : "Você está prestes a ficar offline, parando de receber notificações de novas corridas de usuários",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white30,
                                    ),
                                  ),
                                  const SizedBox(height: 25,),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            print("Back button pressed");
                                          },
                                          child: const Text(
                                            "VOLTAR",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.grey,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16,),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            if (!isDriverAvailable) {
                                              //go online
                                              goOnlineNow();
                                              //get driver location updates
                                              setAndGetLocationUpdates();

                                              Navigator.pop(context);

                                              setState(() {
                                                colorToShow = Colors.pink;
                                                titleToShow = "FICAR OFFLINE";
                                                isDriverAvailable = true;
                                                print("Driver state set to online");
                                              });
                                            } else {
                                              //go offline
                                              goOfflineNow();

                                              Navigator.pop(context);

                                              setState(() {
                                                colorToShow = Colors.green;
                                                titleToShow = "FICAR ONLINE";
                                                isDriverAvailable = false;
                                                print("Driver state set to offline");
                                              });
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: (titleToShow == "FICAR ONLINE")
                                                ? Colors.green
                                                : Colors.pink,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                          ),
                                          child: const Text(
                                            "CONFIRMAR",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorToShow,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    titleToShow,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
