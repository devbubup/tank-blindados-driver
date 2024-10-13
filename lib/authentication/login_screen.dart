import 'package:drivers_app/authentication/signup_screen.dart';
import 'package:drivers_app/pages/dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../methods/common_methods.dart';
import '../widgets/loading_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();
  CommonMethods cMethods = CommonMethods();

  @override
  void dispose() {
    emailTextEditingController.dispose();
    passwordTextEditingController.dispose();
    super.dispose();
  }

  checkIfNetworkIsAvailable() {
    signInFormValidation();
  }

  void _forgotPassword(BuildContext context) async {
    String email = "";
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        title: const Text(
          "Redefinir Senha",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00281E),
          ),
        ),
        content: TextField(
          onChanged: (value) {
            email = value;
          },
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: "Digite seu email",
            labelStyle: TextStyle(
              fontSize: 16,
              color: Color(0xFFB99664),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFB99664)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF00281E)),
            ),
          ),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            child: const Text(
              "Cancelar",
              style: TextStyle(
                color: Color(0xFF00281E),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text(
              "Enviar",
              style: TextStyle(
                color: Color(0xFFB99664),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              if (email.isNotEmpty && email.contains("@")) {
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                  cMethods.displaySnackBar("Link de redefinição de senha enviado para $email.", context);
                } catch (e) {
                  cMethods.displaySnackBar("Erro: Não foi possível enviar o link para o email.", context);
                }
              } else {
                cMethods.displaySnackBar("Insira um email válido.", context);
              }
            },
          ),
        ],
      ),
    );
  }

  signInFormValidation() {
    final String email = emailTextEditingController.text.trim();
    final String password = passwordTextEditingController.text.trim();

    final RegExp emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');

        if (email.isEmpty || !emailRegExp.hasMatch(email)) {
    cMethods.displaySnackBar("Insira um email válido.", context);
    } else if (password.length < 6) {
    cMethods.displaySnackBar("Sua senha deve ter pelo menos 6 caracteres.", context);
    } else if (password.length > 20) {
    cMethods.displaySnackBar("Sua senha deve ter no máximo 20 caracteres.", context);
    } else {
    signInUser();
    }
  }

  signInUser() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => LoadingDialog(messageText: "Realizando seu login..."),
    );

    try {
      final User? userFirebase = (await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailTextEditingController.text.trim(),
        password: passwordTextEditingController.text.trim(),
      )).user;

      if (!context.mounted) return;
      Navigator.pop(context);

      if (userFirebase != null) {
        DatabaseReference usersRef = FirebaseDatabase.instance.ref().child("drivers").child(userFirebase.uid);
        usersRef.once().then((snap) {
          if (snap.snapshot.value != null) {
            if ((snap.snapshot.value as Map)["blockStatus"] == "no") {
              Navigator.push(context, MaterialPageRoute(builder: (c) => const Dashboard()));
            } else {
              FirebaseAuth.instance.signOut();
              cMethods.displaySnackBar("Sua conta foi bloqueada. Para mais informações, entre em contato com email@gmail.com", context);
            }
          } else {
            FirebaseAuth.instance.signOut();
            cMethods.displaySnackBar("Sua conta de motorista não existe.", context);
          }
        });
      }
    } catch (errorMsg) {
      Navigator.pop(context);
      cMethods.displaySnackBar("Erro: $errorMsg", context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 60),
              Center(
                child: Image.asset(
                  "assets/images/logo.png",
                  height: 200,
                  width: 220,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "Login de Motorista",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00281E),
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: emailTextEditingController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email",
                  labelStyle: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFB99664),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFB99664)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00281E)),
                  ),
                ),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: passwordTextEditingController,
                obscureText: true,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: "Senha",
                  labelStyle: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFB99664),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFB99664)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00281E)),
                  ),
                ),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: GestureDetector(
                  onTap: () => _forgotPassword(context),
                  child: const Text(
                    "Esqueceu a senha?",
                    style: TextStyle(
                      color: Color(0xFF00281E),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 85),
              ElevatedButton(
                onPressed: checkIfNetworkIsAvailable,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00281E),
                  padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Login",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (c) => const SignUpScreen()));
                  },
                  child: const Text(
                    "Não tem uma conta? Registre aqui!",
                    style: TextStyle(
                      color: Color(0xFF00281E),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
