import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../methods/common_methods.dart';
import '../pages/dashboard.dart';
import '../pages/home_page.dart';
import '../widgets/loading_dialog.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController userNameTextEditingController = TextEditingController();
  TextEditingController userPhoneTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();
  TextEditingController cpfPassportTextEditingController = TextEditingController();
  TextEditingController vehicleNumberTextEditingController = TextEditingController();
  TextEditingController renavamTextEditingController = TextEditingController();
  TextEditingController pixKeyTextEditingController = TextEditingController();
  TextEditingController bankNameTextEditingController = TextEditingController();
  TextEditingController bankAgencyTextEditingController = TextEditingController();
  TextEditingController bankAccountNumberTextEditingController = TextEditingController();

  CommonMethods cMethods = CommonMethods();
  XFile? imageFile;
  String urlOfUploadedImage = "";
  bool isForeignUser = false;

  Map<String, XFile?> carImages = {
    'frente': null,
    'traseira': null,
    'lateral_direita': null,
    'lateral_esquerda': null,
    'chassi': null,
    'pneu_dianteiro_direito': null,
    'pneu_dianteiro_esquerdo': null,
    'pneu_traseiro_direito': null,
    'pneu_traseiro_esquerdo': null,
  };

  Map<String, String> carImagesUrls = {
    'frente': '',
    'traseira': '',
    'lateral_direita': '',
    'lateral_esquerda': '',
    'chassi': '',
    'pneu_dianteiro_direito': '',
    'pneu_dianteiro_esquerdo': '',
    'pneu_traseiro_direito': '',
    'pneu_traseiro_esquerdo': '',
  };

  Map<String, File?> documentFiles = {
    'negativa_antecedentes_federal': null,
    'negativa_antecedentes_estadual': null,
    'negativa_antecedentes_militar': null,
    'cnh': null,
    'rg': null,
    'toxicologico': null,
    'renavam': null,
  };

  Map<String, String> documentFilesUrls = {
    'negativa_antecedentes_federal': '',
    'negativa_antecedentes_estadual': '',
    'negativa_antecedentes_militar': '',
    'cnh': '',
    'rg': '',
    'toxicologico': '',
    'renavam': '',
  };

  String? selectedServiceType;
  String? selectedBrand;
  String? selectedModel;
  String? selectedYear;
  String? selectedColor;
  int _currentPageIndex = 0;
  PageController _pageController = PageController();

  Map<String, List<String>> serviceCategories = {
    'Sedan Exec.': ['CHEVROLET CRUZE', 'NISSAN SENTRA', 'TOYOTA COROLLA'],
    'Sedan Prime': ['BMW 320i', 'BMW 530i', 'BMW 740i', 'MERCEDES E300', 'MERCEDES S500', 'MERCEDES C300'],
    'SUV Especial': ['COROLLA CROSS', 'JEEP COMPASS', 'KIA SORENTO', 'VOLKSWAGEN TAOS'],
    'SUV Prime': ['JEEP COMMANDER', 'MITSUBISHI PAJERO', 'TOYOTA SW4', 'VOLKSWAGEN TIGUAN'],
    'Mini Van': ['MINI VAN'],
    'Van': ['VAN']
  };

  List<String> years = List.generate(7, (index) => (2018 + index).toString());

  List<String> colors = ['Azul', 'Preto', 'Branco', 'Cinza', 'Vermelho'];

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _showContractDialog(context);
    });
  }

  void _showContractDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            "Leia o Contrato!",
            style: TextStyle(color: Colors.red),
          ),
          content: const Text(
            "Por favor, leia e aceite o contrato antes de continuar com o registro. Existem regras no contrato que, em caso de não cumprimento, podem levar o motorista à suspensão ou banimento do app.",
            style: TextStyle(color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK", style: TextStyle(color: Color.fromRGBO(20, 125, 240, 1))),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height - 150,
              child: PageView(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPageIndex = page;
                  });
                },
                children: [
                  buildPersonalInfoForm(),
                  buildCarInfoForm(),
                  buildDocumentUploadForm(),
                  buildPaymentInfoForm(),
                ],
              ),
            ),
            buildBottomNavigationBar(),
            buildLoginLink(),
          ],
        ),
      ),
    );
  }

  Widget buildBottomNavigationBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPageIndex != 0)
            buildButton("Anterior", () {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.ease,
              );
            }),
          buildButton(
            _currentPageIndex == 3 ? "Registrar" : "Próximo",
                () async {
              if (_currentPageIndex == 0) {
                if (!isPersonalInfoComplete()) {
                  cMethods.displaySnackBar("Por favor, complete todas as informações pessoais.", context);
                  return;
                }
                await uploadPersonalInfo();
              } else if (_currentPageIndex == 1) {
                if (!isCarInfoComplete()) {
                  cMethods.displaySnackBar("Por favor, complete todas as informações do carro.", context);
                  return;
                }
                await uploadCarInfo();
              } else if (_currentPageIndex == 2) {
                await uploadDocuments();
              } else if (_currentPageIndex == 3) {
                if (!isPaymentInfoComplete()) {
                  cMethods.displaySnackBar("Por favor, complete todas as informações de pagamento.", context);
                  return;
                }
                await uploadPaymentInfo();

                // Mostrar notificação para o usuário após o upload completo
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      backgroundColor: const Color.fromRGBO(0, 40, 30, 1),
                      title: const Text(
                        "Conta em Verificação",
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        "Fique atento aos meios de contato inseridos, sua conta está sendo verificada e você receberá um retorno em breve.",
                        style: TextStyle(color: Colors.white70),
                        textAlign: TextAlign.justify,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Bordas menos arredondadas
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Fechar a caixa de diálogo
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                                  (Route<dynamic> route) => false,
                            ); // Redirecionar para a tela de login
                          },
                          child: const Text(
                            "OK",
                            style: TextStyle(color: Color.fromRGBO(20, 125, 240, 1)),
                          ),
                        ),
                      ],
                    );
                  },
                );
              }

              if (_currentPageIndex < 3) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.ease,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget buildButton(String text, VoidCallback onPressed, {bool enabled = true}) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? const Color.fromARGB(255, 0, 40, 30) : Colors.grey,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget buildLoginLink() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: TextButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (c) => const LoginScreen()));
          },
          child: const Text(
            "Já tem uma conta? Faça login aqui.",
            style: TextStyle(
              color: Color.fromRGBO(20, 125, 240, 1),
            ),
          ),
        ),
      ),
    );
  }

  bool isPersonalInfoComplete() {
    return userNameTextEditingController.text.trim().isNotEmpty &&
        userPhoneTextEditingController.text.trim().isNotEmpty &&
        emailTextEditingController.text.trim().isNotEmpty &&
        passwordTextEditingController.text.trim().isNotEmpty &&
        imageFile != null;
  }

  bool isCarInfoComplete() {
    return selectedBrand != null &&
        selectedModel != null &&
        selectedYear != null &&
        selectedColor != null &&
        vehicleNumberTextEditingController.text.trim().isNotEmpty &&
        selectedServiceType != null &&
        carImages.values.any((image) => image != null);
  }

  bool isPaymentInfoComplete() {
    return cpfPassportTextEditingController.text.trim().isNotEmpty &&
        pixKeyTextEditingController.text.trim().isNotEmpty &&
        bankNameTextEditingController.text.trim().isNotEmpty &&
        bankAgencyTextEditingController.text.trim().isNotEmpty &&
        bankAccountNumberTextEditingController.text.trim().isNotEmpty;
  }

  Future<String> uploadImage(File imageFile, String fileName) async {
    try {
      Reference reference = FirebaseStorage.instance.ref().child("Images").child(fileName);
      UploadTask uploadTask = reference.putFile(imageFile);

      // Listen to the task and handle errors
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        // Handle upload progress
      }, onError: (e) {
        // Handle upload error
        cMethods.displaySnackBar("Erro no upload da imagem: $e", context);
      });

      // Wait for the upload to complete
      TaskSnapshot snapshot = await uploadTask;
      String downloadURL = await snapshot.ref.getDownloadURL();

      return downloadURL;
    } catch (e) {
      cMethods.displaySnackBar("Erro no upload da imagem: $e", context);
      return "";
    }
  }

  Future<void> uploadPersonalInfo() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => LoadingDialog(messageText: "Fazendo upload..."),
      );

      String imageIDName = DateTime.now().millisecondsSinceEpoch.toString();
      String imageURL = await uploadImage(File(imageFile!.path), imageIDName);

      final User? userFirebase = FirebaseAuth.instance.currentUser;

      if (userFirebase == null) {
        Navigator.pop(context);
        cMethods.displaySnackBar("Usuário não encontrado.", context);
        return;
      }

      DatabaseReference usersRef = FirebaseDatabase.instance.ref().child("drivers").child(userFirebase.uid);

      Map<String, String> driverPersonalInfo = {
        "photo": imageURL,
        "name": userNameTextEditingController.text.trim(),
        "email": emailTextEditingController.text.trim(),
        "phone": userPhoneTextEditingController.text.trim(),
        "cpf": !isForeignUser ? cpfPassportTextEditingController.text.trim() : "",
        "passport": isForeignUser ? cpfPassportTextEditingController.text.trim() : "",
        "blockStatus": "yes",
      };

      await usersRef.update(driverPersonalInfo);
      Navigator.pop(context);
    } catch (e) {
      Navigator.pop(context);
      cMethods.displaySnackBar("Erro no upload das informações pessoais: $e", context);
    }
  }

  Future<void> uploadCarImages() async {
    for (String key in carImages.keys) {
      if (carImages[key] != null) {
        String imageIDName = '$key' + '_' + '${DateTime.now().millisecondsSinceEpoch}';
        String downloadURL = await uploadImage(File(carImages[key]!.path), imageIDName);
        carImagesUrls[key] = downloadURL;
      }
    }
  }

  Future<void> uploadCarInfo() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => LoadingDialog(messageText: "Fazendo upload..."),
      );

      await uploadCarImages();

      User? userFirebase = FirebaseAuth.instance.currentUser;

      if (userFirebase == null) {
        Navigator.pop(context);
        cMethods.displaySnackBar("Usuário não encontrado.", context);
        return;
      }

      DatabaseReference usersRef = FirebaseDatabase.instance.ref().child("drivers").child(userFirebase.uid);

      Map<String, dynamic> driverCarInfo = {
        "carColor": selectedColor,
        "carBrand": selectedBrand,
        "carModel": selectedModel,
        "carYear": selectedYear,
        "carNumber": vehicleNumberTextEditingController.text.trim(),
        "serviceType": selectedServiceType,
        "images": carImagesUrls,
      };

      await usersRef.update({"car_details": driverCarInfo});
      Navigator.pop(context);
    } catch (e) {
      Navigator.pop(context);
      cMethods.displaySnackBar("Erro no upload das informações do carro: $e", context);
    }
  }

  Future<void> uploadDocuments() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => LoadingDialog(messageText: "Fazendo upload..."),
      );

      for (String key in documentFiles.keys) {
        if (documentFiles[key] != null) {
          String fileIDName = '$key' + '_' + '${DateTime.now().millisecondsSinceEpoch}';
          String downloadURL = await uploadImage(documentFiles[key]!, fileIDName);
          documentFilesUrls[key] = downloadURL;
        }
      }

      User? userFirebase = FirebaseAuth.instance.currentUser;

      if (userFirebase == null) {
        Navigator.pop(context);
        cMethods.displaySnackBar("Usuário não encontrado.", context);
        return;
      }

      DatabaseReference usersRef = FirebaseDatabase.instance.ref().child("drivers").child(userFirebase.uid);

      Map<String, dynamic> driverDocumentsInfo = {
        "negativa_antecedentes_federal": documentFilesUrls['negativa_antecedentes_federal'],
        "negativa_antecedentes_estadual": documentFilesUrls['negativa_antecedentes_estadual'],
        "negativa_antecedentes_militar": documentFilesUrls['negativa_antecedentes_militar'],
        "cnh": documentFilesUrls['cnh'],
        "rg": documentFilesUrls['rg'],
        "toxicologico": documentFilesUrls['toxicologico'],
        "renavam": documentFilesUrls['renavam'],
      };

      await usersRef.update({"documents": driverDocumentsInfo});

      Navigator.pop(context);
    } catch (e) {
      Navigator.pop(context);
      cMethods.displaySnackBar("Erro no upload dos documentos: $e", context);
    }
  }

  Future<void> uploadPaymentInfo() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => LoadingDialog(messageText: "Fazendo upload..."),
      );

      User? userFirebase = FirebaseAuth.instance.currentUser;

      if (userFirebase == null) {
        Navigator.pop(context);
        cMethods.displaySnackBar("Usuário não encontrado.", context);
        return;
      }

      DatabaseReference usersRef = FirebaseDatabase.instance.ref().child("drivers").child(userFirebase.uid);

      Map<String, dynamic> paymentInfo = {
        "cpf": !isForeignUser ? cpfPassportTextEditingController.text.trim() : "",
        "passport": isForeignUser ? cpfPassportTextEditingController.text.trim() : "",
        "pixKey": pixKeyTextEditingController.text.trim(),
        "bankName": bankNameTextEditingController.text.trim(),
        "bankAgency": bankAgencyTextEditingController.text.trim(),
        "bankAccountNumber": bankAccountNumberTextEditingController.text.trim(),
      };

      await usersRef.update({"payment_info": paymentInfo});

      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color.fromRGBO(0, 40, 30, 1),
            title: const Text(
              "Conta em Verificação",
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              "Fique atento aos meios de contato inseridos, sua conta está sendo verificada e você receberá um retorno em breve.",
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.justify,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // Bordas menos arredondadas
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Fechar a caixa de diálogo
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (Route<dynamic> route) => false,
                  ); // Redirecionar para a tela de login
                },
                child: const Text(
                  "OK",
                  style: TextStyle(color: Color.fromRGBO(20, 125, 240, 1)),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      Navigator.pop(context);
      cMethods.displaySnackBar("Erro no upload das informações de pagamento: $e", context);
    }
  }

  chooseImageFromGallery() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        imageFile = pickedFile;
      });
    }
  }

  chooseCarImage(String key) async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        carImages[key] = pickedFile;
      });
    }
  }

  chooseDocumentFile(String key) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      setState(() {
        documentFiles[key] = File(result.files.single.path!);
      });
    }
  }

  Widget buildPersonalInfoForm() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView( // Adicionando scroll
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 15),
            const Text(
              'Informações Pessoais',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 40, 30)),
            ),
            const SizedBox(height: 20),
            imageFile == null
                ? const CircleAvatar(
              radius: 86,
              backgroundImage: AssetImage("assets/images/avatarman.png"),
            )
                : Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey,
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: FileImage(File(imageFile!.path)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: chooseImageFromGallery,
              child: const Text(
                "Selecionar Imagem",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(20, 125, 240, 1),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: userNameTextEditingController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: "Nome",
                labelStyle: TextStyle(
                  fontSize: 14,
                  color: Color.fromRGBO(0, 40, 30, 1),
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 185, 150, 100)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 0, 40, 30)),
                ),
              ),
              style: const TextStyle(
                color: Color.fromARGB(255, 0, 40, 30),
                fontSize: 15,
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: userPhoneTextEditingController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: "Número de Contato",
                labelStyle: TextStyle(
                  fontSize: 14,
                  color: Color.fromRGBO(0, 40, 30, 1),
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 185, 150, 100)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 0, 40, 30)),
                ),
              ),
              style: const TextStyle(
                color: Color.fromARGB(255, 0, 40, 30),
                fontSize: 15,
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: emailTextEditingController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Email de Contato",
                labelStyle: TextStyle(
                  fontSize: 14,
                  color: Color.fromRGBO(0, 40, 30, 1),
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 185, 150, 100)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 0, 40, 30)),
                ),
              ),
              style: const TextStyle(
                color: Color.fromARGB(255, 0, 40, 30),
                fontSize: 15,
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: passwordTextEditingController,
              obscureText: true,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: "Senha",
                labelStyle: TextStyle(
                  fontSize: 14,
                  color: Color.fromRGBO(0, 40, 30, 1),
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 185, 150, 100)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 0, 40, 30)),
                ),
              ),
              style: const TextStyle(
                color: Color.fromARGB(255, 0, 40, 30),
                fontSize: 15,
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: cpfPassportTextEditingController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: isForeignUser ? "Passaporte" : "CPF",
                labelStyle: TextStyle(
                  fontSize: 14,
                  color: Color.fromRGBO(0, 40, 30, 1),
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 185, 150, 100)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 0, 40, 30)),
                ),
              ),
              style: const TextStyle(
                color: Color.fromARGB(255, 0, 40, 30),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isForeignUser = false;
                      cpfPassportTextEditingController.clear();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    backgroundColor: isForeignUser
                        ? Colors.grey.shade300
                        : const Color.fromARGB(255, 0, 40, 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "CPF",
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isForeignUser = true;
                      cpfPassportTextEditingController.clear();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    backgroundColor: isForeignUser
                        ? const Color.fromARGB(255, 0, 40, 30)
                        : Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Passaporte",
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCarInfoForm() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 50),
            const Text('Informações do Veículo', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 40, 30))),
            const SizedBox(height: 22),
            const Text(
              'Complete os campos abaixo com as informações do veículo de trabalho.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 22),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: "Categoria de Serviço",
                labelStyle: TextStyle(
                  fontSize: 14,
                  color: Color.fromRGBO(0, 40, 30, 1),
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 185, 150, 100)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 0, 40, 30)),
                ),
              ),
              items: serviceCategories.keys.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedServiceType = newValue;
                  selectedBrand = null;
                  selectedModel = null;
                });
              },
              value: selectedServiceType,
              dropdownColor: Colors.grey.shade300,
            ),
            const SizedBox(height: 22),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: "Marca",
                labelStyle: TextStyle(
                  fontSize: 14,
                  color: Color.fromRGBO(0, 40, 30, 1),
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 185, 150, 100)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 0, 40, 30)),
                ),
              ),
              items: selectedServiceType != null
                  ? serviceCategories[selectedServiceType]!
                  .map((String brandModel) => brandModel.split(' ')[0])
                  .toSet()
                  .map((String brand) {
                return DropdownMenuItem<String>(
                  value: brand,
                  child: Text(brand),
                );
              }).toList()
                  : [],
              onChanged: (String? newValue) {
                setState(() {
                  selectedBrand = newValue;
                  selectedModel = null;
                });
              },
              value: selectedBrand,
              dropdownColor: Colors.grey.shade300,
            ),
            const SizedBox(height: 22),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: "Modelo",
                labelStyle: TextStyle(
                  fontSize: 14,
                  color: Color.fromRGBO(0, 40, 30, 1),
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 185, 150, 100)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 0, 40, 30)),
                ),
              ),
              items: selectedBrand != null
                  ? serviceCategories[selectedServiceType]!
                  .where((String brandModel) => brandModel.startsWith(selectedBrand!))
                  .map((String brandModel) => brandModel.split(' ').sublist(1).join(' '))
                  .map((String model) {
                return DropdownMenuItem<String>(
                  value: model,
                  child: Text(model),
                );
              }).toList()
                  : [],
              onChanged: (String? newValue) {
                setState(() {
                  selectedModel = newValue;
                });
              },
              value: selectedModel,
              dropdownColor: Colors.grey.shade300,
            ),
            const SizedBox(height: 22),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: "Ano do Veículo",
                labelStyle: TextStyle(
                  fontSize: 14,
                  color: Color.fromRGBO(0, 40, 30, 1),
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 185, 150, 100)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 0, 40, 30)),
                ),
              ),
              items: years.map((String year) {
                return DropdownMenuItem<String>(
                  value: year,
                  child: Text(year),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedYear = newValue;
                });
              },
              value: selectedYear,
              dropdownColor: Colors.grey.shade300,
            ),
            const SizedBox(height: 22),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: "Cor do Veículo",
                labelStyle: TextStyle(
                  fontSize: 14,
                  color: Color.fromRGBO(0, 40, 30, 1),
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 185, 150, 100)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 0, 40, 30)),
                ),
              ),
              items: colors.map((String color) {
                return DropdownMenuItem<String>(
                  value: color,
                  child: Text(color),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedColor = newValue;
                });
              },
              value: selectedColor,
              dropdownColor: Colors.grey.shade300,
            ),
            const SizedBox(height: 22),
            TextField(
              controller: vehicleNumberTextEditingController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: "Placa do Veículo",
                labelStyle: TextStyle(
                  fontSize: 14,
                  color: Color.fromRGBO(0, 40, 30, 1),
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 185, 150, 100)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 0, 40, 30)),
                ),
                errorText: isPlateValid(vehicleNumberTextEditingController.text) ? null : "Placa inválida",
              ),
              style: const TextStyle(
                color: Color.fromARGB(255, 0, 40, 30),
                fontSize: 15,
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 22),
            const Text(
              'Insira as seguintes fotos do veículo:',
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey
              ),
            ),
            const SizedBox(height: 10),
            buildCarImagePicker('frente', 'Foto da Frente'),
            buildCarImagePicker('traseira', 'Foto da Traseira'),
            buildCarImagePicker('lateral_direita', 'Foto Lateral Direita'),
            buildCarImagePicker('lateral_esquerda', 'Foto Lateral Esquerda'),
            buildCarImagePicker('chassi', 'Foto do Número do Chassi'),
            buildCarImagePicker('pneu_dianteiro_direito', 'Foto do Pneu Dianteiro Direito'),
            buildCarImagePicker('pneu_dianteiro_esquerdo', 'Foto do Pneu Dianteiro Esquerdo'),
            buildCarImagePicker('pneu_traseiro_direito', 'Foto do Pneu Traseiro Direito'),
            buildCarImagePicker('pneu_traseiro_esquerdo', 'Foto do Pneu Traseiro Esquerdo'),
          ],
        ),
      ),
    );
  }

  Widget buildDocumentUploadForm() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 50),
            const Text('Upload de Documentos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 40, 30))),
            const SizedBox(height: 15),
            const Text(
              'Realize o upload dos arquivos exigidos abaixo. Todos os documentos abaixo do motorista e veículo são necessários para o cadastro.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 15),
            buildDocumentFilePicker('negativa_antecedentes_federal', 'Negativa de Antecedentes (Federal)'),
            buildDocumentFilePicker('negativa_antecedentes_estadual', 'Negativa de Antecedentes (Estadual)'),
            buildDocumentFilePicker('negativa_antecedentes_militar', 'Negativa de Antecedentes (Militar)'),
            buildDocumentFilePicker('cnh', 'CNH (Incluindo EAR)'),
            buildDocumentFilePicker('rg', 'RG'),
            buildDocumentFilePicker('toxicologico', 'Toxicológico (Últimos 12 meses)'),
            buildDocumentFilePicker('renavam', 'Documento CRLV'),
          ],
        ),
      ),
    );
  }

  Widget buildPaymentInfoForm() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 50),
            const Text('Informações de Pagamento', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 40, 30))),
            const SizedBox(height: 15),
            const Text(
              'Insira as informações de pagamento abaixo. Os dados bancários devem estar associados ao nome e CPF/Passaporte do motorista.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: cpfPassportTextEditingController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: isForeignUser ? "Passaporte" : "CPF",
                labelStyle: TextStyle(
                  fontSize: 14,
                  color: Color.fromRGBO(0, 40, 30, 1),
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 185, 150, 100)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 0, 40, 30)),
                ),
              ),
              style: const TextStyle(
                color: Color.fromARGB(255, 0, 40, 30),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: pixKeyTextEditingController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: "Chave Pix",
                labelStyle: TextStyle(
                  fontSize: 14,
                  color: Color.fromRGBO(0, 40, 30, 1),
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 185, 150, 100)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 0, 40, 30)),
                ),
              ),
              style: const TextStyle(
                color: Color.fromARGB(255, 0, 40, 30),
                fontSize: 15,
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: bankNameTextEditingController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: "Nome do Banco",
                labelStyle: TextStyle(
                  fontSize: 14,
                  color: Color.fromRGBO(0, 40, 30, 1),
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 185, 150, 100)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 0, 40, 30)),
                ),
              ),
              style: const TextStyle(
                color: Color.fromARGB(255, 0, 40, 30),
                fontSize: 15,
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: bankAgencyTextEditingController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Agência Bancária",
                labelStyle: TextStyle(
                  fontSize: 14,
                  color: Color.fromRGBO(0, 40, 30, 1),
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 185, 150, 100)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 0, 40, 30)),
                ),
              ),
              style: const TextStyle(
                color: Color.fromARGB(255, 0, 40, 30),
                fontSize: 15,
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: bankAccountNumberTextEditingController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Número da Conta",
                labelStyle: TextStyle(
                  fontSize: 14,
                  color: Color.fromRGBO(0, 40, 30, 1),
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 185, 150, 100)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 0, 40, 30)),
                ),
              ),
              style: const TextStyle(
                color: Color.fromARGB(255, 0, 40, 30),
                fontSize: 15,
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 15),
            const Text(
              '* As informações bancárias devem estar associadas ao nome e CPF/Passaporte do motorista.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCarImagePicker(String key, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color.fromRGBO(0, 40, 30, 1),
          ),
        ),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: () => chooseCarImage(key),
          child: Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              border: Border.all(
                color: Colors.grey.shade400,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: carImages[key] == null
                ? const Center(
              child: Text(
                'Selecionar Imagem',
                style: TextStyle(
                  color: Color.fromRGBO(20, 125, 240, 1),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
                : Image.file(
              File(carImages[key]!.path),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          carImagesUrls[key] != '' ? 'Foto enviada com sucesso!' : '',
          style: const TextStyle(
            color: Colors.green,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget buildDocumentFilePicker(String key, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color.fromRGBO(0, 40, 30, 1),
          ),
        ),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: () => chooseDocumentFile(key),
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              border: Border.all(
                color: Colors.grey.shade400,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: documentFiles[key] == null
                ? const Center(
              child: Text(
                'Selecionar Arquivo',
                style: TextStyle(
                  color: Color.fromRGBO(20, 125, 240, 1),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
                : Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Arquivo Selecionado',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          documentFilesUrls[key] != '' ? 'Arquivo enviado com sucesso!' : '',
          style: const TextStyle(
            color: Colors.green,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  bool isPlateValid(String plate) {
    final mercosulRegex = RegExp(r'^[A-Z]{3}[0-9][A-Z0-9][0-9]{2}$');
    return mercosulRegex.hasMatch(plate);
  }
}
