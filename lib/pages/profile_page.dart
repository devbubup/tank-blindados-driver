import 'package:drivers_app/authentication/login_screen.dart';
import 'package:drivers_app/global/global_var.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController nameTextEditingController = TextEditingController();
  TextEditingController phoneTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController carTextEditingController = TextEditingController();

  setDriverInfo() {
    setState(() {
      nameTextEditingController.text = driverName;
      phoneTextEditingController.text = driverPhone;
      emailTextEditingController.text = FirebaseAuth.instance.currentUser!.email.toString();
      carTextEditingController.text = '$carNumber - $carColor - $carModel';
    });
  }

  @override
  void initState() {
    super.initState();
    setDriverInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Perfil",
          style: TextStyle(
            color: Color.fromRGBO(185, 150, 100, 1),
          ),
        ),
        backgroundColor: const Color.fromRGBO(0, 40, 30, 1),
        iconTheme: const IconThemeData(
          color: Color.fromRGBO(185, 150, 100, 1),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Image
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey,
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: NetworkImage(driverPhoto),
                  ),
                  border: Border.all(
                    color: Colors.black,
                    width: 2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Driver name
              buildTextField(
                controller: nameTextEditingController,
                icon: Icons.person,
              ),
              // Driver phone
              buildTextField(
                controller: phoneTextEditingController,
                icon: Icons.phone_android_outlined,
              ),
              // Driver email
              buildTextField(
                controller: emailTextEditingController,
                icon: Icons.email,
              ),
              // Driver car info
              buildTextField(
                controller: carTextEditingController,
                icon: Icons.drive_eta_rounded,
              ),
              const SizedBox(height: 12),
              // Logout button
              ElevatedButton(
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const LoginScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(30, 170, 70, 1),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4), // Menos arredondado
                  ),
                ),
                child: const Text(
                  "Logout",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              // Delete account button
              ElevatedButton(
                onPressed: () {
                  showDeleteAccountDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(240, 75, 20, 1),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4), // Menos arredondado
                  ),
                ),
                child: const Text(
                  "Deletar Conta",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmação de Deleção"),
          content: const Text("Você tem certeza que deseja deletar sua conta? Essa ação não pode ser desfeita."),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Deletar"),
              onPressed: () async {
                Navigator.of(context).pop();
                await deleteAccount();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteAccount() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Delete user from Firebase Realtime Database
        DatabaseReference userRef = FirebaseDatabase.instance.ref().child('drivers').child(user.uid);
        await userRef.remove();

        // Delete user from Firebase Auth
        await user.delete();

        // Sign out and navigate to login screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (c) => const LoginScreen()),
              (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      print("Error deleting account: $e");
      // Handle the error accordingly
    }
  }

  Widget buildTextField({required TextEditingController controller, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 8),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        enabled: false,
        style: const TextStyle(fontSize: 16, color: Colors.black),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(4), // Menos arredondado
          ),
          prefixIcon: Icon(icon, color: Colors.black),
        ),
      ),
    );
  }
}
