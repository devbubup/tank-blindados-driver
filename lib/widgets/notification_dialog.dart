import 'dart:async';
import 'package:drivers_app/global/global_var.dart';
import 'package:drivers_app/methods/common_methods.dart';
import 'package:drivers_app/models/trip_details.dart';
import 'package:drivers_app/pages/new_trip_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
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
  final LocalAuthentication auth = LocalAuthentication();

  DatabaseReference? tripStatusRef;
  StreamSubscription<DatabaseEvent>? tripStatusSubscription;

  @override
  void initState() {
    super.initState();
    print("NotificationDialog initState called");
    cancelNotificationDialogAfter20Sec();
    listenToTripStatus();
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

  void listenToTripStatus() {
    tripStatusRef = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child("newTripStatus");

    tripStatusSubscription = tripStatusRef!.onValue.listen((event) {
      if (event.snapshot.value == null) return;

      String tripStatus = event.snapshot.value.toString();

      print("Trip status in NotificationDialog: $tripStatus");

      if (tripStatus == "cancelled" || tripStatus == "cancelado") {
        print("Trip has been cancelled by the user.");
        if (mounted) {
          Navigator.pop(context); // Fechar o NotificationDialog
          audioPlayer.stop();
          showTripCancelledAlert(); // Mostrar o alerta de cancelamento
        }
      }
    });
  }

  void showTripCancelledAlert() {
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

  @override
  void dispose() {
    countdownTimer?.cancel();
    tripStatusSubscription?.cancel();
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
      cMethods.displaySnackBar("Solicitação de viagem não encontrada.", context);
    } else if (newTripStatusValue == widget.tripDetailsInfo!.tripID) {
      print("Trip request accepted");
      driverTripStatusRef.set("accepted");
      cMethods.turnOffLocationUpdatesForHomePage();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => NewTripPage(newTripDetailsInfo: widget.tripDetailsInfo)),
      );
    } else if (newTripStatusValue == "cancelled" || newTripStatusValue == "cancelado") {
      print("Trip request cancelled by user");
      cMethods.displaySnackBar("Solicitação de viagem foi cancelada pelo usuário.", context);
    } else if (newTripStatusValue == "timeout") {
      print("Trip request timed out");
      cMethods.displaySnackBar("Solicitação de viagem expirou.", context);
    } else {
      print("Trip request removed");
      cMethods.displaySnackBar("Solicitação de viagem removida. Não encontrada.", context);
    }
  }

  Future<bool> authenticate() async {
    try {
      return await auth.authenticate(
        localizedReason: 'Por favor, autentique-se para aceitar a viagem',
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      print(e);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: Colors.black87,
      child: Container(
        margin: const EdgeInsets.all(5),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20.0),
              Image.asset(
                "assets/images/uberexec.png",
                width: 120,
              ),
              const SizedBox(height: 16.0),
              const Text(
                "NOVA SOLICITAÇÃO DE CORRIDA",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20.0),
              const Divider(
                height: 1,
                color: Colors.grey,
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
                          height: 24,
                          width: 24,
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Text(
                            widget.tripDetailsInfo!.pickupAddress.toString(),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: const TextStyle(
                              color: Colors.white70,
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
                          height: 24,
                          width: 24,
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Text(
                            widget.tripDetailsInfo!.dropOffAddress.toString(),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: const TextStyle(
                              color: Colors.white70,
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
                color: Colors.grey,
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
                          // Atualizar status para "cancelled" no banco de dados
                          DatabaseReference driverRef = FirebaseDatabase.instance
                              .ref()
                              .child("drivers")
                              .child(FirebaseAuth.instance.currentUser!.uid)
                              .child("newTripStatus");
                          driverRef.set("cancelled");
                          Navigator.pop(context);
                          audioPlayer.stop();
                          print("Trip request declined by driver");
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          "RECUSAR",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          audioPlayer.stop();
                          bool isAuthenticated = await authenticate();
                          if (isAuthenticated) {
                            setState(() {
                              tripRequestStatus = "accepted";
                            });
                            checkAvailabilityOfTripRequest(context);
                            print("Trip request accepted button pressed");
                          } else {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) => AlertDialog(
                                backgroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                title: const Text(
                                  'Autenticação Falhou',
                                  style: TextStyle(color: Colors.white),
                                ),
                                content: const Text(
                                  'Falha na autenticação. Por favor, tente novamente.',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text(
                                      'OK',
                                      style: TextStyle(color: Colors.blue),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          "ACEITAR",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
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
      ),
    );
  }
}
