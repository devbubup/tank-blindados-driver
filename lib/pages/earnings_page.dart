import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class EarningsPage extends StatefulWidget {
  const EarningsPage({super.key});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  double currentWeekEarnings = 0.0;
  List<double> lastFiveWeeksEarnings = List.filled(5, 0.0);
  List<FlSpot> lineChartData = [];
  List<String> weekDates = [];
  bool hasEarningsData = false;

  @override
  void initState() {
    super.initState();
    getTotalEarningsOfCurrentDriver();
  }

  Future<void> getTotalEarningsOfCurrentDriver() async {
    DatabaseReference driverEarningsRef = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child("earnings");

    driverEarningsRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        print("Earnings data received: ${event.snapshot.value}");

        Map earningsMap = event.snapshot.value as Map;

        DateTime now = DateTime.now();
        DateTime currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
        DateTime fiveWeeksAgo = currentWeekStart.subtract(Duration(days: 35));

        Map<int, double> weeklyEarnings = {
          for (var i = 0; i < 6; i++) i: 0.0,
        };

        earningsMap.forEach((key, value) {
          if (value != null) {
            double? amount;
            DateTime? earningDate;

            try {
              amount = value['amount'] != null
                  ? double.tryParse(value['amount'].toString())
                  : null;
              earningDate = value['timestamp'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(int.tryParse(value['timestamp'].toString()) ?? 0)
                  : null;

              if (amount != null && earningDate != null) {
                if (earningDate.isAfter(fiveWeeksAgo) || earningDate.isAtSameMomentAs(currentWeekStart)) {
                  int weekNumber = ((currentWeekStart.difference(earningDate).inDays) / 7).floor();

                  if (weekNumber >= 0 && weekNumber < 6) {
                    weeklyEarnings[weekNumber] =
                        (weeklyEarnings[weekNumber] ?? 0.0) + amount;
                  }
                }
              }
            } catch (e) {
              print("Error processing earnings data: $e");
            }
          }
        });

        print("Weekly earnings computed: $weeklyEarnings");

        setState(() {
          currentWeekEarnings = weeklyEarnings[0] ?? 0.0;
          lastFiveWeeksEarnings =
              List.generate(5, (index) => weeklyEarnings[index + 1] ?? 0.0);
          weekDates = List.generate(6, (index) {
            DateTime weekStart = currentWeekStart.subtract(Duration(days: (index) * 7));
            DateTime weekEnd = weekStart.add(Duration(days: 6));
            return "${weekStart.day}/${weekStart.month} - ${weekEnd.day}/${weekEnd.month}";
          });

          lineChartData = List.generate(6, (index) {
            return FlSpot(index.toDouble(), weeklyEarnings[index] ?? 0.0);
          });

          hasEarningsData = true;
        });
      } else {
        print("No earnings data found.");
        setState(() {
          hasEarningsData = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double maxYValue = (lineChartData.isNotEmpty
        ? lineChartData
        .map((spot) => spot.y)
        .reduce((a, b) => a > b ? a : b)
        .ceilToDouble() +
        10
        : 10)
        .ceilToDouble();
    maxYValue = maxYValue % 10 == 0
        ? maxYValue
        : (maxYValue + (10 - maxYValue % 10)).ceilToDouble();

    return Scaffold(
      backgroundColor: const Color.fromRGBO(255, 255, 255, 1),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Ganhos",
          style: TextStyle(
            color: Color.fromRGBO(185, 150, 100, 1),
          ),
        ),
        backgroundColor: const Color.fromRGBO(0, 40, 30, 1),
        iconTheme: const IconThemeData(
          color: Color.fromRGBO(185, 150, 100, 1),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: hasEarningsData
              ? Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
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
                      "Ganhos desta Semana:",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "\$ ${currentWeekEarnings.toStringAsFixed(2)}",
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
              const Text(
                "Ganhos das Últimas 5 Semanas:",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: lastFiveWeeksEarnings.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 250,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(0, 40, 30, 1),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 5,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Semana ${weekDates[index + 1]}:",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "\$${lastFiveWeeksEarnings[index].toStringAsFixed(2)}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
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
              const Text(
                "Gráfico de Ganhos (Últimas 6 Semanas):",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(0, 40, 30, 1),
                  borderRadius: BorderRadius.circular(10),
                ),
                width: double.infinity,
                height: 400,
                padding: const EdgeInsets.all(18.0),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (value, meta) {
                            if (value % 10 == 0) {
                              return Text(
                                value.toStringAsFixed(0),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              );
                            }
                            return Container();
                          },
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 80,
                          getTitlesWidget: (value, meta) {
                            final weekIndex = value.toInt();
                            if (weekIndex >= 0 && weekIndex < 6) {
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 15,
                                child: Transform.translate(
                                  offset: const Offset(0, 15),
                                  child: Transform.rotate(
                                    angle: -0.7854,
                                    child: Text(
                                      weekDates[weekIndex],
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return Text('');
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: lineChartData,
                        isCurved: false,
                        color: const Color.fromRGBO(185, 150, 100, 1),
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color.fromRGBO(185, 150, 100, 1)
                              .withOpacity(0.3),
                        ),
                      ),
                    ],
                    minY: 0,
                    maxY: maxYValue,
                    lineTouchData: LineTouchData(enabled: false),
                  ),
                ),
              ),
            ],
          )
              : const Center(
            child: Text(
              "Nenhum dado de ganho disponível",
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
