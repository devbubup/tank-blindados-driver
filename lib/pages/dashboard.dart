import 'package:drivers_app/pages/earnings_page.dart';
import 'package:drivers_app/pages/home_page.dart';
import 'package:drivers_app/pages/profile_page.dart';
import 'package:drivers_app/pages/trips_page.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with SingleTickerProviderStateMixin {
  TabController? controller;
  int indexSelected = 0;

  onBarItemClicked(int i) {
    setState(() {
      indexSelected = i;
      controller!.index = indexSelected;
    });
  }

  @override
  void initState() {
    super.initState();
    controller = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        physics: const NeverScrollableScrollPhysics(),
        controller: controller,
        children: const [
          HomePage(),
          EarningsPage(),
          TripsPage(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Início",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card),
            label: "Resultados",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_tree),
            label: "Viagens",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Perfil",
          ),
        ],
        currentIndex: indexSelected,
        unselectedItemColor: Color.fromRGBO(0, 40, 30, 1),
        selectedItemColor: Color.fromRGBO(30, 170, 70, 1),
        showSelectedLabels: true,
        selectedLabelStyle: const TextStyle(fontSize: 12),
        type: BottomNavigationBarType.fixed,
        onTap: onBarItemClicked,
        backgroundColor: Color.fromRGBO(255, 255, 255, 1), // Fundo do BottomNavigationBar branco
      ),
    );
  }
}
