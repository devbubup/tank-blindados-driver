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

  @override
  void initState() {
    super.initState();
    getTotalEarningsOfCurrentDriver();
  }

  getTotalEarningsOfCurrentDriver() async {
    DatabaseReference driverEarningsRef = FirebaseDatabase.instance.ref()
        .child("drivers")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child("earnings");

    driverEarningsRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        Map earningsMap = event.snapshot.value as Map;

        DateTime now = DateTime.now();
        DateTime currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
        DateTime fiveWeeksAgo = currentWeekStart.subtract(Duration(days: 35));

        Map<int, double> weeklyEarnings = {
          for (var i = 0; i < 6; i++) i: 0.0,
        };

        earningsMap.forEach((key, value) {
          double amount = value['amount'];
          DateTime earningDate = DateTime.fromMillisecondsSinceEpoch(int.parse(key));
          if (earningDate.isAfter(fiveWeeksAgo)) {
            int weekNumber = ((currentWeekStart.difference(earningDate).inDays) / 7).floor();
            if (weekNumber < 6) {
              weeklyEarnings[weekNumber] = weeklyEarnings[weekNumber]! + amount;
            }
          }
        });

        setState(() {
          currentWeekEarnings = weeklyEarnings[0]!;
          lastFiveWeeksEarnings = List.generate(5, (index) => weeklyEarnings[index + 1]!);
          weekDates = List.generate(6, (index) {
            DateTime weekStart = currentWeekStart.subtract(Duration(days: index * 7));
            DateTime weekEnd = weekStart.add(Duration(days: 6));
            return "${weekStart.day}/${weekStart.month} - ${weekEnd.day}/${weekEnd.month}";
          });

          lineChartData = List.generate(6, (index) {
            return FlSpot(index.toDouble(), weeklyEarnings[index]!);
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double maxYValue = (lineChartData.map((spot) => spot.y).reduce((a, b) => a > b ? a : b).ceilToDouble() + 10).ceilToDouble();
    maxYValue = maxYValue % 10 == 0 ? maxYValue : (maxYValue + (10 - maxYValue % 10)).ceilToDouble();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Ganhos"),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.indigo,
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
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 150, // Aumentar a altura dos boxes
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: lastFiveWeeksEarnings.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 250, // Aumentar a largura dos boxes
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.indigo,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
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
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "\$${lastFiveWeeksEarnings[index].toStringAsFixed(2)}",
                              style: TextStyle(
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
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.indigo,
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
                                style: TextStyle(color: Colors.white, fontSize: 12),
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
                                  offset: Offset(0, 15), // Mover a legenda para baixo
                                  child: Transform.rotate(
                                    angle: -0.7854,
                                    child: Text(
                                      weekDates[weekIndex],
                                      style: TextStyle(color: Colors.white, fontSize: 12),
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
                        color: Colors.blue,
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.blue.withOpacity(0.3),
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
          ),
        ),
      ),
    );
  }
}

class WeeklyEarnings {
  final String week;
  final double amount;

  WeeklyEarnings(this.week, this.amount);
}
