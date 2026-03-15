import 'package:doctor_app/common/view/logIn_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class userSelectionPage extends StatefulWidget {
  const userSelectionPage({super.key});

  @override
  State<userSelectionPage> createState() => _userSelectionPageState();
}

class _userSelectionPageState extends State<userSelectionPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 100, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F8), // Pale Slate
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              child: Text(
                "USER SELECTION",
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.black,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            SizedBox(
              height: 50,
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                    color: const Color(0xFFB0BEC5), width: 4), // Blue Grey
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              child: Image.asset(
                "assets/selection_page/doctor_selection.png",
                height: 150,
                width: 150,
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Container(
              width: 150,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                    color: const Color(0xFF2C3E50), width: 2), // Midnight Blue
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xFF2C3E50), // Midnight Blue
              ),
              child: Center(
                  child: GestureDetector(
                onTap: () {
                  Get.to(LogInPage(role: "doctor"));
                },
                child: Text(
                  "Doctor",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    decoration: TextDecoration.none,
                  ),
                ),
              )),
            ),
            SizedBox(
              height: 50,
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                    color: const Color(0xFFB0BEC5), width: 4), // Blue Grey
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              child: Image.asset(
                "assets/selection_page/patient_selection.png",
                height: 150,
                width: 150,
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Container(
              width: 150,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                    color: const Color(0xFF2C3E50), width: 2), // Midnight Blue
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xFF2C3E50), // Midnight Blue
              ),
              child: Center(
                  child: GestureDetector(
                onTap: () {
                  Get.to(LogInPage(role: "patient"));
                },
                child: Text(
                  "Patient",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    decoration: TextDecoration.none,
                  ),
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }
}
