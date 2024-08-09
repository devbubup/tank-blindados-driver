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
            color: Color.fromRGBO(185, 150, 100, 1),
          ),
        ),
        backgroundColor: const Color.fromRGBO(0, 40, 30, 1),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: Color.fromRGBO(185, 150, 100, 1)),
        ),
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder(
        stream: completedTripRequestsOfCurrentDriver.orderByChild("timestamp").onValue,
        builder: (BuildContext context, snapshotData) {
          if (snapshotData.hasError) {
            return const Center(
              child: Text(
                "Error Occurred.",
                style: TextStyle(color: Colors.black),
              ),
            );
          }

          if (!snapshotData.hasData || snapshotData.data!.snapshot.value == null) {
            return const Center(
              child: Text(
                "No record found.",
                style: TextStyle(color: Colors.black),
              ),
            );
          }

          Map dataTrips = snapshotData.data!.snapshot.value as Map;
          List<Map<String, dynamic>> tripsList = [];

          dataTrips.forEach((key, value) {
            if (value["status"] == "ended" &&
                value["driverID"] == FirebaseAuth.instance.currentUser!.uid) {
              // Verifique se o timestamp é nulo e forneça um valor padrão, como 0
              int timestamp = value["timestamp"] ?? 0;
              tripsList.add({"key": key, "timestamp": timestamp, ...value});
            }
          });

          // Ordena as corridas do mais recente para o mais antigo
          tripsList.sort((a, b) => b["timestamp"].compareTo(a["timestamp"]));

          return ListView.builder(
            shrinkWrap: true,
            itemCount: tripsList.length,
            itemBuilder: ((context, index) {
              return Card(
                color: const Color.fromRGBO(0, 40, 30, 1),
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // pickup - fare amount
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.green),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Text(
                              tripsList[index]["pickUpAddress"].toString(),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "\$ " + tripsList[index]["fareAmount"].toString(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.greenAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // dropoff
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.red),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Text(
                              tripsList[index]["dropOffAddress"].toString(),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
