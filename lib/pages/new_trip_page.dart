import 'dart:async';
import 'package:drivers_app/methods/common_methods.dart';
import 'package:drivers_app/models/trip_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../global/global_var.dart';
import '../widgets/loading_dialog.dart';
import '../widgets/payment_dialog.dart';

class NewTripPage extends StatefulWidget {
  final TripDetails? newTripDetailsInfo;

  NewTripPage({super.key, this.newTripDetailsInfo});

  @override
  State<NewTripPage> createState() => _NewTripPageState();
}

class _NewTripPageState extends State<NewTripPage> {
  final Completer<GoogleMapController> googleMapCompleterController = Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;
  double googleMapPaddingFromBottom = 0;
  List<LatLng> coordinatesPolylineLatLngList = [];
  PolylinePoints polylinePoints = PolylinePoints();
  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};
  Set<Polyline> polyLinesSet = {};
  BitmapDescriptor? carMarkerIcon;
  bool directionRequested = false;
  String statusOfTrip = "accepted";
  String durationText = "", distanceText = "";
  String buttonTitleText = "CHEGOU";
  Color buttonColor = const Color.fromRGBO(0, 40, 30, 1); // Cor inicial do botão
  CommonMethods cMethods = CommonMethods();
  double? initialFareAmount;

  makeMarker() {
    if (carMarkerIcon == null) {
      ImageConfiguration configuration = createLocalImageConfiguration(context, size: const Size(2, 2));

      BitmapDescriptor.fromAssetImage(configuration, "assets/images/tracking.png").then((valueIcon) {
        carMarkerIcon = valueIcon;
      });
    }
  }

  obtainDirectionAndDrawRoute(sourceLocationLatLng, destinationLocationLatLng) async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => LoadingDialog(
        messageText: 'Please wait...',
      ),
    );

    var tripDetailsInfo = await CommonMethods.getDirectionDetailsFromAPI(sourceLocationLatLng, destinationLocationLatLng);

    Navigator.pop(context);

    PolylinePoints pointsPolyline = PolylinePoints();
    List<PointLatLng> latLngPoints = pointsPolyline.decodePolyline(tripDetailsInfo!.encodedPoints!);

    coordinatesPolylineLatLngList.clear();

    if (latLngPoints.isNotEmpty) {
      for (var pointLatLng in latLngPoints) {
        coordinatesPolylineLatLngList.add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      }
    }

    //draw polyline
    polyLinesSet.clear();

    setState(() {
      Polyline polyline = Polyline(
        polylineId: const PolylineId("routeID"),
        color: const Color.fromRGBO(185, 150, 100, 1), // Usando a cor bege
        points: coordinatesPolylineLatLngList,
        jointType: JointType.round,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      polyLinesSet.add(polyline);
    });

    //fit the polyline on google map
    LatLngBounds boundsLatLng;

    if (sourceLocationLatLng.latitude > destinationLocationLatLng.latitude &&
        sourceLocationLatLng.longitude > destinationLocationLatLng.longitude) {
      boundsLatLng = LatLngBounds(
        southwest: destinationLocationLatLng,
        northeast: sourceLocationLatLng,
      );
    } else if (sourceLocationLatLng.longitude > destinationLocationLatLng.longitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(sourceLocationLatLng.latitude, destinationLocationLatLng.longitude),
        northeast: LatLng(destinationLocationLatLng.latitude, sourceLocationLatLng.longitude),
      );
    } else if (sourceLocationLatLng.latitude > destinationLocationLatLng.latitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(destinationLocationLatLng.latitude, sourceLocationLatLng.longitude),
        northeast: LatLng(sourceLocationLatLng.latitude, destinationLocationLatLng.longitude),
      );
    } else {
      boundsLatLng = LatLngBounds(
        southwest: sourceLocationLatLng,
        northeast: destinationLocationLatLng,
      );
    }

    controllerGoogleMap!.animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 72));

    //add marker
    Marker sourceMarker = Marker(
      markerId: const MarkerId('sourceID'),
      position: sourceLocationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );

    Marker destinationMarker = Marker(
      markerId: const MarkerId('destinationID'),
      position: destinationLocationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    );

    setState(() {
      markersSet.add(sourceMarker);
      markersSet.add(destinationMarker);
    });

    //add circle
    Circle sourceCircle = Circle(
      circleId: const CircleId('sourceCircleID'),
      strokeColor: const Color.fromRGBO(185, 150, 100, 1), // Cor bege
      strokeWidth: 4,
      radius: 14,
      center: sourceLocationLatLng,
      fillColor: const Color.fromRGBO(0, 40, 30, 0.7), // Fundo semi-transparente
    );

    Circle destinationCircle = Circle(
      circleId: const CircleId('destinationCircleID'),
      strokeColor: const Color.fromRGBO(185, 150, 100, 1), // Cor bege
      strokeWidth: 4,
      radius: 14,
      center: destinationLocationLatLng,
      fillColor: const Color.fromRGBO(0, 40, 30, 0.7), // Fundo semi-transparente
    );

    setState(() {
      circlesSet.add(sourceCircle);
      circlesSet.add(destinationCircle);
    });
  }

  getLiveLocationUpdatesOfDriver() {
    LatLng lastPositionLatLng = const LatLng(0, 0);

    positionStreamNewTripPage = Geolocator.getPositionStream().listen((Position positionDriver) {
      driverCurrentPosition = positionDriver;

      LatLng driverCurrentPositionLatLng = LatLng(driverCurrentPosition!.latitude, driverCurrentPosition!.longitude);

      Marker carMarker = Marker(
        markerId: const MarkerId("carMarkerID"),
        position: driverCurrentPositionLatLng,
        icon: carMarkerIcon!,
        infoWindow: const InfoWindow(title: "My Location"),
      );

      setState(() {
        CameraPosition cameraPosition = CameraPosition(target: driverCurrentPositionLatLng, zoom: 16);
        controllerGoogleMap!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

        markersSet.removeWhere((element) => element.markerId.value == "carMarkerID");
        markersSet.add(carMarker);
      });

      lastPositionLatLng = driverCurrentPositionLatLng;

      //update Trip Details Information
      updateTripDetailsInformation();

      //update driver location to tripRequest
      Map updatedLocationOfDriver = {
        "latitude": driverCurrentPosition!.latitude,
        "longitude": driverCurrentPosition!.longitude,
      };
      FirebaseDatabase.instance.ref().child("tripRequests").child(widget.newTripDetailsInfo!.tripID!).child("driverLocation").set(updatedLocationOfDriver);
    });
  }

  updateTripDetailsInformation() async {
    if (!directionRequested) {
      directionRequested = true;

      if (driverCurrentPosition == null) {
        return;
      }

      var driverLocationLatLng = LatLng(driverCurrentPosition!.latitude, driverCurrentPosition!.longitude);

      LatLng dropOffDestinationLocationLatLng;
      if (statusOfTrip == "accepted") {
        dropOffDestinationLocationLatLng = widget.newTripDetailsInfo!.pickUpLatLng!;
      } else {
        dropOffDestinationLocationLatLng = widget.newTripDetailsInfo!.dropOffLatLng!;
      }

      var directionDetailsInfo = await CommonMethods.getDirectionDetailsFromAPI(driverLocationLatLng, dropOffDestinationLocationLatLng);

      if (directionDetailsInfo != null) {
        directionRequested = false;

        setState(() {
          durationText = directionDetailsInfo.durationTextString!;
          distanceText = directionDetailsInfo.distanceTextString!;
        });
      }
    }
  }

  void endTripNow() async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => LoadingDialog(
        messageText: 'Aguarde..',
      ),
    );

    var driverCurrentLocationLatLng = LatLng(driverCurrentPosition!.latitude, driverCurrentPosition!.longitude);

    var directionDetailsStartTripInfo = await CommonMethods.getDirectionDetailsFromAPI(
      driverCurrentLocationLatLng, //pickup
      widget.newTripDetailsInfo!.dropOffLatLng!, //destination
    );

    if (directionDetailsStartTripInfo != null) {
      initialFareAmount = await cMethods.calculateFareAmount(directionDetailsStartTripInfo);
    }

    await FirebaseDatabase.instance.ref().child("tripRequests").child(widget.newTripDetailsInfo!.tripID!).child("fareAmount").set(initialFareAmount.toString());

    await FirebaseDatabase.instance.ref().child("tripRequests").child(widget.newTripDetailsInfo!.tripID!).child("status").set("ended");

    positionStreamNewTripPage!.cancel();

    Navigator.pop(context);

    //dialog for collecting fare amount
    displayPaymentDialog(initialFareAmount!);

    //save fare amount to driver total earnings
    saveFareAmountToDriverTotalEarnings(initialFareAmount!);
  }

  void displayPaymentDialog(double fareAmount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => PaymentDialog(fareAmount: fareAmount.toStringAsFixed(2)),
    );
  }

  void saveFareAmountToDriverTotalEarnings(double fareAmount) async {
    DatabaseReference driverEarningsRef = FirebaseDatabase.instance.ref().child("drivers").child(FirebaseAuth.instance.currentUser!.uid).child("earnings");

    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    await driverEarningsRef.child(timestamp).set({
      'amount': fareAmount,
      'timestamp': timestamp,
    }).catchError((error) {
      print("Failed to update earnings: $error");
    });
  }

  saveDriverDataToTripInfo() async {
    Map<String, dynamic> driverDataMap = {
      "status": "accepted",
      "driverID": FirebaseAuth.instance.currentUser!.uid,
      "driverName": driverName,
      "driverPhone": driverPhone,
      "driverPhoto": driverPhoto,
      "carDetails": "$carColor - $carModel - $carNumber",
    };

    Map<String, dynamic> driverCurrentLocation = {
      'latitude': driverCurrentPosition!.latitude.toString(),
      'longitude': driverCurrentPosition!.longitude.toString(),
    };

    await FirebaseDatabase.instance.ref().child("tripRequests").child(widget.newTripDetailsInfo!.tripID!).update(driverDataMap);

    await FirebaseDatabase.instance.ref().child("tripRequests").child(widget.newTripDetailsInfo!.tripID!).child("driverLocation").update(driverCurrentLocation);
  }

  @override
  void initState() {
    super.initState();
    saveDriverDataToTripInfo();
  }

  @override
  void dispose() {
    positionStreamNewTripPage?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    makeMarker();

    return Scaffold(
      body: Stack(
        children: [
          ///google map
          GoogleMap(
            padding: EdgeInsets.only(bottom: googleMapPaddingFromBottom),
            mapType: MapType.normal,
            myLocationEnabled: true,
            markers: markersSet,
            circles: circlesSet,
            polylines: polyLinesSet,
            initialCameraPosition: googlePlexInitialPosition,
            onMapCreated: (GoogleMapController mapController) async {
              controllerGoogleMap = mapController;
              googleMapCompleterController.complete(controllerGoogleMap);

              setState(() {
                googleMapPaddingFromBottom = 262;
              });

              var driverCurrentLocationLatLng = LatLng(driverCurrentPosition!.latitude, driverCurrentPosition!.longitude);

              var userPickUpLocationLatLng = widget.newTripDetailsInfo!.pickUpLatLng;

              await obtainDirectionAndDrawRoute(driverCurrentLocationLatLng, userPickUpLocationLatLng);

              getLiveLocationUpdatesOfDriver();
            },
          ),

          if (statusOfTrip == "ontrip") ...[
            Positioned(
              bottom: 310,
              left: 10,
              child: FloatingActionButton.extended(
                onPressed: () async {
                  if (widget.newTripDetailsInfo!.dropOffLatLng != null && driverCurrentPosition != null) {
                    final url = Uri.parse("https://www.google.com/maps/dir/?api=1&origin=${driverCurrentPosition!.latitude},${driverCurrentPosition!.longitude}&destination=${widget.newTripDetailsInfo!.dropOffLatLng!.latitude},${widget.newTripDetailsInfo!.dropOffLatLng!.longitude}&travelmode=driving");
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    } else {
                      throw 'Could not launch $url';
                    }
                  }
                },
                label: const Text("Abrir com Google Maps"),
                icon: const Icon(Icons.directions),
                backgroundColor: const Color.fromRGBO(0, 40, 30, 1), // Cor verde
              ),
            ),
          ],

          ///trip details
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromRGBO(0, 40, 30, 0.9), // Fundo semi-transparente
                borderRadius: const BorderRadius.only(topRight: Radius.circular(17), topLeft: Radius.circular(17)),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 17,
                    spreadRadius: 0.5,
                    offset: Offset(0.7, 0.7),
                  ),
                ],
              ),
              height: 300,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //trip duration
                    Center(
                      child: Text(
                        durationText + " - " + distanceText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 5,),

                    //user name - call user icon btn
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        //user name
                        Text(
                          widget.newTripDetailsInfo!.userName!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        //call user icon btn
                        GestureDetector(
                          onTap: () {
                            launchUrl(
                              Uri.parse(
                                  "tel://${widget.newTripDetailsInfo!.userPhone}"
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(right: 10),
                            child: Icon(
                              Icons.phone_android_outlined,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15,),

                    //pickup icon and location
                    Row(
                      children: [
                        Image.asset(
                          "assets/images/initial.png",
                          height: 16,
                          width: 16,
                        ),

                        Expanded(
                          child: Text(
                            widget.newTripDetailsInfo!.pickupAddress.toString(),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15,),

                    //dropoff icon and location
                    Row(
                      children: [
                        Image.asset(
                          "assets/images/final.png",
                          height: 16,
                          width: 16,
                        ),

                        Expanded(
                          child: Text(
                            widget.newTripDetailsInfo!.dropOffAddress.toString(),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25,),

                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          //arrived button
                          if (statusOfTrip == "accepted") {
                            setState(() {
                              buttonTitleText = "INICIAR";
                              buttonColor = const Color.fromRGBO(0, 40, 30, 1); // Cor verde
                            });

                            statusOfTrip = "arrived";

                            FirebaseDatabase.instance.ref().child("tripRequests").child(widget.newTripDetailsInfo!.tripID!).child("status").set("arrived");

                            showDialog(
                              barrierDismissible: false,
                              context: context,
                              builder: (BuildContext context) => LoadingDialog(messageText: 'Aguarde...',),
                            );

                            await obtainDirectionAndDrawRoute(
                              widget.newTripDetailsInfo!.pickUpLatLng,
                              widget.newTripDetailsInfo!.dropOffLatLng,
                            );

                            Navigator.pop(context);
                          }
                          //start trip button
                          else if (statusOfTrip == "arrived") {
                            setState(() {
                              buttonTitleText = "FINALIZAR";
                              buttonColor = const Color.fromRGBO(185, 150, 100, 1); // Cor âmbar
                            });

                            statusOfTrip = "ontrip";

                            FirebaseDatabase.instance.ref().child("tripRequests").child(widget.newTripDetailsInfo!.tripID!).child("status").set("ontrip");
                          }
                          //end trip button
                          else if (statusOfTrip == "ontrip") {
                            //end the trip
                            endTripNow();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                        ),
                        child: Text(
                          buttonTitleText,
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
