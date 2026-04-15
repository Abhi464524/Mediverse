import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mediverse/feature/doctorPages/model/patient_model.dart';
import 'package:mediverse/feature/doctorPages/model/appointment_model.dart';
import 'package:mediverse/feature/doctorPages/controller/patient_controller.dart';
import 'package:mediverse/common/services/storage_service.dart';
import 'package:mediverse/feature/doctorPages/controller/emergency_appointments_controller.dart';

class EditPatientDetailsPage extends StatefulWidget {
  final NewPatientResponse patient;
  final AppointmentModel? appointment;

  const EditPatientDetailsPage({
    super.key,
    required this.patient,
    this.appointment,
  });

  @override
  State<EditPatientDetailsPage> createState() => _EditPatientDetailsPageState();
}

class _EditPatientDetailsPageState extends State<EditPatientDetailsPage> {
  final PatientController _controller = Get.find<PatientController>();
  final EmergencyAppointmentsController _emergencyController = Get.put(EmergencyAppointmentsController());

  bool get _isEmergency =>
      (widget.patient.appointment?.symptoms ?? '')
          .toLowerCase()
          .contains('emergency');

  Color get _accent =>
      _isEmergency ? const Color(0xFFE53935) : const Color(0xFF6A9C89);
  Color get _accentLight =>
      _isEmergency ? const Color(0xFFFFCDD2) : const Color(0xFFC4DAD2);
  Color get _accentBg =>
      _isEmergency ? const Color(0xFFFFF5F5) : const Color(0xFFF8FBF9);

  // ── Contact ──
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;

  // ── Medical History ──
  late final TextEditingController _historyCtrl;
  late final TextEditingController _medicationsCtrl;
  late final TextEditingController _allergiesCtrl;
  late final TextEditingController _lastVisitCtrl;

  // ── Current Visit ──
  late final TextEditingController _symptomsCtrl;
  late final TextEditingController _diagnosisCtrl;

  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate from passed patient model
    _phoneCtrl = TextEditingController(
        text: widget.patient.contact?.phone ?? '');
    _emailCtrl = TextEditingController(
        text: widget.patient.contact?.email ?? '');
    _addressCtrl = TextEditingController(
        text: widget.patient.contact?.address ?? '');
    _historyCtrl = TextEditingController(
        text: widget.patient.medicalHistory?.historyNotes ?? '');
    _medicationsCtrl = TextEditingController(
        text: widget.patient.medicalHistory?.currentMedications ?? '');
    _allergiesCtrl = TextEditingController(
        text: widget.patient.medicalHistory?.allergies ?? '');
    _lastVisitCtrl = TextEditingController(
        text: widget.patient.medicalHistory?.lastVisitDate ?? '');
    _symptomsCtrl = TextEditingController(
        text: widget.patient.appointment?.symptoms ?? '');
    _diagnosisCtrl = TextEditingController(
        text: widget.patient.appointment?.diagnosis ?? '');

