import 'package:mediverse/feature/doctorPages/view/doctor_footer_view.dart';
import 'package:mediverse/feature/doctorPages/view/patient_details_view.dart';
import 'package:mediverse/feature/doctorPages/model/appointment_model.dart';
import 'package:mediverse/feature/doctorPages/model/patient_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import '../controller/patient_controller.dart';
import '../../../common/utils/phone_launcher.dart' show launchCallWithLoader;
import '../../../common/services/storage_service.dart';

class AppointmentsPage extends StatefulWidget {
  /// When true, show only today's appointments (e.g. when opened from "Today's Appointments" card).
  final bool showOnlyToday;

  /// When true, automatically open the "Add New Patient" dialog on startup.
  final bool showAddPatient;

  const AppointmentsPage({
    super.key,
    this.showOnlyToday = false,
    this.showAddPatient = false,
  });

  @override
  State<AppointmentsPage> createState() => AppointmentsPageState();
}

class AppointmentsPageState extends State<AppointmentsPage> {
  final PatientController _patientController = Get.put(PatientController());
  final Map<String, String> _persistedStatuses = {};
  static const String _hardcodedPhoneNumber = "+91 7900464524";
  static const List<String> _doctorSlots = <String>[
    '10:00 AM',
    '11:30 AM',
    '02:00 PM',
    '04:15 PM',
    '06:00 PM',
  ];

