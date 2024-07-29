import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class TripsHistoryPage extends StatefulWidget {
  const TripsHistoryPage({super.key});

  @override
  State<TripsHistoryPage> createState() => _TripsHistoryPageState();
}

class _TripsHistoryPageState extends State<TripsHistoryPage> {
  final completedTripRequestsOfCurrentDriver = FirebaseDatabase.instance.ref().child("tripRequests");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Histórico de Corridas',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      backgroundColor: Colors.black, // Fundo preto
      body: StreamBuilder(
        stream: completedTripRequestsOfCurrentDriver.onValue,
        builder: (BuildContext context, snapshotData) {
          if (snapshotData.hasError) {
            return const Center(
              child: Text(
                "Error Occurred.",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          if (!snapshotData.hasData) {
            return const Center(
              child: Text(
                "No record found.",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          Map dataTrips = snapshotData.data!.snapshot.value as Map;
          List tripsList = [];
          dataTrips.forEach((key, value) => tripsList.add({"key": key, ...value}));

          return ListView.builder(
            shrinkWrap: true,
            itemCount: tripsList.length,
            itemBuilder: ((context, index) {
              if (tripsList[index]["status"] != null &&
                  tripsList[index]["status"] == "ended" &&
                  tripsList[index]["driverID"] == FirebaseAuth.instance.currentUser!.uid) {
                return Card(
                  color: Colors.white, // Card branco
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4), // Menos arredondado
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // pickup - fare amount
                        Row(
                          children: [
                            Image.asset('assets/images/initial.png', height: 16, width: 16),

                            const SizedBox(width: 18),

                            Expanded(
                              child: Text(
                                tripsList[index]["pickUpAddress"].toString(),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                            ),

                            const SizedBox(width: 5),

                            Text(
                              "\$ " + tripsList[index]["fareAmount"].toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // dropoff
                        Row(
                          children: [
                            Image.asset('assets/images/final.png', height: 16, width: 16),

                            const SizedBox(width: 18),

                            Expanded(
                              child: Text(
                                tripsList[index]["dropOffAddress"].toString(),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return Container();
              }
            }),
          );
        },
      ),
    );
  }
}