    // Override with any locally persisted edits
    _loadPersistedDetails();
  }

  Future<void> _loadPersistedDetails() async {
    try {
      final storage = await StorageService.getInstance();
      final saved =
          storage.getPatientDetails(widget.patient.patientId ?? '');
      if (saved == null) return;
      setState(() {
        if (saved['phone'] != null) _phoneCtrl.text = saved['phone']!;
        if (saved['email'] != null) _emailCtrl.text = saved['email']!;
        if (saved['address'] != null) _addressCtrl.text = saved['address']!;
        if (saved['medicalHistory'] != null)
          _historyCtrl.text = saved['medicalHistory']!;
        if (saved['currentMedications'] != null)
          _medicationsCtrl.text = saved['currentMedications']!;
        if (saved['allergies'] != null)
          _allergiesCtrl.text = saved['allergies']!;
        if (saved['lastVisit'] != null)
          _lastVisitCtrl.text = saved['lastVisit']!;
        if (saved['symptoms'] != null) _symptomsCtrl.text = saved['symptoms']!;
        if (saved['diagnosis'] != null)
          _diagnosisCtrl.text = saved['diagnosis']!;
      });
    } catch (_) {}
  }

  Future<void> _saveAll() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'contact': {
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
      },
      'medical_history': {
        'history_notes': _historyCtrl.text.trim(),
        'current_medications': _medicationsCtrl.text.trim(),
        'allergies': _allergiesCtrl.text.trim(),
        'last_visit_date': _lastVisitCtrl.text.trim(),
      },
      'appointment': {
        'symptoms': _symptomsCtrl.text.trim(),
        'diagnosis': _diagnosisCtrl.text.trim(),
      },
    };

    setState(() => _isSaving = true);

    bool success = false;
    final patientId = widget.patient.patientId ?? '';

    try {
      success = await _controller.updatePatient(patientId, data);
      
      // Also update the appointment object
      if (success && widget.appointment != null) {
        final appointmentData = {
          'id': widget.appointment!.id,
          'doctorId': widget.patient.createdBy,
          'patientName': widget.appointment!.patientName,
          'phone': _phoneCtrl.text.trim(),
          'time': widget.appointment!.time,
          'date': widget.appointment!.date,
          'diagnosis': _diagnosisCtrl.text.trim(),
          'status': widget.appointment!.status,
          'patient': data, // Pass the newly updated details as the inner object
        };
        
        if (_isEmergency) {
           appointmentData['severity'] = 'Emergency'; 
           await _emergencyController.updateEmergencyAppointment(appointmentData);
        } else {
           await _controller.updateAppointment(appointmentData);
        }
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }

    if (!mounted) return;

    if (success) {
      // Persist locally so detail view reflects changes immediately
      try {
        final storage = await StorageService.getInstance();
        await storage.savePatientDetails(patientId, {
          'phone': _phoneCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'address': _addressCtrl.text.trim(),
          'medicalHistory': _historyCtrl.text.trim(),
          'currentMedications': _medicationsCtrl.text.trim(),
          'allergies': _allergiesCtrl.text.trim(),
          'lastVisit': _lastVisitCtrl.text.trim(),
          'symptoms': _symptomsCtrl.text.trim(),
          'diagnosis': _diagnosisCtrl.text.trim(),
        });
      } catch (_) {}

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Patient details updated successfully'),
          backgroundColor: _accent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Get.back(result: true); // signal caller to refresh
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Failed to update: ${_controller.error.value}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _historyCtrl.dispose();
    _medicationsCtrl.dispose();
    _allergiesCtrl.dispose();
    _lastVisitCtrl.dispose();
    _symptomsCtrl.dispose();
    _diagnosisCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _accentBg,
      appBar: AppBar(
        title: Text(
          'Edit Patient Details',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
              height: 1, color: Colors.grey.shade200, thickness: 1),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient name banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white.withOpacity(0.25),
                      child: Icon(Icons.person,
                          color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.patient.profile?.name ?? 'Patient',
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.patient.appointment?.diagnosis ??
                                'No diagnosis',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontFamily: 'Poppins',
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Contact Information ──
              _buildSection(
                title: 'Contact Information',
                icon: Icons.contact_mail_outlined,
                children: [
                  _buildField(
                    controller: _phoneCtrl,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  _buildField(
                    controller: _emailCtrl,
                    label: 'Email Address',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  _buildField(
                    controller: _addressCtrl,
                    label: 'Address',
                    icon: Icons.location_on_outlined,
                    maxLines: 2,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Medical History ──
              _buildSection(
                title: 'Medical History',
                icon: Icons.medical_services_outlined,
                children: [
                  _buildField(
                    controller: _historyCtrl,
                    label: 'History Notes',
                    icon: Icons.history_outlined,
                    maxLines: 3,
                  ),
                  _buildField(
                    controller: _medicationsCtrl,
                    label: 'Current Medications',
                    icon: Icons.medication_outlined,
                    maxLines: 2,
                  ),
                  _buildField(
                    controller: _allergiesCtrl,
                    label: 'Allergies',
                    icon: Icons.warning_amber_outlined,
                  ),
                  _buildField(
                    controller: _lastVisitCtrl,
                    label: 'Last Visit Date',
                    icon: Icons.calendar_today_outlined,
                    hint: 'e.g. 2024-01-15',
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Current Visit ──
              _buildSection(
                title: 'Current Visit',
                icon: Icons.local_hospital_outlined,
                children: [
                  _buildField(
                    controller: _symptomsCtrl,
                    label: 'Symptoms',
                    icon: Icons.sick_outlined,
                    maxLines: 2,
                  ),
                  _buildField(
                    controller: _diagnosisCtrl,
                    label: 'Diagnosis',
                    icon: Icons.monitor_heart_outlined,
                    maxLines: 2,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomSheet: _buildSaveButton(),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _accent, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          Divider(
              height: 24,
              color: _accentLight.withOpacity(0.5),
              thickness: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: _accent, size: 20),
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontFamily: 'Poppins',
            fontSize: 13,
          ),
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontFamily: 'Poppins',
            fontSize: 13,
          ),
          filled: true,
          fillColor: _accentBg,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _accentLight, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: _accentLight.withOpacity(0.6), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _accent, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveAll,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'Save All Changes',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