  Future<void> _callHardcodedNumber() async {
    await launchCallWithLoader(context, _hardcodedPhoneNumber);
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
    } catch (_) {
      return now;
    }
  }

  bool _hasAppointmentPassed(AppointmentModel app) {
    final appTime = _parseTime(app.time);
    return DateTime.now().isAfter(appTime);
  }

  @override
  void initState() {
    super.initState();
    _loadPersistedStatuses();
    if (widget.showAddPatient) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _addPatients();
      });
    }
  }

  Future<void> _loadPersistedStatuses() async {
    try {
      final storage = await StorageService.getInstance();
      for (final app in appointments) {
        String? status = storage.getAppointmentStatus(app.id);
        if (status == 'Pending') status = 'Scheduled';
        if (status != null && status.isNotEmpty) {
          _persistedStatuses[app.id] = status;
        } else if (_hasAppointmentPassed(app)) {
          // Default to Scheduled if time has passed and no explicit status saved.
          _persistedStatuses[app.id] = 'Scheduled';
        }
      }
      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      // Ignore storage errors; badges just won't show.
    }
  }

  // Using AppointmentModel
  final List<AppointmentModel> appointments = [
    AppointmentModel(
        id: '1',
        patientName: "Patient 1",
        time: "10:00 AM",
        diagnosis: "Derma"),
    AppointmentModel(
        id: '2',
        patientName: "Patient 2",
        time: "11:30 AM",
        diagnosis: "Derma"),
    AppointmentModel(
        id: '3',
        patientName: "Patient 3",
        time: "02:00 PM",
        diagnosis: "Derma"),
    AppointmentModel(
        id: '4',
        patientName: "Patient 4",
        time: "04:15 PM",
        diagnosis: "Derma"),
    AppointmentModel(
        id: '5',
        patientName: "Patient 5",
        time: "06:00 PM",
        diagnosis: "Derma"),
    AppointmentModel(
        id: '6',
        patientName: "Patient 6",
        time: "10:00 AM",
        diagnosis: "Derma"),
    AppointmentModel(
        id: '7',
        patientName: "Patient 7",
        time: "11:30 AM",
        diagnosis: "Derma"),
    AppointmentModel(
        id: '8',
        patientName: "Patient 8",
        time: "02:00 PM",
        diagnosis: "Derma"),
    AppointmentModel(
        id: '9',
        patientName: "Patient 9",
        time: "04:15 PM",
        diagnosis: "Derma"),
    AppointmentModel(
        id: '10',
        patientName: "Patient 10",
        time: "06:00 PM",
        diagnosis: "Derma"),
  ];

  void _addPatients() {
    TextEditingController nameController = TextEditingController();
    TextEditingController ageController = TextEditingController();
    TextEditingController genderController = TextEditingController();
    TextEditingController contactController = TextEditingController();
    TextEditingController diagnosisController = TextEditingController();
    String selectedSlot = '';

    showDialog(
        barrierColor:
            const Color(0xFFC4DAD2).withOpacity(0.5), // Soft Sage Accent
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
              backgroundColor: Colors.white,
              insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                    color: const Color(0xFFC4DAD2),
                    width: 1.5), // Soft Sage Accent
              ),
              title: Text(
                "Add New Patient",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              content: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDialogTextField(
                          nameController, "Patient Name", Icons.person),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                              child: _buildDialogTextField(
                                  ageController, "Age", Icons.calendar_today)),
                          SizedBox(width: 12),
                          Expanded(
                              child: _buildDialogTextField(
                                  genderController, "Gender", Icons.wc)),
                        ],
                      ),
                      SizedBox(height: 16),
                      _buildDialogTextField(
                          contactController, "Contact Number", Icons.phone),
                      SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Appointment Time Slot',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _doctorSlots.map((slot) {
                          final isSelected = selectedSlot == slot;
                          return ChoiceChip(
                            label: Text(
                              slot,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: const Color(0xFF6A9C89),
                            backgroundColor: const Color(0xFFF2F7F5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected
                                    ? const Color(0xFF6A9C89)
                                    : const Color(0xFFC4DAD2),
                              ),
                            ),
                            onSelected: (_) {
                              setDialogState(() {
                                selectedSlot = slot;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 16),
                      _buildDialogTextField(diagnosisController, "Diagnosis",
                          Icons.monitor_heart_outlined),
                      SizedBox(height: 24),
                      Obx(() => Row(
                        children: [
                          Expanded(
                            child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.grey,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text("Cancel",
                                    style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600))),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                                onPressed: _patientController.isLoading.value
                                    ? null
                                    : () async {
                                        if (nameController.text.isNotEmpty &&
                                            selectedSlot.isNotEmpty) {
                                          final newPatient = NewPatientResponse(
                                            patientId: DateTime.now()
                                                .millisecondsSinceEpoch
                                                .toString(),
                                            profile: Profile(
                                              name: nameController.text,
                                              age: ageController.text,
                                              gender: genderController.text,
                                            ),
                                            contact: Contact(
                                              phone: contactController.text,
                                            ),
                                            appointment: Appointment(
                                              scheduledTime: selectedSlot,
                                              diagnosis: diagnosisController.text,
                                            ),
                                          );

                                          final success = await _patientController
                                              .addPatient(newPatient);

                                          if (success) {
                                            setState(() {
                                              appointments.add(AppointmentModel(
                                                id: newPatient.patientId ?? '',
                                                patientName: newPatient.profile?.name ?? '',
                                                time: selectedSlot,
                                                diagnosis: newPatient.appointment?.diagnosis ?? '',
                                              ));
                                            });
                                            Navigator.pop(context);
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF6A9C89), // Sage Green
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                child: _patientController.isLoading.value
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text("Add",
                                        style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.bold))),
                          ),
                        ],
                      ))
                    ],
                  ),
                ),
              ),
            ),
        ));
  }

  Widget _buildDialogTextField(
      TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6A9C89), size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFFC4DAD2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFF6A9C89), width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: TextStyle(
            color: Colors.grey.shade600, fontFamily: 'Poppins', fontSize: 14),
      ),
      style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF9), // Pale Mint
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Transparent for modern look
        elevation: 0,
        automaticallyImplyLeading: true,
        title: Text("Appointments",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              fontSize: 22,
            )),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFC4DAD2)), // Soft Sage
            ),
            child: IconButton(
              icon:
                  Icon(Icons.add, color: const Color(0xFF6A9C89)), // Sage Green
              onPressed: () => _addPatients(),
              tooltip: "Add New Patient",
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.only(top: 10),
        child: Column(
          children: [
            _buildAppointmentsSection(),
            SizedBox(height: 80),
          ],
        ),
      ),
      bottomSheet: DoctorFooter(),
    );
  }

  Widget _buildAppointmentsSection() {
    final sortedAppointments = List<AppointmentModel>.from(appointments)
      ..sort((a, b) => _parseTime(a.time).compareTo(_parseTime(b.time)));

    final listToShow = widget.showOnlyToday && sortedAppointments.length > 5
        ? sortedAppointments.sublist(0, 5)
        : sortedAppointments;
    return Expanded(
      child: listToShow.isEmpty
          ? Center(
              child: Text("No appointments today",
                  style: TextStyle(fontFamily: 'Poppins', color: Colors.grey)))
          : ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: listToShow.length,
              itemBuilder: (context, index) {
                final appointment = listToShow[index];
                final persistedStatus = _persistedStatuses[appointment.id];
                final isPending =
                    persistedStatus != null && persistedStatus == 'Pending';
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFFC4DAD2).withOpacity(0.6),
                        width: 1), // Soft Sage Accent
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.05),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: const Color(0xFFC4DAD2)),
                              ),
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFFF2F7F5),
                                child: Icon(Icons.person,
                                    color: const Color(0xFF6A9C89)),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        appointment.patientName,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      if (isPending) ...[
                                        SizedBox(width: 6),
                                        Icon(
                                          Icons.warning_amber_rounded,
                                          size: 18,
                                          color: Colors.orange,
                                        ),
                                      ],
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isPending
                                          ? Colors.orange.withOpacity(0.1)
                                          : const Color(0xFF6A9C89)
                                              .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      persistedStatus == 'Scheduled' &&
                                              _hasAppointmentPassed(appointment)
                                          ? "Status: Scheduled (Overdue)"
                                          : (persistedStatus == 'Scheduled'
                                              ? "Scheduled"
                                              : (persistedStatus ??
                                                  "Scheduled")),
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        color: persistedStatus == 'Scheduled' &&
                                                _hasAppointmentPassed(
                                                    appointment)
                                            ? Colors.orange.shade800
                                            : const Color(0xFF6A9C89),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                // Create a dummy PatientModel for navigation since we don't have full details here
                                // In a real app, you might fetch details by ID
                                final patient = NewPatientResponse(
                                  patientId: appointment.id,
                                  profile: Profile(
                                    name: appointment.patientName,
                                    age: "35",
                                    gender: "Male",
                                    bloodGroup: "O+",
                                  ),
                                  contact: Contact(
                                    phone: "+1 234-567-8900",
                                    email: "patient@email.com",
                                    address: "123 Main St",
                                  ),
                                  appointment: Appointment(
                                    diagnosis: appointment.diagnosis,
                                    scheduledTime: appointment.time,
                                    symptoms: "Checkup",
                                  ),
                                  medicalHistory: MedicalHistory(
                                    historyNotes: "None",
                                    currentMedications: "None",
                                    allergies: "None",
                                    lastVisitDate: "2024-01-01",
                                  ),
                                );

                                await Get.to(() => PatientDetails(
                                      patient: patient,
                                      appointment: appointment,
                                    ));

                                // Reload persisted statuses so alerts update if status changed.
                                _loadPersistedStatuses();
                              },
                              icon: Icon(Icons.arrow_forward_ios_rounded,
                                  size: 16, color: Colors.grey.shade400),
                            )
                          ],
                        ),
                      ),
                      Divider(
                          height: 1,
                          thickness: 1,
                          color: const Color(0xFFF2F7F5)),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6A9C89), // Sage Green
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.access_time,
                                      size: 14, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text(
                                    appointment.time,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                _buildActionIcon(Icons.call, () {
                                  _callHardcodedNumber();
                                }),
                                SizedBox(width: 12),
                                _buildActionIcon(Icons.message_outlined, () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              "Messaging ${appointment.patientName}...")));
                                }),
                                SizedBox(width: 12),
                                _buildActionIcon(Icons.delete_outline, () {
                                  setState(() {
                                    appointments.removeAt(index);
                                  });
                                }, isDestructive: true),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildActionIcon(IconData icon, VoidCallback onTap,
      {bool isDestructive = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive
              ? const Color(0xFFFFC0C0).withOpacity(0.2)
              : const Color(0xFFF2F7F5),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDestructive
              ? const Color(0xFFE57373)
              : const Color(0xFF6A9C89), // Soft Rose or Sage Green
        ),
      ),
    );
  }
}
