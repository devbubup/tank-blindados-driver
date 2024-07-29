import 'dart:async';
import 'package:drivers_app/global/global_var.dart';
import 'package:drivers_app/methods/common_methods.dart';
import 'package:drivers_app/models/trip_details.dart';
import 'package:drivers_app/pages/new_trip_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'loading_dialog.dart';

class NotificationDialog extends StatefulWidget {
  final TripDetails? tripDetailsInfo;

  const NotificationDialog({super.key, this.tripDetailsInfo});

  @override
  State<NotificationDialog> createState() => _NotificationDialogState();
}

class _NotificationDialogState extends State<NotificationDialog> {
  String tripRequestStatus = "";
  CommonMethods cMethods = CommonMethods();
  Timer? countdownTimer;

  @override
  void initState() {
    super.initState();
    print("NotificationDialog initState called");
    cancelNotificationDialogAfter20Sec();
  }

  void cancelNotificationDialogAfter20Sec() {
    const duration = Duration(seconds: 1);

    countdownTimer = Timer.periodic(duration, (timer) {
      if (!mounted) return;

      setState(() {
        driverTripRequestTimeout--;
      });

      if (tripRequestStatus == "accepted" || driverTripRequestTimeout == 0) {
        timer.cancel();
        if (driverTripRequestTimeout == 0 && mounted) {
          Navigator.pop(context);
          audioPlayer.stop();
        }
        setState(() {
          driverTripRequestTimeout = 20;
        });
      }
    });
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
    print("NotificationDialog disposed");
  }

  Future<void> checkAvailabilityOfTripRequest(BuildContext context) async {
    if (!mounted) return;

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => LoadingDialog(messageText: 'Aguarde...'),
    );

    DatabaseReference driverTripStatusRef = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child("newTripStatus");

    final snap = await driverTripStatusRef.once();

    if (!mounted) return;

    Navigator.pop(context);
    print("Loading dialog dismissed");

    String newTripStatusValue = snap.snapshot.value?.toString() ?? "";

    if (newTripStatusValue.isEmpty) {
      print("Trip request not found");
      cMethods.displaySnackBar("Trip Request Not Found.", context);
    } else if (newTripStatusValue == widget.tripDetailsInfo!.tripID) {
      print("Trip request accepted");
      driverTripStatusRef.set("accepted");
      cMethods.turnOffLocationUpdatesForHomePage();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => NewTripPage(newTripDetailsInfo: widget.tripDetailsInfo)),
      );
    } else if (newTripStatusValue == "cancelled") {
      print("Trip request cancelled by user");
      cMethods.displaySnackBar("Trip Request has been Cancelled by user.", context);
    } else if (newTripStatusValue == "timeout") {
      print("Trip request timed out");
      cMethods.displaySnackBar("Trip Request timed out.", context);
    } else {
      print("Trip request removed");
      cMethods.displaySnackBar("Trip Request removed. Not Found.", context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: Colors.black54,
      child: Container(
        margin: const EdgeInsets.all(5),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 30.0),
            Image.asset(
              "assets/images/uberexec.png",
              width: 140,
            ),
            const SizedBox(height: 16.0),
            const Text(
              "NOVA PROPOSTA DE CORRIDA",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20.0),
            const Divider(
              height: 1,
              color: Colors.white,
              thickness: 1,
            ),
            const SizedBox(height: 10.0),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        "assets/images/initial.png",
                        height: 16,
                        width: 16,
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Text(
                          widget.tripDetailsInfo!.pickupAddress.toString(),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        "assets/images/final.png",
                        height: 16,
                        width: 16,
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Text(
                          widget.tripDetailsInfo!.dropOffAddress.toString(),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(
              height: 1,
              color: Colors.white,
              thickness: 1,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        audioPlayer.stop();
                        print("Trip request declined");
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                      ),
                      child: const Text(
                        "RECUSAR",
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        audioPlayer.stop();
                        setState(() {
                          tripRequestStatus = "accepted";
                        });
                        checkAvailabilityOfTripRequest(context);
                        print("Trip request accepted button pressed");
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text(
                        "ACEITAR",
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10.0),
          ],
        ),
      ),
    );
  }
}
