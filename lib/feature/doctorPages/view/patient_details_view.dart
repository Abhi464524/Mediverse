import 'package:mediverse/feature/doctorPages/model/patient_model.dart';
import 'package:mediverse/feature/doctorPages/model/appointment_model.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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
  String notes = "";
  TextEditingController? _notesController;
  late String _selectedStatus;
  List<String> _savedNotes = <String>[];
  List<Map<String, String>> _attachments = <Map<String, String>>[];

  // Editable fields controllers
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _medicalHistoryController;
  late TextEditingController _currentMedicationsController;
  late TextEditingController _allergiesController;
  late TextEditingController _lastVisitController;
  late TextEditingController _appointmentTimeController;
  late TextEditingController _symptomsController;
  late TextEditingController _diagnosisController;
  static const String _hardcodedPhoneNumber = "+91 7900464524";

  TextEditingController get notesController {
    _notesController ??= TextEditingController();
    return _notesController!;
  }

  Future<void> _callHardcodedNumber() async {
    await launchCallWithLoader(context, _hardcodedPhoneNumber);
  }

  Widget _buildStatusCard() {
    bool hasPassed = _hasAppointmentPassed;
    List<String> options = ['Scheduled', 'Done', 'Not Visited'];

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline,
                  color: const Color(0xFF6A9C89), size: 20),
              SizedBox(width: 8),
              Text(
                "Appointment Status",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: 'Poppins',
                ),
              ),
              if (hasPassed && _selectedStatus == 'Scheduled')
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 16),
                ),
            ],
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: options.map((status) {
              bool isSelected = _selectedStatus == status;
              Color activeColor = status == 'Done'
                  ? const Color(0xFF6A9C89)
                  : (status == 'Not Visited'
                      ? Colors.redAccent
                      : const Color(0xFFC4DAD2));

              String label = status;
              if (status == 'Scheduled' && hasPassed) {
                label = "Scheduled (Action Required)";
              }

              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedStatus = status);
                    if (widget.appointment != null) {
                      StorageService.getInstance().then(
                        (storage) => storage.saveAppointmentStatus(
                          widget.appointment!.id,
                          status,
                        ),
                      );
                    }
                  }
                },
                selectedColor: activeColor.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected ? activeColor : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontFamily: 'Poppins',
                ),
                backgroundColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? activeColor : Colors.transparent,
                  ),
                ),
              );
            }).toList(),
          ),
          if (hasPassed && _selectedStatus == 'Scheduled')
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "Appointment time has passed. Please update status.",
                style: TextStyle(
                    color: Colors.orange.shade800,
                    fontSize: 11,
                    fontFamily: 'Poppins'),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    String initialStatus = widget.appointment?.status ?? 'Scheduled';
    if (initialStatus == 'Pending') initialStatus = 'Scheduled';
    _selectedStatus = initialStatus;

    // Initialize editable controllers from the current patient/appointment data
    _phoneController = TextEditingController(text: widget.patient.contact?.phone ?? "");
    _emailController = TextEditingController(text: widget.patient.contact?.email ?? "");
    _addressController = TextEditingController(text: widget.patient.contact?.address ?? "");
    _medicalHistoryController =
        TextEditingController(text: widget.patient.medicalHistory?.historyNotes ?? "");
    _currentMedicationsController =
        TextEditingController(text: widget.patient.medicalHistory?.currentMedications ?? "");
    _allergiesController =
        TextEditingController(text: widget.patient.medicalHistory?.allergies ?? "");
    _lastVisitController =
        TextEditingController(text: widget.patient.medicalHistory?.lastVisitDate ?? "");
    _appointmentTimeController =
        TextEditingController(text: widget.patient.appointment?.scheduledTime ?? "N/A");
    _symptomsController = TextEditingController(text: widget.patient.appointment?.symptoms ?? "");
    _diagnosisController =
        TextEditingController(text: widget.patient.appointment?.diagnosis ?? "");

    // Now load any persisted values that override the defaults.
    _loadPersistedStatus();
    _loadSavedNotes();
    _loadAttachments();
    _loadEditableDetails();
  }

  Future<void> _loadSavedNotes() async {
    try {
      final storage = await StorageService.getInstance();
      final notes = storage.getPatientNotes(widget.patient.patientId ?? "");
      setState(() {
        _savedNotes = notes;
      });
    } catch (_) {
      // Ignore storage errors.
    }
  }

  Future<void> _addNote() async {
    final text = notesController.text.trim();
    if (text.isEmpty) return;
    try {
      final storage = await StorageService.getInstance();
      await storage.addPatientNote(widget.patient.patientId ?? "", text);
      notesController.clear();
      setState(() {
        notes = "";
      });
      await _loadSavedNotes();
    } catch (_) {
      // Ignore storage errors.
    }
  }

  Future<void> _loadEditableDetails() async {
    try {
      final storage = await StorageService.getInstance();
      final details = storage.getPatientDetails(widget.patient.patientId ?? "");
      if (details == null) return;
      setState(() {
        _phoneController.text = details['phone'] ?? _phoneController.text;
        _emailController.text = details['email'] ?? _emailController.text;
        _addressController.text = details['address'] ?? _addressController.text;
        _medicalHistoryController.text =
            details['medicalHistory'] ?? _medicalHistoryController.text;
        _currentMedicationsController.text =
            details['currentMedications'] ?? _currentMedicationsController.text;
        _allergiesController.text =
            details['allergies'] ?? _allergiesController.text;
        _lastVisitController.text =
            details['lastVisit'] ?? _lastVisitController.text;
        _appointmentTimeController.text =
            details['appointmentTime'] ?? _appointmentTimeController.text;
        _symptomsController.text =
            details['symptoms'] ?? _symptomsController.text;
        _diagnosisController.text =
            details['diagnosis'] ?? _diagnosisController.text;
      });
    } catch (_) {
      // Ignore storage errors.
    }
  }

  Future<void> _saveEditableDetails() async {
    try {
      final storage = await StorageService.getInstance();
      final ok = await storage.savePatientDetails(widget.patient.patientId ?? "", {
        'phone': _phoneController.text,
        'email': _emailController.text,
        'address': _addressController.text,
        'medicalHistory': _medicalHistoryController.text,
        'currentMedications': _currentMedicationsController.text,
        'allergies': _allergiesController.text,
        'lastVisit': _lastVisitController.text,
        'appointmentTime': _appointmentTimeController.text,
        'symptoms': _symptomsController.text,
        'diagnosis': _diagnosisController.text,
      });
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Patient details saved")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to save details")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving details: $e")),
      );
    }
  }

  Future<void> _loadAttachments() async {
    try {
      final storage = await StorageService.getInstance();
      final files = storage.getPatientFiles(widget.patient.patientId ?? "");
      setState(() {
        _attachments = files;
      });
    } catch (_) {
      // Ignore errors.
    }
  }

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final path = file.path;
      if (path == null) return;
      final name = file.name;

      final storage = await StorageService.getInstance();
      final ok = await storage.addPatientFile(widget.patient.patientId ?? "", name, path);
      if (!ok) return;
      await _loadAttachments();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Report uploaded: $name")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to pick file: $e")),
      );
    }
  }

  String _formatNoteTimestamp(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return "$y-$m-$d $hh:$mm";
  }

  ({String note, String? timestampLabel}) _parseStoredNote(String raw) {
    // New format: "ISO_TIMESTAMP|note"
    final idx = raw.indexOf('|');
    if (idx <= 0 || idx == raw.length - 1) {
      // Old format (no timestamp)
      return (note: raw, timestampLabel: null);
    }
    final ts = raw.substring(0, idx);
    final note = raw.substring(idx + 1);
    try {
      final dt = DateTime.parse(ts);
      return (note: note, timestampLabel: _formatNoteTimestamp(dt));
    } catch (_) {
      return (note: note, timestampLabel: ts);
    }
  }

  Future<void> _loadPersistedStatus() async {
    if (widget.appointment == null) return;
    try {
      final storage = await StorageService.getInstance();
      final persisted = storage.getAppointmentStatus(widget.appointment!.id);
      if (persisted != null && persisted.isNotEmpty) {
        String status = persisted;
        if (status == 'Pending') status = 'Scheduled';
        setState(() {
          _selectedStatus = status;
        });
      }
    } catch (_) {
      // Ignore storage errors; keep default status.
    }
  }

  DateTime _parseTime(String timeStr) {
    if (timeStr.isEmpty) return DateTime.now();
    final now = DateTime.now();
    try {
      final parts = timeStr.trim().split(' ');
      if (parts.length < 2) return now;
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      final amPm = parts[1].toUpperCase();

      if (amPm == "PM" && hour != 12) hour += 12;
      if (amPm == "AM" && hour == 12) hour = 0;

      return DateTime(now.year, now.month, now.day, hour, minute);
    } catch (e) {
      return now;
    }
  }

  bool get _hasAppointmentPassed {
    if (widget.appointment == null) return false;
    final appTime = _parseTime(widget.appointment!.time);
    // Adding 15 mins buffer or just compare strictly? Strict for now.
    return DateTime.now().isAfter(appTime);
  }

  @override
  void dispose() {
    _notesController?.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _medicalHistoryController.dispose();
    _currentMedicationsController.dispose();
    _allergiesController.dispose();
    _lastVisitController.dispose();
    _appointmentTimeController.dispose();
    _symptomsController.dispose();
    _diagnosisController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF9), // Pale Mint
      appBar: AppBar(
        title: Text(
          "Patient Details",
          style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins'),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 100), // Space for extended AppBar
            _buildEnhancedHeader(),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  if (widget.appointment != null) ...[
                    _buildStatusCard(),
                    SizedBox(height: 24),
                  ],
                  _buildQuickStatsGrid(),
                  SizedBox(height: 24),
                  _buildSectionCard(
                    title: "Contact Information",
                    icon: Icons.contact_mail_outlined,
                    children: [
                      _buildEditableInfoRow(
                          Icons.phone, "Phone", _phoneController),
                      _buildEditableInfoRow(
                          Icons.email, "Email", _emailController),
                      _buildEditableInfoRow(
                          Icons.location_on, "Address", _addressController),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _saveEditableDetails,
                          icon: Icon(
                            Icons.save,
                            size: 18,
                            color: const Color(0xFF6A9C89),
                          ),
                          label: Text(
                            "Save Details",
                            style: TextStyle(
                              color: const Color(0xFF6A9C89),
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  _buildSectionCard(
                    title: "Medical Overview",
                    icon: Icons.medical_services_outlined,
                    children: [
                      _buildEditableInfoRow(Icons.history, "Medical History",
                          _medicalHistoryController),
                      _buildEditableInfoRow(Icons.medication,
                          "Current Medications", _currentMedicationsController),
                      _buildEditableInfoRow(Icons.warning_amber_rounded,
                          "Allergies", _allergiesController),
                      _buildEditableInfoRow(Icons.calendar_today, "Last Visit",
                          _lastVisitController),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.attach_file,
                              size: 18, color: const Color(0xFF6A9C89)),
                          SizedBox(width: 8),
                          Text(
                            "Reports / Attachments",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Spacer(),
                          TextButton.icon(
                            onPressed: _pickAndUploadFile,
                            icon: Icon(Icons.cloud_upload,
                                size: 18, color: const Color(0xFF6A9C89)),
                            label: Text(
                              "Upload",
                              style: TextStyle(
                                color: const Color(0xFF6A9C89),
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_attachments.isNotEmpty) ...[
                        SizedBox(height: 12),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: const Color(0xFFC4DAD2).withOpacity(0.7),
                        ),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: _attachments.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 8,
                            color: const Color(0xFFC4DAD2).withOpacity(0.5),
                          ),
                          itemBuilder: (context, index) {
                            final file = _attachments[index];
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
                                color: const Color(0xFF6A9C89),
                              ),
                              title: Text(
                                name,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: ts.isNotEmpty
                                  ? Text(
                                      ts,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    )
                                  : null,
                              onTap: path.isNotEmpty
                                  ? () => OpenFilex.open(path)
                                  : null,
                            );
                          },
                        ),
                      ],
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _saveEditableDetails,
                          icon: Icon(
                            Icons.save,
                            size: 18,
                            color: const Color(0xFF6A9C89),
                          ),
                          label: Text(
                            "Save Details",
                            style: TextStyle(
                              color: const Color(0xFF6A9C89),
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  _buildSectionCard(
                    title: "Current Visit",
                    icon: Icons.local_hospital_outlined,
                    children: [
                      _buildEditableInfoRow(Icons.access_time,
                          "Appointment Time", _appointmentTimeController),
                      _buildEditableInfoRow(
                          Icons.sick_outlined, "Symptoms", _symptomsController),
                      _buildEditableInfoRow(Icons.monitor_heart_outlined,
                          "Diagnosis", _diagnosisController),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _saveEditableDetails,
                          icon: Icon(
                            Icons.save,
                            size: 18,
                            color: const Color(0xFF6A9C89),
                          ),
                          label: Text(
                            "Save Details",
                            style: TextStyle(
                              color: const Color(0xFF6A9C89),
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  _buildDoctorNotes(),
                  SizedBox(height: 100), // Space for bottom buttons
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomActions(),
    );
  }

  Widget _buildEnhancedHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFC4DAD2).withOpacity(0.3), // Soft Sage Light
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6A9C89)
                      .withOpacity(0.2), // Sage Green Shadow
                  blurRadius: 15,
                  offset: Offset(0, 5),
                )
              ],
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFFC4DAD2),
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
          ),
          SizedBox(height: 16),
          Text(
            widget.patient.profile?.name ?? "Unknown",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF6A9C89), // Sage Green
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.patient.appointment?.diagnosis ?? "No diagnosis",
              style: TextStyle(
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

  Widget _buildQuickStatsGrid() {
    return Row(
      children: [
        _buildStatCard("Age", widget.patient.profile?.age ?? "N/A", Icons.cake),
        SizedBox(width: 12),
        _buildStatCard("Blood", widget.patient.profile?.bloodGroup ?? "N/A", Icons.bloodtype),
        SizedBox(width: 12),
        _buildStatCard(
            "Gender", widget.patient.profile?.gender ?? "N/A", Icons.male), // Simplified icon
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFC4DAD2).withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF6A9C89), size: 24),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
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

  Widget _buildSectionCard(
      {required String title,
      required IconData icon,
      required List<Widget> children}) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF6A9C89), size: 20),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          Divider(height: 24, color: const Color(0xFFF2F7F5)),
          ...children,
        ],
      ),
    );
  }

  Widget _buildEditableInfoRow(
      IconData icon, String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade400),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontFamily: 'Poppins',
                  ),
                ),
                TextField(
                  controller: controller,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                    border: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: const Color(0xFF6A9C89), width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorNotes() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note, color: const Color(0xFF6A9C89), size: 24),
              SizedBox(width: 8),
              Text(
                "Doctor's Notes",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: 'Poppins',
                ),
              ),
              Spacer(),
              TextButton.icon(
                onPressed: _addNote,
                icon:
                    Icon(Icons.save, color: const Color(0xFF6A9C89), size: 18),
                label: Text(
                  "Add",
                  style: TextStyle(
                    color: const Color(0xFF6A9C89),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (_savedNotes.isNotEmpty) ...[
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBF9),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0xFFC4DAD2).withOpacity(0.5)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                padding: EdgeInsets.all(12),
                itemCount: _savedNotes.length,
                separatorBuilder: (_, __) => Divider(
                  height: 12,
                  color: const Color(0xFFC4DAD2).withOpacity(0.4),
                ),
                itemBuilder: (context, index) {
                  final parsed = _parseStoredNote(_savedNotes[index]);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (parsed.timestampLabel != null)
                        Text(
                          parsed.timestampLabel!,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      Text(
                        "• ${parsed.note}",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(height: 12),
          ],
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FBF9), // Pale Mint
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: const Color(0xFFC4DAD2).withOpacity(0.5)),
            ),
            child: TextField(
              controller: notesController,
              maxLines: 4,
              onChanged: (value) => setState(() => notes = value),
              decoration: InputDecoration(
                hintText: "Write a new note, then tap Add...",
                hintStyle: TextStyle(
                    color: Colors.grey.shade400, fontFamily: 'Poppins'),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -5),
          )
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: _buildActionButton(
                "Call",
                Icons.call,
                Colors.white,
                const Color(0xFF6A9C89), // Sage Green
                _callHardcodedNumber,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                "Message",
                Icons.message,
                const Color(0xFF6A9C89), // Sage Green
                Colors.white,
                () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Opening message..."))),
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
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: bgColor == Colors.white
              ? BorderSide(color: const Color(0xFF6A9C89))
              : BorderSide.none,
        ),
        elevation: 0,
      ),
    );
  }
}
