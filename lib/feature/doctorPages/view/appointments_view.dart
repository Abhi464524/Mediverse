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
  final bool showOnlyToday;

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
  late final PageController _weekPageController;
  static const String _hardcodedPhoneNumber = "+91 7900464524";
  static const List<String> _doctorSlots = <String>[
    '10:00 AM',
    '11:30 AM',
    '02:00 PM',
    '04:15 PM',
    '06:00 PM',
  ];
  // Date parameters are now managed in _patientController
  DateTime get _selectedDate => _patientController.selectedDate.value;
  set _selectedDate(DateTime d) => _patientController.selectedDate.value = d;

  String get _searchQuery => _patientController.searchQuery.value;
  set _searchQuery(String s) => _patientController.searchQuery.value = s;

  final TextEditingController _searchController = TextEditingController();
  bool _calendarExpanded = true;

  /// Calls the API via controller.
  Future<void> _fetchAppointments() async {
    await _patientController.fetchAppointments();
  }

  List<AppointmentModel> get appointments => _patientController.appointments;

  Future<void> _callHardcodedNumber() async {
    await launchCallWithLoader(context, _hardcodedPhoneNumber);
  }

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

  bool _hasAppointmentPassed(AppointmentModel app) {
    final appTime = _parseTime(app.time, date: app.date);
    return DateTime.now().isAfter(appTime);
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  int _daysInMonth(DateTime date) {
    final firstOfNextMonth = (date.month == 12)
        ? DateTime(date.year + 1, 1, 1)
        : DateTime(date.year, date.month + 1, 1);
    return firstOfNextMonth.subtract(const Duration(days: 1)).day;
  }

  @override
  void initState() {
    super.initState();
    // Initialize controller state if not set
    // Initialize controller state if not set
    _patientController.selectedDate.value = _dateOnly(DateTime.now());
    _weekPageController =
        PageController(initialPage: _selectedWeekIndexForMonth(_selectedDate));

    // Reset search state on entering the page via its own route
    _patientController.searchQuery.value = '';
    _searchController.clear();

    _fetchAppointments();
    _loadPersistedStatuses();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpToSelectedWeek(animate: false);
    });

    if (widget.showAddPatient) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _addPatients();
      });
    }
  }

  @override
  void dispose() {
    _weekPageController.dispose();
    _searchController.dispose();
    // We don't reset controller state here so it persists if we come back
    super.dispose();
  }

  int _selectedWeekIndexForMonth(DateTime selectedDate) {
    final firstOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final leadingEmptyCells = firstOfMonth.weekday % 7; // Sunday = 0
    return ((leadingEmptyCells + selectedDate.day - 1) / 7).floor();
  }

  void _jumpToSelectedWeek({bool animate = true}) {
    if (!_weekPageController.hasClients) return;
    final targetPage = _selectedWeekIndexForMonth(_selectedDate);
    if (animate) {
      _weekPageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
      return;
    }
    _weekPageController.jumpToPage(targetPage);
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
                insetPadding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 40),
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
                                child: _buildDialogTextField(ageController,
                                    "Age", Icons.calendar_today)),
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
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
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
                                        padding:
                                            EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: Text("Cancel",
                                          style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w600))),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                      onPressed: _patientController
                                              .isLoading.value
                                          ? null
                                          : () async {
                                              if (nameController
                                                      .text.isNotEmpty &&
                                                  selectedSlot.isNotEmpty) {
                                                final newPatient =
                                                    NewPatientResponse(
                                                  patientId: DateTime.now()
                                                      .millisecondsSinceEpoch
                                                      .toString(),
                                                  profile: Profile(
                                                    name: nameController.text,
                                                    age: ageController.text,
                                                    gender:
                                                        genderController.text,
                                                  ),
                                                  contact: Contact(
                                                    phone:
                                                        contactController.text,
                                                  ),
                                                  appointment: Appointment(
                                                    scheduledTime: selectedSlot,
                                                    diagnosis:
                                                        diagnosisController
                                                            .text,
                                                  ),
                                                );

                                                final success =
                                                    await _patientController
                                                        .addPatient(newPatient);

                                                if (success) {
                                                  setState(() {
                                                    appointments
                                                        .add(AppointmentModel(
                                                      id: newPatient
                                                              .patientId ??
                                                          '',
                                                      patientName: newPatient
                                                              .profile?.name ??
                                                          '',
                                                      time: selectedSlot,
                                                      diagnosis: newPatient
                                                              .appointment
                                                              ?.diagnosis ??
                                                          '',
                                                    ));
                                                  });
                                                  Navigator.pop(context);
                                                }
                                              }
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                            0xFF6A9C89), // Sage Green
                                        foregroundColor: Colors.white,
                                        padding:
                                            EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
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
                                                  fontWeight:
                                                      FontWeight.bold))),
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
            AnimatedCrossFade(
              firstChild: _buildCalendarDateFilter(),
              secondChild: _buildCollapsedDateChip(),
              crossFadeState: _calendarExpanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 250),
            ),
            SizedBox(height: 10),
            _buildSearchBar(),
            SizedBox(height: 10),
            _buildAppointmentsSection(),
            SizedBox(height: 80),
          ],
        ),
      ),
      bottomSheet: const DoctorFooter(selectedIndex: 4),
    );
  }

  Widget _buildCollapsedDateChip() {
    final dd = _selectedDate.day.toString().padLeft(2, '0');
    final mmm = _monthLabel(_selectedDate.month).substring(0, 3);
    final label = '$dd $mmm ${_selectedDate.year}';

    return GestureDetector(
      onTap: () => setState(() => _calendarExpanded = true),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFC4DAD2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                size: 18, color: Color(0xFF6A9C89)),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
            const Spacer(),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF6A9C89)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          _searchQuery = value.trim().toLowerCase();
          _fetchAppointments();
          setState(() {}); // Update local UI like clear icon
        },
        decoration: InputDecoration(
          hintText: 'Search by name or phone...',
          hintStyle: TextStyle(
            fontFamily: 'Poppins',
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
          prefixIcon: Icon(Icons.search, color: const Color(0xFF6A9C89)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon:
                      Icon(Icons.clear, color: Colors.grey.shade400, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _searchQuery = '';
                    _fetchAppointments();
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: const Color(0xFFC4DAD2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: const Color(0xFFC4DAD2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: const Color(0xFF6A9C89), width: 1.5),
          ),
        ),
        style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
      ),
    );
  }

  Widget _buildAppointmentsSection() {
    return Expanded(
      child: Obx(() {
        if (_patientController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // Data comes from the controller (API driven).
        // Sorting is done client-side for display order.
        final sorted = List<AppointmentModel>.from(appointments)
          ..sort((a, b) => _parseTime(a.time, date: a.date)
              .compareTo(_parseTime(b.time, date: b.date)));

        final listToShow =
            widget.showOnlyToday ? sorted.take(5).toList() : sorted;

        final emptyMessage = _searchQuery.isNotEmpty
            ? "No patients found for '$_searchQuery'"
            : "No appointments on selected date";

        if (listToShow.isEmpty) {
          return RefreshIndicator(
            onRefresh: _fetchAppointments,
            color: const Color(0xFF6A9C89),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                Center(
                  child: Text(emptyMessage,
                      style:
                          TextStyle(fontFamily: 'Poppins', color: Colors.grey)),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _fetchAppointments,
          color: const Color(0xFF6A9C89),
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification) {
                final offset = notification.metrics.pixels;
                if (offset > 2 && _calendarExpanded) {
                  setState(() => _calendarExpanded = false);
                } else if (offset <= 0 && !_calendarExpanded) {
                  setState(() => _calendarExpanded = true);
                }
              }
              return false;
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
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
                                      Flexible(
                                        child: Text(
                                          appointment.patientName,
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isPending) ...[
                                        const SizedBox(width: 6),
                                        const Icon(Icons.warning_amber_rounded,
                                            size: 18, color: Colors.orange),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Last Visit: ${appointment.patient?.medicalHistory?.lastVisitDate ?? ""}",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Optimized Status Pill with Dot Indicator
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: persistedStatus == 'Scheduled' &&
                                          _hasAppointmentPassed(appointment)
                                      ? Colors.orange.withOpacity(0.3)
                                      : const Color(0xFF6A9C89)
                                          .withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: persistedStatus == 'Scheduled' &&
                                              _hasAppointmentPassed(appointment)
                                          ? Colors.orange
                                          : const Color(0xFF6A9C89),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    persistedStatus == 'Scheduled' &&
                                            _hasAppointmentPassed(appointment)
                                        ? "Overdue"
                                        : (persistedStatus ??
                                            appointment.status),
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: persistedStatus == 'Scheduled' &&
                                              _hasAppointmentPassed(appointment)
                                          ? Colors.orange.shade800
                                          : const Color(0xFF6A9C89),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(
                          height: 1, thickness: 1, color: Color(0xFFF2F7F5)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Time chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6A9C89),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.access_time,
                                      size: 14, color: Colors.white),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatTimeWithDay(appointment.time,
                                        date: appointment.date),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Action icons
                            _buildActionIcon(Icons.call, () {
                              _callHardcodedNumber();
                            }),
                            const SizedBox(width: 8),
                            _buildActionIcon(Icons.message_outlined, () {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(
                                      "Messaging ${appointment.patientName}...")));
                            }),
                            const SizedBox(width: 8),
                            _buildActionIcon(
                              Icons.arrow_forward_ios_rounded,
                              () async {
                                final patient = appointment.patient ??
                                    NewPatientResponse(
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
                                _loadPersistedStatuses();
                              },
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCalendarDateFilter() {
    final firstOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final totalDays = _daysInMonth(_selectedDate);
    final leadingEmptyCells = firstOfMonth.weekday % 7; // Sunday = 0
    final totalCells = leadingEmptyCells + totalDays;
    final weekCount = (totalCells / 7).ceil();
    final monthYearLabel =
        '${_monthLabel(_selectedDate.month)} ${_selectedDate.year}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC4DAD2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  setState(() {
                    _selectedDate = DateTime(
                        _selectedDate.year, _selectedDate.month - 1, 1);
                  });
                  _fetchAppointments();
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _jumpToSelectedWeek());
                },
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    color: Color(0xFF6A9C89),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    monthYearLabel,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  setState(() {
                    _selectedDate = DateTime(
                        _selectedDate.year, _selectedDate.month + 1, 1);
                  });
                  _fetchAppointments();
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _jumpToSelectedWeek());
                },
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF6A9C89),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: const [
                Expanded(child: Center(child: Text('S'))),
                Expanded(child: Center(child: Text('M'))),
                Expanded(child: Center(child: Text('T'))),
                Expanded(child: Center(child: Text('W'))),
                Expanded(child: Center(child: Text('T'))),
                Expanded(child: Center(child: Text('F'))),
                Expanded(child: Center(child: Text('S'))),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 36,
            child: PageView.builder(
              controller: _weekPageController,
              itemCount: weekCount,
              itemBuilder: (context, weekIndex) {
                return Row(
                  children: List<Widget>.generate(7, (dayIndex) {
                    final cellIndex = weekIndex * 7 + dayIndex;
                    final dayNumber = cellIndex - leadingEmptyCells + 1;
                    if (dayNumber < 1 || dayNumber > totalDays) {
                      return const Expanded(child: SizedBox.shrink());
                    }
                    final date = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      dayNumber,
                    );
                    final isSelected = DateUtils.isSameDay(
                        date, _patientController.selectedDate.value);
                    return Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          _patientController.selectedDate.value = date;
                          _fetchAppointments();
                          setState(() {});
                        },
                        child: Center(
                          child: Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: const Color(0xFF6A9C89),
                                      width: 1.6,
                                    )
                                  : null,
                            ),
                            child: Text(
                              '$dayNumber',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected
                                    ? const Color(0xFF6A9C89)
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _monthLabel(int month) {
    switch (month) {
      case 1:
        return 'January';
      case 2:
        return 'February';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      case 10:
        return 'October';
      case 11:
        return 'November';
      default:
        return 'December';
    }
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
