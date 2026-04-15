import 'package:mediverse/feature/doctorPages/model/patient_model.dart';
import 'package:mediverse/feature/doctorPages/model/appointment_model.dart';
import 'package:mediverse/feature/doctorPages/view/edit_patient_details_view.dart';
import 'package:mediverse/feature/doctorPages/view/digital_prescription_view.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import '../../../common/services/storage_service.dart';
import '../../../common/utils/phone_launcher.dart' show launchCallWithLoader;

class PatientDetails extends StatefulWidget {
  final NewPatientResponse patient;
  final AppointmentModel? appointment;

  const PatientDetails({
    super.key,
    required this.patient,
    this.appointment,
  });

  @override
  State<PatientDetails> createState() => _PatientDetailsState();
}

class _PatientDetailsState extends State<PatientDetails> {
  late String _selectedStatus;

  bool get _isEmergency =>
      (widget.patient.appointment?.symptoms ?? '')
          .toLowerCase()
          .contains('emergency');

  Color get _accentColor =>
      _isEmergency ? const Color(0xFFE53935) : const Color(0xFF6A9C89);
  Color get _accentLight =>
      _isEmergency ? const Color(0xFFFFCDD2) : const Color(0xFFC4DAD2);
  Color get _accentBg =>
      _isEmergency ? const Color(0xFFFFF5F5) : const Color(0xFFF8FBF9);

  List<Map<String, String>> _attachments = [];

  // Local overrides loaded from storage (set by the Edit page)
  Map<String, String?> _persisted = {};

  static const String _hardcodedPhoneNumber = "+91 7900464524";



  // ── helpers ──────────────────────────────────────────────────────────
  String _val(String? stored, String? modelVal) =>
      (stored != null && stored.isNotEmpty) ? stored : (modelVal ?? '—');

  Future<void> _callHardcodedNumber() async {
    await launchCallWithLoader(context, _hardcodedPhoneNumber);
  }

  // ── lifecycle ────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    String initialStatus = widget.appointment?.status ?? 'Scheduled';
    if (initialStatus == 'Pending') initialStatus = 'Scheduled';
    _selectedStatus = initialStatus;

