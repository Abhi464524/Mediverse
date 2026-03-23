import 'package:doctor_app/feature/patientsPages/model/patient_repository.dart';
import 'package:doctor_app/feature/patientsPages/model/patient_models.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Edit health & contact details that mirror the doctor's **Patient details** screen.
class PatientHealthProfilePage extends StatefulWidget {
  const PatientHealthProfilePage({super.key});

  @override
  State<PatientHealthProfilePage> createState() =>
      _PatientHealthProfilePageState();
}

class _PatientHealthProfilePageState extends State<PatientHealthProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final PatientRepository _repository = PatientRepository.instance;

  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _weight;
  late final TextEditingController _height;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _medicalHistory;
  late final TextEditingController _medications;
  late final TextEditingController _allergies;
  late final TextEditingController _lastVisit;

  String _gender = 'Male';
  String _bloodGroup = 'O+';

  static const _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];
  static const _blood = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-',
    'Unknown'
  ];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _age = TextEditingController();
    _weight = TextEditingController();
    _height = TextEditingController();
    _phone = TextEditingController();
    _email = TextEditingController();
    _address = TextEditingController();
    _medicalHistory = TextEditingController();
    _medications = TextEditingController();
    _allergies = TextEditingController();
    _lastVisit = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    final p = await _repository.getProfile();
    if (p == null || !mounted) return;
    setState(() {
      _name.text = p.fullName;
      _age.text = p.age;
      _weight.text = p.weight;
      _height.text = p.height;
      _phone.text = p.phone;
      _email.text = p.email;
      _address.text = p.address;
      _medicalHistory.text = p.medicalHistory;
      _medications.text = p.currentMedications;
      _allergies.text = p.allergies;
      _lastVisit.text = p.lastVisitDate;
      if (p.gender.isNotEmpty) _gender = p.gender;
      if (p.bloodGroup.isNotEmpty) _bloodGroup = p.bloodGroup;
    });
  }

  PatientProfileData _map() {
    return PatientProfileData(
      fullName: _name.text.trim(),
      age: _age.text.trim(),
      gender: _gender,
      bloodGroup: _bloodGroup,
      weight: _weight.text.trim(),
      height: _height.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      address: _address.text.trim(),
      medicalHistory: _medicalHistory.text.trim(),
      currentMedications: _medications.text.trim(),
      allergies: _allergies.text.trim(),
      lastVisitDate: _lastVisit.text.trim(),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final username = await _repository.currentUsername();
    if (username == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in again.')),
      );
      return;
    }
    final ok = await _repository.saveProfile(_map());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Health profile saved' : 'Could not save'),
      ),
    );
    if (ok) Get.back();
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _weight.dispose();
    _height.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _medicalHistory.dispose();
    _medications.dispose();
    _allergies.dispose();
    _lastVisit.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF6B9AC4);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My health information',
            style: TextStyle(
                fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            Text(
              'Keep this up to date — your doctor sees the same fields in Patient details.',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: _dec('Full name *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _age,
                    decoration: _dec('Age *'),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _gender,
                    decoration: _dec('Gender *'),
                    items: _genders
                        .map((g) => DropdownMenuItem(
                              value: g,
                              child: Text(
                                g,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _gender = v ?? _gender),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _bloodGroup,
              decoration: _dec('Blood group'),
              items: _blood
                  .map((b) => DropdownMenuItem(
                        value: b,
                        child: Text(b, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _bloodGroup = v ?? _bloodGroup),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weight,
                    decoration: _dec('Weight (kg)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _height,
                    decoration: _dec('Height (cm)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phone,
              decoration: _dec('Mobile *'),
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              decoration: _dec('Email *'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (!v.contains('@')) return 'Invalid email';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              decoration: _dec('Address *'),
              maxLines: 2,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _medicalHistory,
              decoration: _dec('Medical history'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _medications,
              decoration: _dec('Current medications'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _allergies,
              decoration: _dec('Allergies'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lastVisit,
              decoration: _dec('Last visit (optional)'),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Save',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
