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
  Completer<GoogleMapController> googleMapCompleterController = Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;
  Position? currentPositionOfDriver;
  Color colorToShow = const Color.fromRGBO(30, 170, 70, 1);
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
      } else if (tripStatus == "cancelado" || tripStatus == "cancelled") {
        print("Trip has been cancelled, showing alert...");
        showUserCancelledTripAlert();
      } else if (tripStatus != null) {
        print("Trip status is not ended: $tripStatus");
      } else {
        print("Trip status is null");
      }
    });
  }

  void resetHomePageState() {
    print("Entering resetHomePageState method.");
    if (isDriverAvailable) {
      print("Driver is online, setting driver to offline...");
      goOfflineNow(); // Vai offline automaticamente quando a corrida termina ou é cancelada
      setState(() {
        isDriverAvailable = false;
        colorToShow = const Color.fromRGBO(30, 170, 70, 1);
        titleToShow = "FICAR ONLINE";
        print("Driver state set to offline in UI.");
      });
    } else {
      print("Driver is already offline, no need to go offline again.");
    }

    // Reiniciar o controlador do Google Map
    controllerGoogleMap?.dispose();
    googleMapCompleterController = Completer<GoogleMapController>();

    // Navegar para a HomePage e remover todas as rotas anteriores
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
          (Route<dynamic> route) => false,
    ).then((_) {
      print("Successfully navigated back to HomePage and reset.");
    }).catchError((error) {
      print("Error navigating back to HomePage: $error");
    });
  }

  void showUserCancelledTripAlert() {
    print("Displaying cancellation alert...");
    showDialog(
      context: context,
      barrierDismissible: false, // Evita que o usuário feche o diálogo clicando fora
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Viagem Cancelada"),
          content: const Text("O usuário cancelou a viagem."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                print("User acknowledged cancellation alert");
                resetHomePageState();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
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
    }).catchError((error) {
      print("Failed to save driver trip details: $error");
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
    }).catchError((error) {
      print("Failed to retrieve driver info: $error");
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
            color: const Color.fromRGBO(0, 40, 30, 1),
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
                              color: Color.fromRGBO(0, 40, 30, 1),
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
                                      color: Color.fromRGBO(185, 150, 100, 1),
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
                                      color: Color.fromRGBO(185, 150, 100, 1),
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
                                                colorToShow = const Color.fromRGBO(240, 75, 20, 1);
                                                titleToShow = "FICAR OFFLINE";
                                                isDriverAvailable = true;
                                                print("Driver state set to online");
                                              });
                                            } else {
                                              //go offline
                                              goOfflineNow();

                                              Navigator.pop(context);

                                              setState(() {
                                                colorToShow = const Color.fromRGBO(30, 170, 70, 1);
                                                titleToShow = "FICAR ONLINE";
                                                isDriverAvailable = false;
                                                print("Driver state set to offline");
                                              });
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: (titleToShow == "FICAR ONLINE")
                                                ? const Color.fromRGBO(30, 170, 70, 1)
                                                : const Color.fromRGBO(240, 75, 20, 1),
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