    _loadPersistedStatus();
    _loadAttachments();
    _loadPersistedDetails();
  }

  Future<void> _loadPersistedDetails() async {
    try {
      final storage = await StorageService.getInstance();
      final details =
          storage.getPatientDetails(widget.patient.patientId ?? '');
      if (details != null) {
        setState(() => _persisted = details);
      }
    } catch (_) {}
  }



  Future<void> _loadAttachments() async {
    try {
      final storage = await StorageService.getInstance();
      final files =
          storage.getPatientFiles(widget.patient.patientId ?? '');
      setState(() => _attachments = files);
    } catch (_) {}
  }

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: false);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final path = file.path;
      if (path == null) return;

      final storage = await StorageService.getInstance();
      final ok = await storage.addPatientFile(
          widget.patient.patientId ?? '', file.name, path);
      if (!ok) return;
      await _loadAttachments();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Report uploaded: ${file.name}")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to pick file: $e")));
    }
  }

  Future<void> _loadPersistedStatus() async {
    if (widget.appointment == null) return;
    try {
      final storage = await StorageService.getInstance();
      final persisted =
          storage.getAppointmentStatus(widget.appointment!.id);
      if (persisted != null && persisted.isNotEmpty) {
        String status = persisted;
        if (status == 'Pending') status = 'Scheduled';
        setState(() => _selectedStatus = status);
      }
    } catch (_) {}
  }



  DateTime _parseTime(String timeStr) {
    if (timeStr.isEmpty) return DateTime.now();
    final now = DateTime.now();
    try {
      final parts = timeStr.trim().split(' ');
      if (parts.length < 2) return now;
      final tp = parts[0].split(':');
      int hour = int.parse(tp[0]);
      int minute = int.parse(tp[1]);
      final amPm = parts[1].toUpperCase();
      if (amPm == 'PM' && hour != 12) hour += 12;
      if (amPm == 'AM' && hour == 12) hour = 0;
      return DateTime(now.year, now.month, now.day, hour, minute);
    } catch (_) {
      return now;
    }
  }

  bool get _hasAppointmentPassed {
    if (widget.appointment == null) return false;
    return DateTime.now().isAfter(_parseTime(widget.appointment!.time));
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ── Navigate to edit page ─────────────────────────────────────────────
  Future<void> _openEditPage() async {
    final result = await Get.to(() => EditPatientDetailsPage(
          patient: widget.patient,
          appointment: widget.appointment,
        ));
    if (result == true) {
      // Refresh persisted details after successful save
      await _loadPersistedDetails();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _accentBg,
      appBar: AppBar(
        title: Text(
          _isEmergency ? 'Emergency Patient' : 'Patient Details',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            tooltip: 'Edit Details',
            icon: Icon(Icons.edit_outlined, color: _accentColor),
            onPressed: _openEditPage,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 100),
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (widget.appointment != null) ...[
                    _buildStatusCard(),
                    const SizedBox(height: 24),
                  ],
                  _buildQuickStatsGrid(),
                  const SizedBox(height: 24),
                  _buildReadOnlySection(
                    title: 'Contact Information',
                    icon: Icons.contact_mail_outlined,
                    rows: [
                      _InfoRow(Icons.phone_outlined, 'Phone',
                          _val(_persisted['phone'], widget.patient.contact?.phone)),
                      _InfoRow(Icons.email_outlined, 'Email',
                          _val(_persisted['email'], widget.patient.contact?.email)),
                      _InfoRow(Icons.location_on_outlined, 'Address',
                          _val(_persisted['address'], widget.patient.contact?.address)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildReadOnlySection(
                    title: 'Medical History',
                    icon: Icons.medical_services_outlined,
                    rows: [
                      _InfoRow(Icons.history_outlined, 'History Notes',
                          _val(_persisted['medicalHistory'],
                              widget.patient.medicalHistory?.historyNotes)),
                      _InfoRow(Icons.medication_outlined, 'Current Medications',
                          _val(_persisted['currentMedications'],
                              widget.patient.medicalHistory?.currentMedications)),
                      _InfoRow(Icons.warning_amber_outlined, 'Allergies',
                          _val(_persisted['allergies'],
                              widget.patient.medicalHistory?.allergies)),
                      _InfoRow(Icons.calendar_today_outlined, 'Last Visit',
                          _val(_persisted['lastVisit'],
                              widget.patient.medicalHistory?.lastVisitDate)),
                    ],
                    footer: _buildAttachmentsSection(),
                  ),
                  const SizedBox(height: 20),
                  _buildReadOnlySection(
                    title: 'Current Visit',
                    icon: Icons.local_hospital_outlined,
                    rows: [
                      _InfoRow(Icons.sick_outlined, 'Symptoms',
                          _val(_persisted['symptoms'],
                              widget.patient.appointment?.symptoms)),
                      _InfoRow(Icons.monitor_heart_outlined, 'Diagnosis',
                          _val(_persisted['diagnosis'],
                              widget.patient.appointment?.diagnosis)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildDigitalPrescriptionBox(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomActions(),
    );
  }

  // ── Section Widgets ───────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _accentLight.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: _accentColor.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: _accentLight,
              child: const Icon(Icons.person, size: 60, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.patient.profile?.name ?? 'Unknown',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _accentColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _val(_persisted['diagnosis'],
                  widget.patient.appointment?.diagnosis),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final bool hasPassed = _hasAppointmentPassed;
    final options = ['Scheduled', 'Done', 'Not Visited'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline, color: _accentColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Appointment Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: 'Poppins',
                ),
              ),
              if (hasPassed && _selectedStatus == 'Scheduled')
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 16),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: options.map((status) {
              final isSelected = _selectedStatus == status;
              final Color activeColor = status == 'Done'
                  ? _accentColor
                  : (status == 'Not Visited' ? Colors.redAccent : _accentLight);
              final String label = (status == 'Scheduled' && hasPassed)
                  ? 'Scheduled (Action Required)'
                  : status;
              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedStatus = status);
                    if (widget.appointment != null) {
                      StorageService.getInstance().then((s) =>
                          s.saveAppointmentStatus(
                              widget.appointment!.id, status));
                    }
                  }
                },
                selectedColor: activeColor.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected ? activeColor : Colors.grey,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  fontFamily: 'Poppins',
                ),
                backgroundColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: isSelected ? activeColor : Colors.transparent),
                ),
              );
            }).toList(),
          ),
          if (hasPassed && _selectedStatus == 'Scheduled')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Appointment time has passed. Please update status.',
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontSize: 11,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsGrid() {
    return Row(
      children: [
        _buildStatCard('Age', widget.patient.profile?.age ?? 'N/A', Icons.cake),
        const SizedBox(width: 12),
        _buildStatCard(
            'Blood', widget.patient.profile?.bloodGroup ?? 'N/A', Icons.bloodtype),
        const SizedBox(width: 12),
        _buildStatCard(
            'Gender', widget.patient.profile?.gender ?? 'N/A', Icons.male),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _accentLight.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: _accentColor, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
                fontFamily: 'Poppins',
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlySection({
    required String title,
    required IconData icon,
    required List<_InfoRow> rows,
    Widget? footer,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: _accentColor, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontFamily: 'Poppins',
              ),
            ),
          ]),
          Divider(height: 24, color: _accentLight.withOpacity(0.5)),
          ...rows.map((r) => _buildInfoRow(r.icon, r.label, r.value)),
          if (footer != null) ...[
            const SizedBox(height: 4),
            footer,
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '—' : value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.attach_file, size: 18, color: _accentColor),
            const SizedBox(width: 8),
            const Text(
              'Reports / Attachments',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _pickAndUploadFile,
              icon: Icon(Icons.cloud_upload, size: 18, color: _accentColor),
              label: Text(
                'Upload',
                style: TextStyle(
                  color: _accentColor,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (_attachments.isNotEmpty) ...[
          const SizedBox(height: 8),
          Divider(height: 1, color: _accentLight.withOpacity(0.7)),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: _attachments.length,
            separatorBuilder: (_, __) =>
                Divider(height: 8, color: _accentLight.withOpacity(0.5)),
            itemBuilder: (ctx, i) {
              final file = _attachments[i];
              final name = file['name'] ?? '';
              final ts = file['ts'] ?? '';
              final path = file['path'] ?? '';
              return ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(
                  name.toLowerCase().endsWith('.pdf')
                      ? Icons.picture_as_pdf
                      : Icons.insert_drive_file,
                  size: 20,
                  color: _accentColor,
                ),
                title: Text(name,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                subtitle: ts.isNotEmpty
                    ? Text(ts,
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Colors.grey.shade600))
                    : null,
                onTap: path.isNotEmpty ? () => OpenFilex.open(path) : null,
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildDigitalPrescriptionBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.picture_as_pdf_outlined, color: _accentColor, size: 24),
              const SizedBox(width: 8),
              const Text(
                "Digital Prescription",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Generate or view the digital prescription for this patient's visit.",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Get.to(() => DigitalPrescriptionView(
                  patientId: widget.patient.patientId,
                  appointmentId: widget.appointment?.id,
                  initialPatientName: _val(_persisted['name'], widget.patient.profile?.name ?? widget.appointment?.patientName),
                  initialAge: _val(_persisted['age'], widget.patient.profile?.age),
                  initialGender: _val(_persisted['gender'], widget.patient.profile?.gender),
                  initialSymptoms: _val(_persisted['symptoms'], widget.patient.appointment?.symptoms),
                  initialDiagnosis: _val(_persisted['diagnosis'], widget.patient.appointment?.diagnosis),
                ));
              },
              icon: const Icon(Icons.file_open_rounded, size: 18, color: Colors.white),
              label: const Text(
                'Open Digital Rx',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Call',
                Icons.call,
                Colors.white,
                _accentColor,
                _callHardcodedNumber,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                'Message',
                Icons.message,
                _accentColor,
                Colors.white,
                () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening message...'))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color bgColor,
      Color textColor, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: textColor),
      label: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: bgColor == Colors.white
              ? BorderSide(color: _accentColor)
              : BorderSide.none,
        ),
        elevation: 0,
      ),
    );
  }
}

// ── Data class for table rows ─────────────────────────────────────────────
class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);
}
