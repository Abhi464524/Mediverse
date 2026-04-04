import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../services/storage_service.dart';
import '../../feature/doctorPages/view/doctor_homepage_view.dart';
import '../../feature/patientsPages/view/patient_home_view.dart';
import '../controller/auth_controller.dart';

class LogInPage extends StatefulWidget {
  final String role;
  const LogInPage({super.key, required this.role});

  @override
  State<LogInPage> createState() => _LogInPageState();
}

class _LogInPageState extends State<LogInPage> {
  final AuthController _authController = Get.put(AuthController());
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController otpController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController specializationController = TextEditingController();

  bool _loginPasswordObscured = true;
  bool _loginWithPhone = false;

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  String? _verificationId;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool get _otpSent => _verificationId != null;

  // Update if you need another country.
  static const String _firebaseCountryCode = '+91';

  static const Color _sage = Color(0xFF6A9C89);
  static const Color _mintBg = Color(0xFFF8FBF9);

  /// Prefer backend body; strip generic `HTTP <code>: ` prefix from [DioClient] errors.
  String _loginErrorForSnack(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Login failed';
    final s = raw.trim();
    final m = RegExp(r'^HTTP \d+:\s*(.+)$').firstMatch(s);
    return (m != null && m.group(1)!.trim().isNotEmpty)
        ? m.group(1)!.trim()
        : s;
  }

  InputDecoration _loginFieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
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

