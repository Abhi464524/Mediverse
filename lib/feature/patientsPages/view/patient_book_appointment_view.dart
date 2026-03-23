import 'package:doctor_app/feature/patientsPages/model/patient_repository.dart';
import 'package:doctor_app/feature/patientsPages/model/patient_models.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Default doctor shown on patient home — used for booking label.
const String kPatientAppDoctorName = 'Dr. Shubham Chaudhary';
const String kPatientAppDoctorSpecialty = 'Cardiologist';

/// Front-desk / clinic line for patient home (tap-to-call).
const String kPatientClinicPhone = '+91 7900464524';

/// Book an appointment with the doctor: your details + visit slot + reason.
class BookAppointmentPage extends StatefulWidget {
  final String doctorName;
  final String doctorSpecialty;

  const BookAppointmentPage({
    super.key,
    this.doctorName = kPatientAppDoctorName,
    this.doctorSpecialty = kPatientAppDoctorSpecialty,
  });

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
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
  late final TextEditingController _symptoms;

  String _gender = 'Male';
  String _bloodGroup = 'O+';
  String _visitType = 'In-person consultation';
  DateTime? _preferredDate;
  String? _selectedSlot;
  bool _slotsLoading = false;
  List<PatientSlot> _slotsForSelectedDate = <PatientSlot>[];

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
  static const _visitTypes = [
    'In-person consultation',
    'Follow-up visit',
    'New patient',
    'Video consultation',
    'Urgent / same-day',
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
    _symptoms = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final p = await _repository.getProfile();
    if (!mounted) return;
    if (p == null) return;
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

  PatientProfileData _profileData() {
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

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _preferredDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d != null) {
      setState(() => _preferredDate = d);
      setState(() => _slotsLoading = true);
      final apiSlots = await _repository.getSlotsForDate(d);
      if (!mounted) return;
      setState(() {
        _slotsForSelectedDate = apiSlots;
        _slotsLoading = false;
        if (_selectedSlot != null &&
            !_slotsForSelectedDate.any((s) => s.label == _selectedSlot)) {
          _selectedSlot = null;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_preferredDate == null || _selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please choose preferred date and a free slot.')),
      );
      return;
    }
    final username = await _repository.currentUsername();
    if (username == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session error. Please sign in again.')),
      );
      return;
    }

    final profile = _profileData();
    final okProfile = await _repository.saveProfile(profile);
    final dateStr = _dateKey(_preferredDate!);
    final timeStr = _selectedSlot!;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final booking = PatientBooking(
      id: id,
      doctorName: widget.doctorName,
      doctorSpecialty: widget.doctorSpecialty,
      preferredDate: dateStr,
      preferredTime: timeStr,
      visitType: _visitType,
      symptomsReason: _symptoms.text.trim(),
      status: 'Pending',
      submittedAt: DateTime.now().toIso8601String(),
      patientName: profile.fullName,
      patientPhone: profile.phone,
      patientEmail: profile.email,
    );
    final okBook = await _repository.createBooking(booking);

    if (!mounted) return;
    if (okProfile && okBook) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Appointment request sent. The clinic will confirm your slot.'),
        ),
      );
      Get.back();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !okProfile
                ? 'Could not save your profile.'
                : 'Could not save booking. Try again.',
          ),
        ),
      );
    }
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
    _symptoms.dispose();
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
        title: const Text('Book appointment',
            style: TextStyle(
                fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Submit booking request',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
          children: [
            _sectionTitle('Doctor', Icons.medical_information_outlined),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFE8F0FE),
                      child: Icon(Icons.person, color: accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.doctorName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins')),
                          Text(widget.doctorSpecialty,
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            _sectionTitle('Personal details', Icons.badge_outlined),
            TextFormField(
              controller: _name,
              decoration: _dec('Full name *'),
              textCapitalization: TextCapitalization.words,
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
                    decoration: _dec('Weight (kg)', hint: 'e.g. 70'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _height,
                    decoration: _dec('Height (cm)', hint: 'e.g. 170'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _sectionTitle('Contact', Icons.contact_phone_outlined),
            TextFormField(
              controller: _phone,
              decoration: _dec('Mobile number *'),
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
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              decoration: _dec('Full address *'),
              maxLines: 2,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            _sectionTitle('Medical overview', Icons.health_and_safety_outlined),
            TextFormField(
              controller: _medicalHistory,
              decoration: _dec('Past conditions / medical history',
                  hint: 'Surgeries, chronic illness…'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _medications,
              decoration:
                  _dec('Current medications', hint: 'Name & dose if known'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _allergies,
              decoration: _dec('Allergies', hint: 'Drugs, food, latex…'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lastVisit,
              decoration: _dec('Last visit to any doctor (optional)',
                  hint: 'Approx. date or clinic'),
            ),
            const SizedBox(height: 20),
            _sectionTitle('Appointment', Icons.event_available_outlined),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _visitType,
              decoration: _dec('Visit type'),
              items: _visitTypes
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _visitType = v ?? _visitType),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(
                _preferredDate == null
                    ? 'Preferred date *'
                    : '${_preferredDate!.day}/${_preferredDate!.month}/${_preferredDate!.year}',
              ),
            ),
            const SizedBox(height: 12),
            if (_preferredDate != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select slot *',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_slotsLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_slotsForSelectedDate.isEmpty)
                Text(
                  'No slots available for selected date.',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _slotsForSelectedDate.map((slotData) {
                    final slot = slotData.label;
                  final isBooked = slotData.isBooked;
                  final isSelected = _selectedSlot == slot;
                  return ChoiceChip(
                    label: Text(isBooked ? '$slot (Booked)' : slot),
                    selected: isSelected,
                    onSelected: isBooked
                        ? null
                        : (selected) {
                            if (!selected) return;
                            setState(() => _selectedSlot = slot);
                          },
                    selectedColor: const Color(0xFF6B9AC4).withValues(alpha: 0.2),
                    disabledColor: Colors.grey.shade200,
                    labelStyle: TextStyle(
                      color: isBooked
                          ? Colors.grey
                          : (isSelected ? const Color(0xFF6B9AC4) : Colors.black87),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF6B9AC4)
                            : (isBooked ? Colors.grey.shade300 : Colors.transparent),
                      ),
                    ),
                    backgroundColor: Colors.grey.shade100,
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _symptoms,
              decoration: _dec('Reason for visit / symptoms *',
                  hint: 'Describe what you need help with'),
              maxLines: 4,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Icon(icon, size: 22, color: const Color(0xFF6B9AC4)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}
