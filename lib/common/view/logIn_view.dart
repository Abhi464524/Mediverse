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

  void _signupNewUser() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ModernSignUpSheet(role: widget.role),
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

/// Modern signup UI — sage/mint theme, rounded sheet, icons, primary CTA.
class _ModernSignUpSheet extends StatefulWidget {
  final String role;

  const _ModernSignUpSheet({required this.role});

  @override
  State<_ModernSignUpSheet> createState() => _ModernSignUpSheetState();
}

class _ModernSignUpSheetState extends State<_ModernSignUpSheet> {
  static const Color _sage = Color(0xFF6A9C89);
  static const Color _mintBg = Color(0xFFF8FBF9);
  static const Color _border = Color(0xFFC4DAD2);

  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _specializationController;
  bool _obscurePassword = true;
  bool _submitting = false;

  bool get _isDoctor => widget.role.toLowerCase() == 'doctor';

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _specializationController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _specializationController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final userName = _usernameController.text.trim();
    final pass = _passwordController.text.trim();
    final speciality = _specializationController.text.trim();

    if (userName.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter name and password'),
          backgroundColor: Color(0xFFE57373),
        ),
      );
      return;
    }

    if (_isDoctor && speciality.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your specialization'),
          backgroundColor: Color(0xFFE57373),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final storage = await StorageService.getInstance();
      final saved = await storage.saveUser(
        username: userName,
        password: pass,
        role: widget.role.toLowerCase(),
        speciality: speciality,
      );

      if (!mounted) return;

      if (!saved) {
        throw Exception('Username may already be taken.');
      }

      // Persist session immediately after signup so app relaunch keeps user logged in.
      await storage.signIn(userName, pass);

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Welcome! Your account is ready.'),
          backgroundColor: _sage,
        ),
      );

      if (widget.role.toLowerCase() == 'doctor') {
        Get.off(DoctorHomePage(name: userName, speciality: speciality));
      } else {
        Get.off(PatientHomePage(name: userName));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${e.toString()}'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _sage, size: 22),
      suffixIcon: suffix,
      filled: true,
      fillColor: _mintBg,
      alignLabelWithHint: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _sage, width: 2),
      ),
      labelStyle: TextStyle(color: Colors.grey.shade700, fontSize: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final roleLabel = _isDoctor ? 'Doctor' : 'Patient';

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 24,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _mintBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: _border, width: 2),
                ),
                child: Icon(
                  _isDoctor ? Icons.medical_services_rounded : Icons.person_rounded,
                  size: 36,
                  color: _sage,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Create account',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sign up as $roleLabel — quick and secure.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _usernameController,
                textCapitalization: TextCapitalization.words,
                decoration: _fieldDecoration(
                  label: _isDoctor ? 'Full name' : 'Your name',
                  icon: Icons.badge_outlined,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: _fieldDecoration(
                  label: 'Password',
                  icon: Icons.lock_outline_rounded,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
              ),
              if (_isDoctor) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _specializationController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _fieldDecoration(
                    label: 'Specialization',
                    icon: Icons.healing_outlined,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _sage,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _sage.withOpacity(0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Create account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
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
