import 'package:mediverse/feature/doctorPages/view/doctor_footer_view.dart';
import 'package:mediverse/feature/doctorPages/view/doc_notification_view.dart';
import 'package:mediverse/feature/doctorPages/view/patient_details_view.dart';
import 'package:mediverse/feature/doctorPages/view/emergency_appointments_view.dart';
import 'package:mediverse/feature/doctorPages/view/appointments_view.dart';
import 'package:mediverse/feature/doctorPages/view/doctor_profile_view.dart';
import 'package:mediverse/feature/doctorPages/view/edit_doctor_profile_view.dart';
import 'package:mediverse/feature/doctorPages/view/digital_prescription_view.dart';
import '../controller/patient_controller.dart';
import 'package:mediverse/feature/doctorPages/model/patient_model.dart';
import '../model/appointment_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import '../../../common/services/storage_service.dart';

class DoctorHomePage extends StatefulWidget {
  final String name;
  final String? speciality;
  const DoctorHomePage({super.key, required this.name, this.speciality});

  @override
  State<DoctorHomePage> createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends State<DoctorHomePage> {
  String doctorName = "";
  String? doctorSpecialization = "";
  final Map<String, String> _persistedStatuses = {};
  File? _profileImageFile;

  final PatientController _patientController = Get.put(PatientController());

  List<AppointmentModel> get appointments => _patientController.appointments;

  DateTime _parseTime(String timeStr, {String? date}) {
    if (timeStr.isEmpty) return DateTime.now();

    // Use appointment date if provided, otherwise default to today
    DateTime baseDate = DateTime.now();
    if (date != null && date.isNotEmpty) {
      try {
        baseDate = DateTime.parse(date);
      } catch (_) {}
    }

    try {
      final parts = timeStr.trim().split(' ');
      if (parts.length < 2) return baseDate;
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      final amPm = parts[1].toUpperCase();

      if (amPm == "PM" && hour != 12) hour += 12;
      if (amPm == "AM" && hour == 12) hour = 0;

      return DateTime(
          baseDate.year, baseDate.month, baseDate.day, hour, minute);
    } catch (_) {
      return baseDate;
    }
  }

  /// Returns a display string with a day label prefix.
  /// e.g. "Today, 10:00 AM" or "05-04, 10:00 AM"
  String _formatTimeWithDay(String timeStr, {String? date}) {
    final parsed = _parseTime(timeStr, date: date);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = DateTime(parsed.year, parsed.month, parsed.day)
        .difference(today)
        .inDays;

    String dayLabel;
    if (diff == 0) {
      dayLabel = 'Today';
    } else if (diff == 1) {
      dayLabel = 'Tomorrow';
    } else if (diff == -1) {
      dayLabel = 'Yesterday';
    } else {
      final dd = parsed.day.toString().padLeft(2, '0');
      final mm = parsed.month.toString().padLeft(2, '0');
      dayLabel = '$dd-$mm';
    }
    return '$dayLabel, $timeStr';
  }

  List<AppointmentModel> get upcomingAppointments {
    final now = DateTime.now();
    return appointments
        .where((app) => _parseTime(app.time, date: app.date).isAfter(now))
        .toList()
      ..sort((a, b) => _parseTime(a.time, date: a.date)
          .compareTo(_parseTime(b.time, date: b.date)));
  }

  bool _hasAppointmentPassed(AppointmentModel app) {
    final appTime = _parseTime(app.time, date: app.date);
    return DateTime.now().isAfter(appTime);
  }

  String _statusFor(AppointmentModel app) {
    final persisted = _persistedStatuses[app.id];
    if (persisted != null && persisted.isNotEmpty) return persisted;
    if (_hasAppointmentPassed(app)) return 'Pending';
    return app.status;
  }

  Future<void> _editDoctorProfile() async {
    await Get.to(() => EditDoctorProfileView(
          currentName: doctorName.replaceAll('Dr. ', ''),
          currentSpecialization: doctorSpecialization ?? "",
          onSave: (newName, newSpecialization) {
            setState(() {
              doctorName = "Dr. $newName";
              doctorSpecialization = newSpecialization;
            });
          },
        ));
    await _loadProfileImageFromStorage();
  }

  @override
  void initState() {
    super.initState();
    doctorName = "Dr. ${widget.name}";
    doctorSpecialization = widget.speciality ?? "";
    _loadDoctorProfileFromStorage();
    _loadProfileImageFromStorage();
    _loadPersistedStatuses();

    // Fetch real appointments from API
    _patientController.fetchAppointments();
  }

  String _profileImageKey(String username) => "doctor_profile_image_$username";

  Future<void> _loadProfileImageFromStorage() async {
    try {
      final storage = await StorageService.getInstance();
      final profile = await storage.getCurrentUserProfile();
      final username = profile?['username'];
      if (username == null || username.isEmpty) return;
      final savedPath = storage.getString(_profileImageKey(username));
      if (savedPath == null || savedPath.isEmpty) return;
      final file = File(savedPath);
      if (!file.existsSync()) return;
      if (!mounted) return;
      setState(() {
        _profileImageFile = file;
      });
    } catch (_) {
      // Ignore storage/file issues and keep icon fallback.
    }
  }

  Future<void> _loadDoctorProfileFromStorage() async {
    try {
      final storage = await StorageService.getInstance();
      final profile = await storage.getCurrentUserProfile();
      if (profile == null) return;

      final storedName = profile['username'] ?? '';
      final storedSpeciality = profile['speciality'] ?? '';

      setState(() {
        if (storedName.isNotEmpty) {
          doctorName = "Dr. $storedName";
        }
        if (storedSpeciality.isNotEmpty &&
            (doctorSpecialization == null ||
                doctorSpecialization!.isEmpty ||
                doctorSpecialization == "null")) {
          doctorSpecialization = storedSpeciality;
        }
      });
    } catch (_) {
      // Ignore storage errors and keep existing values.
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
          _persistedStatuses[app.id] = 'Scheduled';
        }
      }
      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      // Ignore storage errors; schedule will just not show alerts.
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(200),
          child: _buildProfileCard(),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildTodaysSummary(),
              _buildTodaysSchedule(),

              _buildAppointmentAnalytics(),
              _buildQuickActionButtons(),
              // _buildMedicineStockAlerts(),
              _buildRecentActivity(),

              // _upcommingAppointments(),
              SizedBox(height: 80),
            ],
          ),
        ),
        bottomSheet: const DoctorFooter(selectedIndex: 0),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A9C89).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Get.to(DoctorProfilePage(
                  name: doctorName,
                  specialization: doctorSpecialization ?? "",
                  onEditProfile: _editDoctorProfile,
                )),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFF6A9C89).withOpacity(0.2),
                        width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: _profileImageFile != null
                        ? FileImage(_profileImageFile!)
                        : null,
                    backgroundColor: const Color(0xFFC4DAD2),
                    child: _profileImageFile == null
                        ? const Icon(Icons.person, color: Color(0xFF6A9C89))
                        : null,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F7F5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  onPressed: () => Get.to(DoctorNotificationsPage()),
                  icon: const Icon(Icons.notifications_none_rounded,
                      color: Color(0xFF6A9C89)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            "${'welcome'.tr},",
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Poppins',
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            doctorName,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 24,
              fontFamily: 'Poppins',
              color: Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
          if (doctorSpecialization != null)
            Text(
              doctorSpecialization!,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                fontFamily: 'Poppins',
                color: Color(0xFF6A9C89),
              ),
            ),
        ],
      ),
    );
  }



  // 1.5 Appointment Analytics Graph
  int _selectedAnalyticsTab = 0; // 0: Day, 1: Week, 2: Month

  Widget _buildAppointmentAnalytics() {
    final List<Map<String, dynamic>> analyticsData = [
      {
        "title": "Daily Comparison",
        "currentLabel": "Today",
        "prevLabel": "Yesterday",
        "currentValue": 12.0,
        "prevValue": 8.0,
        "color": const Color(0xFF6A9C89),
      },
      {
        "title": "Weekly Comparison",
        "currentLabel": "This Week",
        "prevLabel": "Prev Week",
        "currentValue": 54.0,
        "prevValue": 42.0,
        "color": const Color(0xFF4A7C59),
      },
      {
        "title": "Monthly Comparison",
        "currentLabel": "This Month",
        "prevLabel": "Prev Month",
        "currentValue": 210.0,
        "prevValue": 185.0,
        "color": const Color(0xFFE2AE7B),
      },
    ];

    final data = analyticsData[_selectedAnalyticsTab];
    final double maxVal = data["currentValue"] > data["prevValue"]
        ? data["currentValue"] * 1.2
        : data["prevValue"] * 1.2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "appointment_analytics".tr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    _buildTabButton("Day", 0),
                    _buildTabButton("Week", 1),
                    _buildTabButton("Month", 2),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data["title"],
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${data["currentValue"].toInt()} Appointments",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    _buildTrendIndicator(
                        data["currentValue"], data["prevValue"]),
                  ],
                ),
                const SizedBox(height: 30),
                SizedBox(
                  height: 160,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBar(data["prevLabel"], data["prevValue"], maxVal,
                          Colors.grey.shade300),
                      _buildBar(data["currentLabel"], data["currentValue"],
                          maxVal, data["color"]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    bool isSelected = _selectedAnalyticsTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedAnalyticsTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF6A9C89) : Colors.grey.shade500,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  Widget _buildTrendIndicator(double current, double prev) {
    double percent = ((current - prev) / prev) * 100;
    bool isUp = percent >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isUp ? Colors.green : Colors.red).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isUp ? Icons.trending_up : Icons.trending_down,
            size: 14,
            color: isUp ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            "${percent.abs().toStringAsFixed(1)}%",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isUp ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String label, double value, double max, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          value.toInt().toString(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 50,
          height: (value / max) * 120,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(6),
              bottomRight: Radius.circular(6),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color,
                color.withOpacity(0.7),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // 2. Today's Schedule Widget
  Widget _buildTodaysSchedule() {
    return Obx(() {
      // Show all upcoming appointments plus any past appointments whose status is Pending.
      final List<AppointmentModel> upcomingList = [];
      final now = DateTime.now();

      for (final app in appointments) {
        final time = _parseTime(app.time, date: app.date);
        final status = _statusFor(app);
        final isUpcoming = time.isAfter(now);
        final isPending = status == 'Pending';

        if (isUpcoming || isPending) {
          if (!upcomingList.any((a) => a.id == app.id)) {
            upcomingList.add(app);
          }
        }
      }

      upcomingList.sort((a, b) => _parseTime(a.time, date: a.date)
          .compareTo(_parseTime(b.time, date: b.date)));

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Schedule",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => Get.to(AppointmentsPage()),
                  child: Text("View All"),
                ),
              ],
            ),
            SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                    color: const Color(0xFFC4DAD2),
                    width: 1.5), // Soft Sage Accent
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC4DAD2)
                        .withOpacity(0.3), // Soft Sage Accent
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: upcomingList.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Center(
                        child: Text(
                          "No upcoming appointments for today",
                          style: TextStyle(
                              color: Colors.grey, fontFamily: 'Poppins'),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: upcomingList.length,
                      itemBuilder: (context, index) {
                        final appointment = upcomingList[index];
                        final isNext = index == 0;
                        final status = _statusFor(appointment);
                        final isPending = status == 'Pending';
                        return GestureDetector(
                          onTap: () async {
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
                            await _loadPersistedStatuses();
                          },
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isNext
                                  ? const Color(0xFFF2F7F5)
                                  : Colors.white, // Soft Mint
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isNext
                                        ? const Color(0xFF6A9C89) // Sage Green
                                        : Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _formatTimeWithDay(appointment.time,
                                        date: appointment.date),
                                    style: TextStyle(
                                      color: isNext
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            appointment.patientName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          if (isPending) ...[
                                            SizedBox(width: 6),
                                            Icon(
                                              Icons.warning_amber_rounded,
                                              size: 16,
                                              color: Colors.orange,
                                            ),
                                          ],
                                        ],
                                      ),
                                      Text(
                                        status == 'Scheduled' &&
                                                _hasAppointmentPassed(
                                                    appointment)
                                            ? "Status: Scheduled (Overdue)"
                                            : (status == 'Scheduled'
                                                ? "Scheduled"
                                                : status),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: status == 'Scheduled' &&
                                                  _hasAppointmentPassed(
                                                      appointment)
                                              ? Colors.orange.shade800
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isNext)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          const Color(0xFF6A9C89), // Sage Green
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "Next",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    });
  }

  // 3. Quick Action Buttons
  Widget _buildQuickActionButtons() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'quick_actions'.tr,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.person_add,
                  label: 'add_patient'.tr,
                  color: const Color(0xFF6A9C89), // Sage Green
                  onTap: () => Get.to(
                      () => const AppointmentsPage(showAddPatient: true)),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.receipt_long,
                  label: 'generate_rx'.tr,
                  color: const Color(0xFF6A9C89), // Sage Green
                  onTap: () => Get.to(() => const DigitalPrescriptionView()),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.event_note,
                  label: 'appointments'.tr,
                  color: const Color(0xFF6A9C89), // Sage Green
                  onTap: () => Get.to(AppointmentsPage()),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.emergency,
                  label: 'emergency'.tr,
                  color: const Color(0xFFFFC0C0), // Soft Rose
                  onTap: () => Get.to(() => const EmergencyAppointmentsPage()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // 5. Recent Activity/Notifications Summary
  Widget _buildRecentActivity() {
    final recentActivities = [
      {
        "type": "notification",
        "message": "New appointment scheduled",
        "time": "2 hours ago"
      },
      {
        "type": "patient",
        "message": "Patient 5 visited today",
        "time": "4 hours ago"
      },
      {
        "type": "system",
        "message": "Medicine stock updated",
        "time": "1 day ago"
      },
    ];

    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'recent_activity'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => Get.to(DoctorNotificationsPage()),
                child: Text('view_all'.tr),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                  color: const Color(0xFFC4DAD2),
                  width: 1.5), // Soft Sage Accent
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFC4DAD2)
                      .withOpacity(0.3), // Soft Sage Accent
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: recentActivities.length,
              itemBuilder: (context, index) {
                final activity = recentActivities[index];
                IconData icon;
                Color iconColor;
                if (activity["type"] == "notification") {
                  icon = Icons.notifications;
                  iconColor = const Color(0xFF6A9C89); // Sage Green
                } else if (activity["type"] == "patient") {
                  icon = Icons.person;
                  iconColor = const Color(0xFF6A9C89); // Sage Green
                } else {
                  icon = Icons.system_update;
                  iconColor = const Color(0xFFFFE5C0); // Soft Peach
                }
                return Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade200,
                        width: index < recentActivities.length - 1 ? 1 : 0,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: iconColor, size: 20),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity["message"] ?? "",
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              activity["time"] ?? "",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 6. Today's Summary Card
  Widget _buildTodaysSummary() {
    // Calculate today's metrics
    final total = appointments.length;
    final done = appointments
        .where((a) =>
            a.status.toLowerCase() == 'done' ||
            a.status.toLowerCase() == 'completed')
        .length;
    final pending = appointments
        .where((a) =>
            a.status.toLowerCase() == 'scheduled' ||
            a.status.toLowerCase() == 'pending')
        .length;
    final engaged = total - done - pending; // Simplified logic for 'engaged'

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'todays_summary'.tr,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6A9C89), Color(0xFF4A7C59)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6A9C89).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCardItem(
                        icon: Icons.assignment_outlined,
                        label: "Total",
                        value: total.toString(),
                      ),
                    ),
                    _buildSummaryDivider(),
                    Expanded(
                      child: _buildSummaryCardItem(
                        icon: Icons.check_circle_outline,
                        label: "Done",
                        value: done.toString(),
                      ),
                    ),
                    _buildSummaryDivider(),
                    Expanded(
                      child: _buildSummaryCardItem(
                        icon: Icons.hourglass_empty_rounded,
                        label: "Pending",
                        value: pending.toString(),
                      ),
                    ),
                    _buildSummaryDivider(),
                    Expanded(
                      child: _buildSummaryCardItem(
                        icon: Icons.groups_outlined,
                        label: "Engaged",
                        value: engaged.toString(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCardItem(
      {required IconData icon, required String label, required String value}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            fontFamily: 'Poppins',
            letterSpacing: 0.5,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white.withOpacity(0.2),
    );
  }

  // _upcommingAppointments(),

  // Widget _upcommingAppointments() {
  //   return Container(
  //     padding: EdgeInsets.all(20),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Text("Upcomming Appointments",
  //                 style: TextStyle(
  //                   fontWeight: FontWeight.w500,
  //                 )),
  //             TextButton(
  //                 onPressed: () {
  //                   Get.to(AppointmentsPage());
  //                 },
  //                 child: Text("See all"))
  //           ],
  //         ),
  //         Container(
  //           padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //           width: double.infinity,
  //           decoration: BoxDecoration(
  //             color: Colors.cyan.shade100,
  //             borderRadius: BorderRadius.circular(20),
  //           ),
  //           child: Column(
  //             children: [
  //               Row(
  //                 children: [
  //                   Icon(
  //                     Icons.person,
  //                     size: 50,
  //                   ),
  //                   SizedBox(
  //                     width: 12,
  //                   ),
  //                   Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Text(
  //                         "Mr. Shubham Chaudhary",
  //                         style: TextStyle(fontWeight: FontWeight.bold),
  //                       ),
  //                       Text(
  //                         "Heart Patient",
  //                         style: TextStyle(
  //                             fontSize: 10, fontWeight: FontWeight.w500),
  //                       ),
  //                     ],
  //                   ),
  //                 ],
  //               ),
  //               SizedBox(height: 20),
  //               Container(
  //                 padding: EdgeInsets.symmetric(horizontal: 12),
  //                 child: Row(
  //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                   children: [
  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.start,
  //                       children: [
  //                         Icon(
  //                           Icons.calendar_month,
  //                           size: 20,
  //                         ),
  //                         SizedBox(
  //                           width: 10,
  //                         ),
  //                         Text("9-sept-2025"),
  //                       ],
  //                     ),
  //                     GestureDetector(
  //                       onTap: () {},
  //                       child: Container(
  //                         padding:
  //                             EdgeInsets.symmetric(vertical: 8, horizontal: 12),
  //                         decoration: BoxDecoration(
  //                           borderRadius: BorderRadius.circular(20),
  //                           color: Colors.black,
  //                         ),
  //                         child: Text(
  //                           "View Appointment",
  //                           style: TextStyle(color: Colors.white),
  //                         ),
  //                       ),
  //                     )
  //                   ],
  //                 ),
  //               )
  //             ],
  //           ),
  //         )
  //       ],
  //     ),
  //   );
  // }
}
