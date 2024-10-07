import 'package:drivers_app/pages/trips_history_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class TripsPage extends StatefulWidget {
  const TripsPage({super.key});

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  String currentDriverTotalTripsCompleted = "0";
  List<Map<String, dynamic>> recentTrips = [];

  @override
  void initState() {
    super.initState();
    getCurrentDriverTotalNumberOfTripsCompleted();
  }

  getCurrentDriverTotalNumberOfTripsCompleted() async {
    try {
      DatabaseReference tripRequestsRef = FirebaseDatabase.instance.ref().child("tripRequests");

      final snap = await tripRequestsRef.once();

      if (snap.snapshot.value != null) {
        Map<dynamic, dynamic> allTripsMap = snap.snapshot.value as Map;
        List<Map<String, dynamic>> tripsCompletedByCurrentDriver = [];

        allTripsMap.forEach((key, value) {
          if (value["status"] != null && value["status"] == "ended" && value["driverID"] == FirebaseAuth.instance.currentUser!.uid) {
            tripsCompletedByCurrentDriver.add({
              "pickUpAddress": value["pickUpAddress"],
              "dropOffAddress": value["dropOffAddress"],
              "fareAmount": value["fareAmount"],
              "timestamp": value["timestamp"] ?? key, // Using the key as a fallback for timestamp
            });
          }
        });

        // Ordena as viagens mais recentes primeiro
        tripsCompletedByCurrentDriver.sort((a, b) => b["timestamp"].compareTo(a["timestamp"]));

        setState(() {
          currentDriverTotalTripsCompleted = tripsCompletedByCurrentDriver.length.toString();
          recentTrips = tripsCompletedByCurrentDriver.take(5).toList(); // Pega apenas as 5 últimas corridas
        });
      } else {
        setState(() {
          currentDriverTotalTripsCompleted = "0";
        });
      }
    } catch (e) {
      print("Error fetching trip data: $e");
      setState(() {
        currentDriverTotalTripsCompleted = "0";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Informações do Motorista",
          style: TextStyle(
            color: Color.fromRGBO(185, 150, 100, 1),
          ),
        ),
        backgroundColor: const Color.fromRGBO(0, 40, 30, 1),
        iconTheme: const IconThemeData(
          color: Color.fromRGBO(185, 150, 100, 1),
        ),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Total Trips
            Container(
              decoration: BoxDecoration(
                color: const Color.fromRGBO(0, 40, 30, 1),
                borderRadius: BorderRadius.circular(10),
              ),
              width: double.infinity,
              padding: const EdgeInsets.all(18.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    "Total de Viagens:",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    currentDriverTotalTripsCompleted,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Recent Trips
            const Text(
              "Últimas 5 Corridas:",
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: recentTrips.length,
                itemBuilder: (context, index) {
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
                              Expanded(
                                child: Text(
                                  "Partida: ${recentTrips[index]["pickUpAddress"].toString()}",
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "\$${recentTrips[index]["fareAmount"].toString()}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // dropoff
                          Text(
                            "Destino: ${recentTrips[index]["dropOffAddress"].toString()}",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // Check trip history button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(0, 40, 30, 1),
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const TripsHistoryPage()),
                );
              },
              child: const Text(
                "Ver Mais",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
