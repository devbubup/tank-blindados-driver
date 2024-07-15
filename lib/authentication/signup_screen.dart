import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../methods/common_methods.dart';
import '../pages/dashboard.dart';
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
  TextEditingController vehicleModelTextEditingController = TextEditingController();
  TextEditingController vehicleColorTextEditingController = TextEditingController();
  TextEditingController vehicleNumberTextEditingController = TextEditingController();
  TextEditingController vehicleYearTextEditingController = TextEditingController(); // Campo para o ano do carro
  TextEditingController renavamTextEditingController = TextEditingController(); // Campo para RENAVAM
  CommonMethods cMethods = CommonMethods();
  XFile? imageFile;
  String urlOfUploadedImage = "";

  Map<String, XFile?> carImages = {
    'frente': null,
    'traseira': null,
    'lateral_direita': null,
    'lateral_esquerda': null,
    'chassi': null,
    'pneus': null,
  };

  Map<String, String> carImagesUrls = {
    'frente': '',
    'traseira': '',
    'lateral_direita': '',
    'lateral_esquerda': '',
    'chassi': '',
    'pneus': '',
  };

  Map<String, File?> documentFiles = {
    'negativa_antecedentes_federal': null,
    'negativa_antecedentes_estadual': null,
    'negativa_antecedentes_militar': null,
    'cnh': null,
    'rg': null,
    'toxicologico': null,
    'renavam': null,  // Campo para arquivo RENAVAM
  };

  Map<String, String> documentFilesUrls = {
    'negativa_antecedentes_federal': '',
    'negativa_antecedentes_estadual': '',
    'negativa_antecedentes_militar': '',
    'cnh': '',
    'rg': '',
    'toxicologico': '',
    'renavam': '',  // URL do arquivo RENAVAM
  };

  String? selectedServiceType;
  int _currentPageIndex = 0;
  PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
              _currentPageIndex == 2 ? "Registrar" : "Próximo",
                  () async {
                if (_currentPageIndex == 0) await uploadPersonalInfo();
                else if (_currentPageIndex == 1) await uploadCarInfo();
                else if (_currentPageIndex == 2) await uploadDocuments();

                if (_currentPageIndex < 2) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.ease,
                  );
                }
              },
              enabled: true // Sempre ativado conforme solicitado
          ),
        ],
      ),
    );
  }

  Widget buildButton(String text, VoidCallback onPressed, {bool enabled = true}) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? Colors.black : Colors.grey,
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
              color: Colors.blue,
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
    int year = int.tryParse(vehicleYearTextEditingController.text) ?? 0;
    return vehicleModelTextEditingController.text.trim().isNotEmpty &&
        vehicleColorTextEditingController.text.trim().isNotEmpty &&
        vehicleNumberTextEditingController.text.trim().isNotEmpty &&
        selectedServiceType != null &&
        year >= 2018 &&
        carImages.values.every((image) => image != null);
  }

  bool isDocumentsInfoComplete() {
    return documentFiles.values.every((file) => file != null) &&
        renavamTextEditingController.text.trim().isNotEmpty;
  }

  Future<void> uploadPersonalInfo() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => LoadingDialog(messageText: "Fazendo upload..."),
      );

      String imageIDName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference referenceImage = FirebaseStorage.instance.ref().child("Images").child(imageIDName);

      UploadTask uploadTask = referenceImage.putFile(File(imageFile!.path));
      TaskSnapshot snapshot = await uploadTask;
      urlOfUploadedImage = await snapshot.ref.getDownloadURL();

      setState(() {
        urlOfUploadedImage;
      });

      final User? userFirebase = (await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailTextEditingController.text.trim(),
        password: passwordTextEditingController.text.trim(),
      ).catchError((errorMsg) {
        Navigator.pop(context);
        cMethods.displaySnackBar(errorMsg.toString(), context);
      })).user;

      if (!context.mounted) return;
      Navigator.pop(context);

      DatabaseReference usersRef = FirebaseDatabase.instance.ref().child("drivers").child(userFirebase!.uid);

      Map<String, String> driverPersonalInfo = {
        "photo": urlOfUploadedImage,
        "name": userNameTextEditingController.text.trim(),
        "email": emailTextEditingController.text.trim(),
        "phone": userPhoneTextEditingController.text.trim(),
        "id": userFirebase.uid,
        "blockStatus": "no",
      };

      await usersRef.set(driverPersonalInfo);
    } catch (e) {
      Navigator.pop(context);
      cMethods.displaySnackBar("Erro no upload das informações pessoais: $e", context);
    }
  }

  Future<void> uploadCarInfo() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => LoadingDialog(messageText: "Fazendo upload..."),
      );

      for (String key in carImages.keys) {
        String imageIDName = '$key' + '_' + '${DateTime.now().millisecondsSinceEpoch}';
        Reference referenceImage = FirebaseStorage.instance.ref().child("CarImages").child(imageIDName);

        UploadTask uploadTask = referenceImage.putFile(File(carImages[key]!.path));
        TaskSnapshot snapshot = await uploadTask;
        carImagesUrls[key] = await snapshot.ref.getDownloadURL();

        setState(() {
          carImagesUrls[key];
        });
      }

      User? userFirebase = FirebaseAuth.instance.currentUser;

      DatabaseReference usersRef = FirebaseDatabase.instance.ref().child("drivers").child(userFirebase!.uid);

      Map<String, dynamic> driverCarInfo = {
        "carColor": vehicleColorTextEditingController.text.trim(),
        "carModel": vehicleModelTextEditingController.text.trim(),
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
        String fileIDName = '$key' + '_' + '${DateTime.now().millisecondsSinceEpoch}';
        Reference referenceFile = FirebaseStorage.instance.ref().child("DocumentFiles").child(fileIDName);

        UploadTask uploadTask = referenceFile.putFile(documentFiles[key]!);
        TaskSnapshot snapshot = await uploadTask;
        documentFilesUrls[key] = await snapshot.ref.getDownloadURL();

        setState(() {
          documentFilesUrls[key];
        });
      }

      User? userFirebase = FirebaseAuth.instance.currentUser;

      DatabaseReference usersRef = FirebaseDatabase.instance.ref().child("drivers").child(userFirebase!.uid);

      Map<String, dynamic> driverDocumentsInfo = {
        "negativa_antecedentes_federal": documentFilesUrls['negativa_antecedentes_federal'],
        "negativa_antecedentes_estadual": documentFilesUrls['negativa_antecedentes_estadual'],
        "negativa_antecedentes_militar": documentFilesUrls['negativa_antecedentes_militar'],
        "cnh": documentFilesUrls['cnh'],
        "rg": documentFilesUrls['rg'],
        "toxicologico": documentFilesUrls['toxicologico'],
        "renavam": documentFilesUrls['renavam'],  // URL do arquivo RENAVAM
      };

      await usersRef.update({"documents": driverDocumentsInfo});
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (c) => Dashboard()));
    } catch (e) {
      Navigator.pop(context);
      cMethods.displaySnackBar("Erro no upload dos documentos: $e", context);
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          const SizedBox(height: 15),

          Text('Informações Pessoais', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black45)),

          const SizedBox(height: 20),

          imageFile == null
              ? CircleAvatar(
            radius: 86,
            backgroundImage: AssetImage("assets/images/avatarman.png"),
          )
              : Container(
            width: 180,
            height:  180,
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
                color: Colors.black45,
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
                color: Colors.grey.shade700,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade700),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: userPhoneTextEditingController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: "Número de Contato",
              labelStyle: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade700),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: emailTextEditingController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: "Email de Contato",
              labelStyle: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade700),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
            ),
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
                color: Colors.grey.shade700,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade700),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
            ),
          ),
        ],
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
            Text('Informações do Veículo', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black45)),
            const SizedBox(height: 22),
            const Text(
              'Complete os campos abaixo com as informações do veículo de trabalho.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: vehicleModelTextEditingController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: "Modelo do Veículo (Marca e Linha)",
                labelStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: vehicleYearTextEditingController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Ano do Veículo",
                labelStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: vehicleColorTextEditingController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: "Cor do Veículo",
                labelStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: vehicleNumberTextEditingController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: "Placa do Veículo",
                labelStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 22),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: "Categoria de Serviço",
                labelStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
              items: <String>['Sedan Executivo', 'Sedan Prime', 'SUV Especial', 'SUV Prime', 'Mini Van', 'Van']
                  .map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedServiceType = newValue;
                });
              },
              value: selectedServiceType,
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
            buildCarImagePicker('chassi', 'Foto do Chassi'),
            buildCarImagePicker('pneus', 'Foto dos Pneus'),
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
            Text('Upload de Documentos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black45)),
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
            buildDocumentFilePicker('renavam', 'Documento RENAVAM'),
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
            color: Colors.grey,
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
                  color: Colors.blue,
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
            color: Colors.grey,
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
                  color: Colors.blue,
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
}
