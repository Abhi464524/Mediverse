import 'package:mediverse/feature/doctorPages/view/doctor_footer_view.dart';
import 'package:mediverse/feature/doctorPages/view/doc_notification_view.dart';
import 'package:mediverse/feature/doctorPages/view/patient_details_view.dart';
import 'package:mediverse/feature/doctorPages/model/patient_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import '../../../common/services/storage_service.dart';
import '../model/appointment_model.dart';
import 'appointments_view.dart';
import 'doctor_profile_view.dart';
import 'edit_doctor_profile_view.dart';
import 'digital_prescription_view.dart';

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
  ];

  DateTime _parseTime(String timeStr) {
    final now = DateTime.now();
    final parts = timeStr.split(' ');
    final timeParts = parts[0].split(':');
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);
    final amPm = parts[1].toUpperCase();

    if (amPm == "PM" && hour != 12) hour += 12;
    if (amPm == "AM" && hour == 12) hour = 0;

    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  List<AppointmentModel> get upcomingAppointments {
    final now = DateTime.now();
    return appointments
        .where((app) => _parseTime(app.time).isAfter(now))
        .toList()
      ..sort((a, b) => _parseTime(a.time).compareTo(_parseTime(b.time)));
  }

  bool _hasAppointmentPassed(AppointmentModel app) {
    final appTime = _parseTime(app.time);
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
          preferredSize: const Size.fromHeight(150),
          child: _buildProfileCard(),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildQuickStatsCards(),
              _buildTodaysSchedule(),
              _buildQuickActionButtons(),
              // _buildMedicineStockAlerts(),
              _buildRecentActivity(),
              _buildTodaysSummary(),
              // _upcommingAppointments(),
              SizedBox(height: 80),
            ],
          ),
        ),
        bottomSheet: DoctorFooter(),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: EdgeInsets.only(left: 20, top: 50, right: 20),
      color: const Color(0xFFF2F7F5), // Soft Mint Background
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                  onPressed: () {
                    Get.to(DoctorProfilePage(
                      name: doctorName,
                      specialization: doctorSpecialization ?? "",
                      onEditProfile: _editDoctorProfile,
                    ));
                  },
                  icon: _profileImageFile != null
                      ? CircleAvatar(
                          radius: 16,
                          backgroundImage: FileImage(_profileImageFile!),
                          backgroundColor: const Color(0xFFC4DAD2),
                        )
                      : Icon(Icons.person,
                          color: const Color(0xFF6A9C89))), // Sage Green
              IconButton(
                  onPressed: () {
                    Get.to(DoctorNotificationsPage());
                  },
                  icon: Icon(Icons.notifications_active,
                      color: const Color(0xFF6A9C89))), // Sage Green
            ],
          ),
          SizedBox(
            height: 10,
          ),
          Container(
            child: Text("${'welcome'.tr} ${doctorName}",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ),
          SizedBox(
            height: 5,
          ),
          Container(
            child: Text("${doctorSpecialization}",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
    );
  }

  // 1. Quick Stats Cards
  Widget _buildQuickStatsCards() {
    final todayAppointments = 5;
    final totalPatients = 10;
    // final lowStockMedicines = 2;
    final pendingNotifications = 3;

    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'quick_stats'.tr,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.event_note,
                  title: 'todays_appointments'.tr,
                  value: todayAppointments.toString(),
                  color: const Color(0xFF6A9C89), // Sage Green
                  onTap: () {
                    Get.to(() => const AppointmentsPage(showOnlyToday: true));
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.people,
                  title: 'total_patients'.tr,
                  value: totalPatients.toString(),
                  color: const Color(0xFF4A7C59), // Darker Sage Green
                  onTap: () {
                    Get.to(() => const AppointmentsPage(showOnlyToday: false));
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.notifications,
                  title: 'pending_alerts'.tr,
                  value: pendingNotifications.toString(),
                  color: const Color(0xFFE2AE7B), // Warm Terracotta/Peach
                  onTap: () {
                    Get.to(const DoctorNotificationsPage());
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Today's Schedule Widget
  Widget _buildTodaysSchedule() {
    // Show all upcoming appointments plus any past appointments whose status is Pending.
    final List<AppointmentModel> upcomingList = [];
    final now = DateTime.now();

    for (final app in appointments) {
      final time = _parseTime(app.time);
      final status = _statusFor(app);
      final isUpcoming = time.isAfter(now);
      final isPending = status == 'Pending';

      if (isUpcoming || isPending) {
        if (!upcomingList.any((a) => a.id == app.id)) {
          upcomingList.add(app);
        }
      }
    }

    upcomingList
        .sort((a, b) => _parseTime(a.time).compareTo(_parseTime(b.time)));

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
                                  appointment.time,
                                  style: TextStyle(
                                    color:
                                        isNext ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                              _hasAppointmentPassed(appointment)
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
              /* Expanded(
                child: _buildActionButton(
                  icon: Icons.medical_information,
                  label: "Medicines",
                  color: const Color(0xFF6A9C89), // Sage Green
                  onTap: () => Get.to(MedicineDetails()),
                ),
              ), */
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
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Emergency contacts opened")),
                    );
                  },
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

  /* // 4. Medicine Stock Alerts
  Widget _buildMedicineStockAlerts() {
    final lowStockMedicines = [
      {"name": "Metronidazole", "count": "8"},
      {"name": "Amoxicillin", "count": "5"},
    ];
    final outOfStockMedicines = [
      {"name": "Metformin", "count": "0"},
      {"name": "Albuterol", "count": "0"},
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Medicine Stock Alerts",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => Get.to(MedicineDetails()),
                child: Text("View All"),
              ),
            ],
          ),
          SizedBox(height: 12),
          if (lowStockMedicines.isNotEmpty)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE5C0), // Soft Peach
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFFFE5C0), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning,
                          color: Colors.orange.shade300, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Low Stock",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade300,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  ...lowStockMedicines.map((medicine) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(medicine["name"] ?? ""),
                            Text(
                              "Count: ${medicine["count"]}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade300,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          if (outOfStockMedicines.isNotEmpty) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC0C0).withOpacity(0.3), // Soft Rose
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFFFC0C0), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.error,
                          color: const Color(0xFFFFC0C0), size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Out of Stock",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD68C8C),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  ...outOfStockMedicines.map((medicine) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(medicine["name"] ?? ""),
                            Text(
                              "Out of Stock",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD68C8C),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  } */

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
    final patientsSeenToday = 8;
    final appointmentsCompleted = 6;
    final revenue = 12000;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
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
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6A9C89),
                  const Color(0xFFC4DAD2)
                ], // Sage Green to Soft Sage
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFC4DAD2)
                      .withOpacity(0.5), // Soft Sage Accent
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                      icon: Icons.people,
                      label: 'patients_seen'.tr,
                      value: patientsSeenToday.toString(),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    _buildSummaryItem(
                      icon: Icons.check_circle,
                      label: 'completed'.tr,
                      value: appointmentsCompleted.toString(),
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

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

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