  void _authentication() async {
    String inputName = nameController.text.trim();
    String inputPhone = phoneController.text.trim();
    String inputOtp = otpController.text.trim();
    String inputPass = passwordController.text.trim();

    if (_loginWithPhone) {
      if (inputPhone.isEmpty || inputOtp.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter phone number and OTP")),
        );
        return;
      }
    } else {
      if (inputName.isEmpty || inputPass.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Please enter both username and password")),
        );
        return;
      }
    }

    try {
      final user = await _authController.login(
        username: _loginWithPhone ? "" : inputName,
        phoneNumber: _loginWithPhone ? inputPhone : "",
        password: _loginWithPhone ? "" : inputPass,
        otp: "",
        role: widget.role,
        showErrorSnackbar: false,
      );

      if (!mounted) return;

      if (user == null) {
        final msg = _loginErrorForSnack(_authController.lastLoginError);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        return;
      }

      if (!user.success) {
        final msg = user.message.trim().isNotEmpty
            ? user.message
            : 'Invalid credentials';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        return;
      }

      final expectedRole = widget.role.toLowerCase();
      final returnedRole = user.role.trim().toLowerCase();
      final role = returnedRole.isNotEmpty ? returnedRole : expectedRole;
      if (role != expectedRole) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid credentials or role")),
        );
        return;
      }

      final String name = user.username.isEmpty
          ? (_loginWithPhone ? inputPhone : inputName)
          : user.username;
      final storage = await StorageService.getInstance();
      final existingProfile = await storage.getCurrentUserProfile();
      final speciality = user.speciality.isNotEmpty
          ? user.speciality
          : (existingProfile?['speciality'] ?? '');
      await storage.setCurrentSession(
        username: name,
        role: role,
        phoneNumber: user.phoneNumber,
        speciality: speciality,
        userId: user.userId,
      );

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

  String _firebasePhoneE164(String phoneDigits) {
    return '$_firebaseCountryCode$phoneDigits';
  }

  bool _isValidPhone10(String phoneDigits) {
    return RegExp(r'^\d{10}$').hasMatch(phoneDigits);
  }

  Future<void> _sendOtp() async {
    final phoneDigits = phoneController.text.trim();
    if (!_isValidPhone10(phoneDigits)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 10-digit phone number')),
      );
      return;
    }

    setState(() {
      _isSendingOtp = true;
      _verificationId = null; // reset old code
      otpController.clear();
    });

    try {
      final phoneE164 = _firebasePhoneE164(phoneDigits);
      final completer = Completer<String>();

      final verifyFuture = _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneE164,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential _) async {
          // Auto-retrieval/sms auto verification is device-dependent.
          // We still require user OTP entry for a consistent UX.
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!completer.isCompleted) completer.completeError(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!completer.isCompleted) completer.complete(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (!completer.isCompleted) completer.complete(verificationId);
        },
      );
      verifyFuture.catchError((Object e) {
        if (!completer.isCompleted) completer.completeError(e);
      });

      final verificationId = await completer.future;
      if (!mounted) return;
      setState(() => _verificationId = verificationId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent. Enter OTP to verify.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send OTP: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isSendingOtp = false);
    }
  }

  Future<void> _verifyOtpAndLogin() async {
    final phoneDigits = phoneController.text.trim();
    final otp = otpController.text.trim();

    if (!_isValidPhone10(phoneDigits)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 10-digit phone number')),
      );
      return;
    }

    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter OTP')),
      );
      return;
    }

    if (_verificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please tap "Send OTP" first')),
      );
      return;
    }

    setState(() => _isVerifyingOtp = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final firebaseIdToken = await userCredential.user?.getIdToken();
      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        throw Exception('Could not fetch Firebase ID token');
      }

      // Backend contract: /users/login-phone expects ONLY firebaseIdToken.
      final authController = Get.find<AuthController>();
      final response = await authController.login(
        firebaseIdToken: firebaseIdToken,
        role: widget.role,
        showErrorSnackbar: false,
      );

      if (!mounted) return;
      if (response == null || !response.success) {
        final String msg;
        if (response != null && response.message.trim().isNotEmpty) {
          msg = response.message.trim();
        } else {
          msg = _loginErrorForSnack(authController.lastLoginError);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        return;
      }

      // Persist a local session so app can restore on restart.
      final storage = await StorageService.getInstance();
      final existingProfile = await storage.getCurrentUserProfile();
      final existingName = (existingProfile?['username'] ?? '').trim();
      final existingSpeciality = (existingProfile?['speciality'] ?? '').trim();
      final resolvedName = response.username.isNotEmpty
          ? response.username
          : (existingName.isNotEmpty ? existingName : phoneDigits);
      final resolvedSpeciality = response.speciality.isNotEmpty
          ? response.speciality
          : existingSpeciality;
      await storage.setCurrentSession(
        username: resolvedName,
        role: response.role.isNotEmpty ? response.role : widget.role,
        phoneNumber: response.phoneNumber.isNotEmpty
            ? response.phoneNumber
            : phoneDigits,
        speciality: resolvedSpeciality,
        userId: response.userId,
      );

      final roleLower = (response.role.isNotEmpty ? response.role : widget.role)
          .toLowerCase();
      final name = resolvedName;
      final speciality = resolvedSpeciality;

      if (roleLower == "doctor") {
        Get.off(DoctorHomePage(name: name, speciality: speciality));
      } else if (roleLower == "patient") {
        Get.off(PatientHomePage(name: name));
      } else {
        // Fallback: stay on page with an error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unknown role returned from server')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP verification failed: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isVerifyingOtp = false);
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
        if (!_loginWithPhone)
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
                        decoration: _loginFieldDecoration(
                          label: "User Name",
                          icon: Icons.badge_outlined,
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: passwordController,
                        decoration: _loginFieldDecoration(
                          label: "Password",
                          icon: Icons.lock_outline_rounded,
                          suffix: IconButton(
                            icon: Icon(
                              _loginPasswordObscured
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _loginPasswordObscured =
                                    !_loginPasswordObscured;
                              });
                            },
                          ),
                        ),
                        obscureText: _loginPasswordObscured,
                      ),
                    
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
                          backgroundColor: _sage,
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
                          backgroundColor: _sage,
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
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _loginWithPhone = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C3E50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.phone),
                  label: const Text("Login with phone (OTP)"),
                ),
              ],
            ),
          )
        else
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
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _loginFieldDecoration(
                          label: "Phone Number",
                          icon: Icons.phone_in_talk_outlined,
                          helperText: "10 digits",
                        ),
                      ),
                      if (_otpSent) ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: _loginFieldDecoration(
                            label: "OTP",
                            icon: Icons.verified_outlined,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (!_otpSent)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSendingOtp ? null : _sendOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C3E50),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.sms),
                      label: Text(
                        _isSendingOtp ? 'Sending...' : 'Send OTP',
                      ),
                    ),
                  ),
                if (_otpSent) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isVerifyingOtp ? null : _verifyOtpAndLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _sage,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.verified),
                      label: Text(_isVerifyingOtp ? 'Verifying...' : 'Verify & Login'),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _loginWithPhone = false;
                      _verificationId = null;
                      otpController.clear();
                    });
                  },
                  child: const Text("Back to username login"),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    otpController.dispose();
    passwordController.dispose();
    specializationController.dispose();
    super.dispose();
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
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;
  late final TextEditingController _specializationController;
  bool _obscurePassword = true;
  bool _submitting = false;
  final AuthController _authController = Get.find<AuthController>();

  bool get _isDoctor => widget.role.toLowerCase() == 'doctor';

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
    _specializationController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _specializationController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final userName = _usernameController.text.trim();
    final phoneNumber = _phoneController.text.trim();
    final pass = _passwordController.text.trim();
    final speciality = _specializationController.text.trim();

    if (userName.isEmpty || phoneNumber.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter name, phone number and password'),
          backgroundColor: Color(0xFFE57373),
        ),
      );
      return;
    }

    if (!RegExp(r'^\d{10}$').hasMatch(phoneNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid 10-digit phone number'),
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
      final response = await _authController.signUp(
        username: userName,
        phoneNumber: phoneNumber,
        password: pass,
        role: widget.role.toLowerCase(),
        speciality: speciality,
      );

      if (!mounted) return;

      if (response == null || !response.success) {
        throw Exception(
          response?.message.isNotEmpty == true
              ? response!.message
              : 'Signup failed.',
        );
      }

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
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: _fieldDecoration(
                  label: 'Phone number',
                  icon: Icons.phone_in_talk_outlined,
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
