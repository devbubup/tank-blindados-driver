import 'package:drivers_app/methods/common_methods.dart';
import 'package:flutter/material.dart';

class PaymentDialog extends StatefulWidget {
  final String fareAmount;

  PaymentDialog({super.key, required this.fareAmount});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  CommonMethods cMethods = CommonMethods();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: Colors.black54,
      child: Container(
        margin: const EdgeInsets.all(5.0),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 21,),
            const Text(
              "Sair",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 21,),
            const Divider(
              height: 1.5,
              color: Colors.white70,
              thickness: 1.0,
            ),
            const SizedBox(height: 16,),
            Text(
              "R\$ ${widget.fareAmount}",
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "A corrida foi finalizada. O valor de R\$ ${widget.fareAmount} será cobrado do usuário. Agora está disponível para novas corridas.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 31,),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);

                cMethods.turnOnLocationUpdatesForHomePage();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text(
                "Sair",
              ),
            ),
            const SizedBox(height: 41,)
          ],
        ),
      ),
    );
  }
}
