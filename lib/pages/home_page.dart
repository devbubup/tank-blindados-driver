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
  Completer<GoogleMapController> googleMapCompleterController =
  Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;
  Position? currentPositionOfDriver;
  Color colorToShow = const Color.fromRGBO(30, 170, 70, 1);
  String titleToShow = "FICAR ONLINE";
  bool isDriverAvailable = false;
  DatabaseReference? tripRequestRef;
  StreamSubscription<DatabaseEvent>? tripRequestSubscription;
  StreamSubscription<DatabaseEvent>? tripStatusSubscription;
  String? currentTripID;
  StreamSubscription<DatabaseEvent>? driverStatusSubscription;
  StreamSubscription<Position>? positionStreamHomePage;

  @override
  void initState() {
    super.initState();
    initializePushNotificationSystem();
    retrieveCurrentDriverInfo();
    getDriverOnlineStatus();
    listenToDriverOnlineStatus();
    print("HomePage initState called");
  }

  @override
  void dispose() {
    tripRequestSubscription?.cancel();
    tripStatusSubscription?.cancel();
    positionStreamHomePage?.cancel();
    driverStatusSubscription?.cancel(); // Cancele o listener
    super.dispose();
    print("HomePage disposed");
  }

  void getCurrentLiveLocationOfDriver() async {
    Position positionOfUser = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
    currentPositionOfDriver = positionOfUser;
    driverCurrentPosition = currentPositionOfDriver;

    LatLng positionOfUserInLatLng =
    LatLng(currentPositionOfDriver!.latitude, currentPositionOfDriver!.longitude);

    CameraPosition cameraPosition =
    CameraPosition(target: positionOfUserInLatLng, zoom: 15);
    controllerGoogleMap!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    print("Current live location of driver obtained: $positionOfUserInLatLng");
  }

  void goOnlineNow() {
    print("Attempting to go online...");
    Geofire.initialize("onlineDrivers");

    String driverId = FirebaseAuth.instance.currentUser!.uid;

    if (currentPositionOfDriver == null) {
      print("Current position is null. Cannot go online.");
      return;
    }

    double latitude = currentPositionOfDriver!.latitude;
    double longitude = currentPositionOfDriver!.longitude;

    // Atualiza o status isOnline no banco de dados
    FirebaseDatabase.instance.ref().child('drivers').child(driverId).update({
      'isOnline': true,
    });

    // Define a localização
    Geofire.setLocation(driverId, latitude, longitude).then((_) {
      print("Driver is now online and location saved successfully!");

      // Configura o onDisconnect
      DatabaseReference driverLocationRef = FirebaseDatabase.instance.ref().child("onlineDrivers").child(driverId);
      driverLocationRef.onDisconnect().remove().then((_) {
        print("Driver location will be removed when app disconnects.");
      });
    });

    setState(() {
      isDriverAvailable = true;
      colorToShow = const Color.fromRGBO(240, 75, 20, 1);
      titleToShow = "FICAR OFFLINE";
      print("Driver state set to online");
    });

    listenToTripRequests();
    setAndGetLocationUpdates();
  }


  void listenToDriverOnlineStatus() {
    String driverId = FirebaseAuth.instance.currentUser!.uid;
    DatabaseReference driverStatusRef = FirebaseDatabase.instance.ref().child('drivers').child(driverId).child('isOnline');

    driverStatusSubscription = driverStatusRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        bool isOnline = event.snapshot.value as bool;
        setState(() {
          isDriverAvailable = isOnline;
          colorToShow = isOnline ? const Color.fromRGBO(240, 75, 20, 1) : const Color.fromRGBO(30, 170, 70, 1);
          titleToShow = isOnline ? "FICAR OFFLINE" : "FICAR ONLINE";
        });
      }
    });
  }

  void goOfflineNow() {
    print("Attempting to go offline...");

    String driverId = FirebaseAuth.instance.currentUser!.uid;

    // Atualiza o status isOnline no banco de dados
    FirebaseDatabase.instance.ref().child('drivers').child(driverId).update({
      'isOnline': false,
    });

    Geofire.removeLocation(driverId).then((_) {
      print("Driver is now offline and location removed successfully!");

      // Cancela o onDisconnect
      DatabaseReference driverLocationRef = FirebaseDatabase.instance.ref().child("onlineDrivers").child(driverId);
      driverLocationRef.onDisconnect().cancel().then((_) {
        print("onDisconnect cancellation successful.");
      });
    });

    tripRequestSubscription?.cancel();
    tripStatusSubscription?.cancel();
    tripRequestRef = null;
    currentTripID = null;

    setState(() {
      isDriverAvailable = false;
      colorToShow = const Color.fromRGBO(30, 170, 70, 1);
      titleToShow = "FICAR ONLINE";
      print("Driver state set to offline");
    });
  }


  void getDriverOnlineStatus() async {
    String driverId = FirebaseAuth.instance.currentUser!.uid;
    DatabaseReference driverStatusRef = FirebaseDatabase.instance.ref().child('drivers').child(driverId).child('isOnline');

    DataSnapshot snapshot = await driverStatusRef.once() as DataSnapshot;

    if (snapshot.value != null) {
      bool isOnline = snapshot.value as bool;
      setState(() {
        isDriverAvailable = isOnline;
        colorToShow = isOnline ? const Color.fromRGBO(240, 75, 20, 1) : const Color.fromRGBO(30, 170, 70, 1);
        titleToShow = isOnline ? "FICAR OFFLINE" : "FICAR ONLINE";
      });
    }
  }


  void setAndGetLocationUpdates() {
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

  void listenToTripRequests() {
    print("Listening for trip requests...");
    tripRequestRef = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child("newTripID");

    tripRequestSubscription = tripRequestRef!.onValue.listen((event) {
      if (event.snapshot.value != null) {
        String tripID = event.snapshot.value.toString();
        print("New trip request received: $tripID");
        currentTripID = tripID;

        // Escutar o status da viagem
        listenToTripStatus();
      } else {
        print("No new trip requests.");
      }
    });
  }

  void listenToTripStatus() {
    if (currentTripID == null) return;

    DatabaseReference tripStatusRef = FirebaseDatabase.instance
        .ref()
        .child("All Bookings")
        .child(currentTripID!)
        .child("status");

    tripStatusSubscription = tripStatusRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        String tripStatus = event.snapshot.value.toString();
        print("Trip status updated: $tripStatus");

        if (tripStatus == "cancelled" || tripStatus == "cancelado") {
          print("Trip has been cancelled by the user.");

          // Fechar o NotificationDialog se estiver aberto
          Navigator.of(context, rootNavigator: true).pop('dialog');

          // Mostrar o alerta de cancelamento
          showUserCancelledTripAlert();

          // Parar de escutar o status da viagem
          tripStatusSubscription?.cancel();
          tripStatusSubscription = null;
        }
      }
    });
  }

  void showUserCancelledTripAlert() {
    print("Displaying cancellation alert...");
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            "Viagem Cancelada",
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            "O usuário cancelou a viagem.",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                print("User acknowledged cancellation alert");
              },
              child: const Text(
                "OK",
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }

  void initializePushNotificationSystem() {
    PushNotificationSystem notificationSystem = PushNotificationSystem();
    notificationSystem.generateDeviceRegistrationToken();
    notificationSystem.startListeningForNewNotification(context);
    print("Push notification system initialized");
  }

  void retrieveCurrentDriverInfo() async {
    print("Retrieving current driver info...");
    await FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .once()
        .then((snap) {
      if (snap.snapshot.value != null) {
        driverName = (snap.snapshot.value as Map)["name"];
        driverPhone = (snap.snapshot.value as Map)["phone"];
        driverPhoto = (snap.snapshot.value as Map)["photo"];
        carColor = (snap.snapshot.value as Map)["car_details"]["carColor"];
        carModel = (snap.snapshot.value as Map)["car_details"]["carModel"];
        carNumber = (snap.snapshot.value as Map)["car_details"]["carNumber"];
        print("Driver info retrieved: $driverName, $driverPhone");
      }
    }).catchError((error) {
      print("Failed to retrieve driver info: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// Google Map
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

          /// Botão para ficar online/offline
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 18),
                              child: Column(
                                children: [
                                  const SizedBox(
                                    height: 11,
                                  ),
                                  Text(
                                    (!isDriverAvailable)
                                        ? "FICAR ONLINE"
                                        : "FICAR OFFLINE",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      color: Color.fromRGBO(185, 150, 100, 1),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 21,
                                  ),
                                  Text(
                                    (!isDriverAvailable)
                                        ? "Você está prestes a ficar online, podendo receber notificação de novas corridas de usuários."
                                        : "Você está prestes a ficar offline, parando de receber notificações de novas corridas de usuários",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color.fromRGBO(185, 150, 100, 1),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 25,
                                  ),
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
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 16),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 16,
                                      ),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            if (!isDriverAvailable) {
                                              // Ficar online
                                              goOnlineNow();

                                              Navigator.pop(context);
                                            } else {
                                              // Ficar offline
                                              goOfflineNow();

                                              Navigator.pop(context);
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: (!isDriverAvailable)
                                                ? const Color.fromRGBO(
                                                30, 170, 70, 1)
                                                : const Color.fromRGBO(
                                                240, 75, 20, 1),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 16),
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
                        });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorToShow,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
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
