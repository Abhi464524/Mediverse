import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../feature/doctorPages/view/doctor_homepage_view.dart';
import '../../feature/patientsPages/view/patient_home_view.dart';
import '../services/storage_service.dart';

class LogInPage extends StatefulWidget {
  final String role;
  const LogInPage({super.key, required this.role});

  @override
  State<LogInPage> createState() => _LogInPageState();
}

class _LogInPageState extends State<LogInPage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController specializationController = TextEditingController();

  bool _loginPasswordObscured = true;
  bool _signupPasswordObscured = true;

  /// Authentication via Firebase Auth
  void _authentication() async {
    String inputName = nameController.text.trim();
    String inputPass = passwordController.text.trim();

    if (inputName.isEmpty || inputPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please enter both username and password")),
      );
      return;
    }

    try {
      StorageService storage = await StorageService.getInstance();
      Map<String, String>? user = await storage.signIn(inputName, inputPass);

      if (!mounted) return;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid credentials")),
        );
        return;
      }

      String role = user['role'] ?? '';
      if (role != widget.role.toLowerCase()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid credentials or role")),
        );
        return;
      }

      String name = user['username'] ?? inputName;
      String speciality = user['speciality'] ?? '';

      if (role == "doctor") {
        Get.off(DoctorHomePage(name: name, speciality: speciality));
      } else if (role == "patient") {
        Get.off(PatientHomePage(name: name));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login error: ${e.toString()}")),
      );
    }
  }

  /// Signup new user via Firebase Auth + Firestore
  void _signupNewUser() {
    TextEditingController usernameController = TextEditingController();
    TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New User SignUp"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                  labelText:
                      widget.role == "doctor" ? "Doctor Name" : "Patient Name"),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: "Password",
                suffixIcon: IconButton(
                  icon: Icon(
                    _signupPasswordObscured
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _signupPasswordObscured = !_signupPasswordObscured;
                    });
                  },
                ),
              ),
              obscureText: _signupPasswordObscured,
            ),
            widget.role == "doctor"
                ? TextField(
                    controller: specializationController,
                    decoration:
                        const InputDecoration(labelText: "Specialization"),
                  )
                : const SizedBox(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                String userName = usernameController.text.trim();
                String pass = passwordController.text.trim();
                String speciality = specializationController.text.trim();

                if (userName.isEmpty || pass.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter all details")),
                  );
                  return;
                }

                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                try {
                  StorageService storage = await StorageService.getInstance();
                  bool saved = await storage.saveUser(
                    username: userName,
                    password: pass,
                    role: widget.role.toLowerCase(),
                    speciality: speciality,
                  );

                  if (!saved) {
                    throw Exception("Username may already be taken.");
                  }

                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(content: Text("Registered Successfully")),
                  );

                  if (widget.role.toLowerCase() == "doctor") {
                    Get.off(
                        DoctorHomePage(name: userName, speciality: speciality));
                  } else {
                    Get.off(PatientHomePage(name: userName));
                  }
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                        content: Text("Registration failed: ${e.toString()}")),
                  );
                }
              },
              child: const Text("Register"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6F8),
      ),
      body: Container(
        color: const Color(0xFFF4F6F8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _login(),
          ],
        ),
      ),
    );
  }

  Widget _login() {
    return Column(
      children: [
        Text(
          "Login as ${widget.role.toUpperCase()}",
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 100),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(width: 2, color: const Color(0xFFB0BEC5)),
            borderRadius: const BorderRadius.all(Radius.circular(20)),
          ),
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(
                      controller: nameController,
                      decoration:
                          const InputDecoration(labelText: "Enter User Name"),
                    ),
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: "Enter Password",
                        suffixIcon: IconButton(
                          icon: Icon(
                            _loginPasswordObscured
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _loginPasswordObscured = !_loginPasswordObscured;
                            });
                          },
                        ),
                      ),
                      obscureText: _loginPasswordObscured,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                      onPressed: _authentication,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C3E50),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      child: const Text("Login")),
                  ElevatedButton(
                      onPressed: _signupNewUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C3E50),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      child: const Text("Sign Up")),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
