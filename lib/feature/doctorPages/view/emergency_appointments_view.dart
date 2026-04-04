import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mediverse/feature/doctorPages/controller/emergency_appointments_controller.dart';
import 'package:mediverse/feature/doctorPages/model/appointment_model.dart';
import 'package:mediverse/feature/doctorPages/model/emergency_appointment_model.dart';
import 'package:mediverse/feature/doctorPages/model/patient_model.dart';
import 'package:mediverse/feature/doctorPages/view/doctor_footer_view.dart';
import 'package:mediverse/feature/doctorPages/view/patient_details_view.dart';
import '../../../common/services/storage_service.dart';
import '../../../common/utils/phone_launcher.dart' show launchCallWithLoader;

// Emergency color palette
const Color _kAccent = Color(0xFFE53935);
const Color _kAccentLight = Color(0xFFFFC0C0);
const Color _kAccentBg = Color(0xFFFFF5F5);
const Color _kAccentSurface = Color(0xFFFFF1F1);
const Color _kBorderColor = Color(0xFFFFCDD2);

class EmergencyAppointmentsPage extends StatefulWidget {
  const EmergencyAppointmentsPage({super.key});

  @override
  State<EmergencyAppointmentsPage> createState() =>
      _EmergencyAppointmentsPageState();
}

class _EmergencyAppointmentsPageState extends State<EmergencyAppointmentsPage> {
  final EmergencyAppointmentsController _controller =
      Get.put(EmergencyAppointmentsController());

  static const String _hardcodedPhoneNumber = "+91 7900464524";

  DateTime _selectedDate = DateTime.now();
  late final PageController _weekPageController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _calendarExpanded = true;
  final Map<String, String> _persistedStatuses = {};

  // ── Helpers ──

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _parseTime(String timeStr) {
    if (timeStr.isEmpty) return DateTime.now();
    final now = DateTime.now();
    try {
      final parts = timeStr.trim().split(' ');
      if (parts.length < 2) return now;
      final tp = parts[0].split(':');
      int h = int.parse(tp[0]);
      int m = int.parse(tp[1]);
      final amPm = parts[1].toUpperCase();
      if (amPm == 'PM' && h != 12) h += 12;
      if (amPm == 'AM' && h == 12) h = 0;
      return DateTime(now.year, now.month, now.day, h, m);
    } catch (_) {
      return now;
    }
  }

  String _formatTimeWithDay(String timeStr) {
    final parsed = _parseTime(timeStr);
    final today = _dateOnly(DateTime.now());
    final diff = _dateOnly(parsed).difference(today).inDays;
    String dayLabel;
    if (diff == 0) {
      dayLabel = 'Today';
    } else if (diff == 1) {
      dayLabel = 'Tomorrow';
    } else if (diff == -1) {
      dayLabel = 'Yesterday';
    } else {
      dayLabel =
          '${parsed.day.toString().padLeft(2, '0')}-${parsed.month.toString().padLeft(2, '0')}';
    }
    return '$dayLabel, $timeStr';
  }

  bool _hasAppointmentPassed(EmergencyAppointmentModel app) =>
      DateTime.now().isAfter(_parseTime(app.time));

  int _daysInMonth(DateTime date) {
    final next = (date.month == 12)
        ? DateTime(date.year + 1, 1, 1)
        : DateTime(date.year, date.month + 1, 1);
    return next.subtract(const Duration(days: 1)).day;
  }

  int _selectedWeekIndexForMonth(DateTime d) {
    final first = DateTime(d.year, d.month, 1);
    final leading = first.weekday % 7;
    return ((leading + d.day - 1) / 7).floor();
  }

  void _jumpToSelectedWeek({bool animate = true}) {
    if (!_weekPageController.hasClients) return;
    final target = _selectedWeekIndexForMonth(_selectedDate);
    if (animate) {
      _weekPageController.animateToPage(target,
          duration: const Duration(milliseconds: 240), curve: Curves.easeOut);
    } else {
      _weekPageController.jumpToPage(target);
    }
  }

  String _monthLabel(int month) {
    const labels = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return labels[month - 1];
  }

  String _mapStatusForDetails(String raw) {
    final s = raw.toLowerCase();
    if (s.contains('done') || s.contains('completed')) return 'Done';
    return 'Scheduled';
  }

  List<EmergencyAppointmentModel> get _filteredAppointments {
    final all = _controller.appointments.toList();
    if (_searchQuery.isEmpty) return all;
    return all
        .where((a) => a.patientName.toLowerCase().contains(_searchQuery))
        .toList();
  }

  Future<void> _callHardcodedNumber() async {
    await launchCallWithLoader(context, _hardcodedPhoneNumber);
  }

  Future<void> _loadPersistedStatuses() async {
    try {
      final storage = await StorageService.getInstance();
      for (final app in _controller.appointments) {
        String? status = storage.getAppointmentStatus(app.id);
        if (status == 'Pending') status = 'Scheduled';
        if (status != null && status.isNotEmpty) {
          _persistedStatuses[app.id] = status;
        }
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  // ── Lifecycle ──

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOnly(DateTime.now());
    _weekPageController =
        PageController(initialPage: _selectedWeekIndexForMonth(_selectedDate));
    _controller.loadEmergencyAppointments().then((_) => _loadPersistedStatuses());
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _jumpToSelectedWeek(animate: false));
  }

  @override
  void dispose() {
    _weekPageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kAccentBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Emergency',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: _kBorderColor),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: _kAccent),
              onPressed: () => _controller.loadEmergencyAppointments(),
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 10),
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
            const SizedBox(height: 10),
            _buildSearchBar(),
            const SizedBox(height: 10),
            _buildAppointmentsSection(),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomSheet: const DoctorFooter(),
    );
  }

  // ── Collapsed date chip ──

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
          border: Border.all(color: _kBorderColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 18, color: _kAccent),
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
            const Icon(Icons.keyboard_arrow_down_rounded, color: _kAccent),
          ],
        ),
      ),
    );
  }

  // ── Search bar ──

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Search by patient name...',
          hintStyle: TextStyle(
              fontFamily: 'Poppins', color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: _kAccent),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey.shade400, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _kBorderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _kBorderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _kAccent, width: 1.5),
          ),
        ),
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
      ),
    );
  }

  // ── Appointments list ──

  Widget _buildAppointmentsSection() {
    final emptyMsg = _searchQuery.isNotEmpty
        ? "No patients found for '$_searchQuery'"
        : 'No emergency appointments on selected date';

    return Expanded(
      child: Obx(() {
        if (_controller.isLoading.value) {
          return const Center(
              child: CircularProgressIndicator(color: _kAccent));
        }
        if (_controller.error.value.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Failed to load.\n${_controller.error.value}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
            ),
          );
        }

        final listToShow = _filteredAppointments
          ..sort((a, b) => _parseTime(a.time).compareTo(_parseTime(b.time)));

        if (listToShow.isEmpty) {
          return Center(
            child: Text(emptyMsg,
                style:
                    const TextStyle(fontFamily: 'Poppins', color: Colors.grey)),
          );
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n is ScrollUpdateNotification) {
              final px = n.metrics.pixels;
              if (px > 2 && _calendarExpanded) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _calendarExpanded = false);
                });
              } else if (px <= 0 && !_calendarExpanded) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _calendarExpanded = true);
                });
              }
            }
            return false;
          },
          child: RefreshIndicator(
            color: _kAccent,
            onRefresh: _controller.loadEmergencyAppointments,
            child: ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: listToShow.length,
              itemBuilder: (context, index) =>
                  _buildAppointmentCard(listToShow[index]),
            ),
          ),
        );
      }),
    );
  }

  // ── Appointment card ──

  Widget _buildAppointmentCard(EmergencyAppointmentModel item) {
    final persistedStatus = _persistedStatuses[item.id];
    final isPending =
        persistedStatus != null && persistedStatus == 'Pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kAccentLight.withOpacity(0.7), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header row ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _kBorderColor),
                  ),
                  child: const CircleAvatar(
                    radius: 24,
                    backgroundColor: _kAccentSurface,
                    child:
                        Icon(Icons.emergency_rounded, color: _kAccent),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.patientName,
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
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _kAccentSurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Severity: ${item.severity}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: _kAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _kAccentSurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    persistedStatus ?? item.status,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: _kAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: _kAccentSurface),

          // ── Bottom row: time + diagnosis + actions ──
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Time chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _kAccent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time,
                          size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        _formatTimeWithDay(item.time),
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Diagnosis
                Expanded(
                  child: Text(
                    item.diagnosis,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ),
                // Action icons
                _buildActionIcon(Icons.call, () => _callHardcodedNumber()),
                const SizedBox(width: 8),
                _buildActionIcon(Icons.message_outlined, () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Messaging ${item.patientName}...')),
                  );
                }),
                const SizedBox(width: 8),
                _buildActionIcon(
                  Icons.arrow_forward_ios_rounded,
                  () => _navigateToDetails(item),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Action icon ──

  Widget _buildActionIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: _kAccentSurface,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: _kAccent),
      ),
    );
  }

  // ── Navigate to patient details ──

  void _navigateToDetails(EmergencyAppointmentModel item) {
    final status = _mapStatusForDetails(item.status);

    final patient = NewPatientResponse(
      patientId: item.id,
      profile: Profile(
        name: item.patientName,
        age: '35',
        gender: 'Male',
        bloodGroup: 'O+',
      ),
      contact: Contact(
        phone: _hardcodedPhoneNumber,
        email: 'patient@email.com',
        address: '123 Main St',
      ),
      medicalHistory: MedicalHistory(
        historyNotes: 'None',
        currentMedications: 'None',
        allergies: 'None',
        lastVisitDate: '2024-01-01',
      ),
      appointment: Appointment(
        scheduledTime: item.time,
        diagnosis: item.diagnosis,
        symptoms: 'Emergency symptoms (${item.severity})',
        status: status,
      ),
    );

    final appointment = AppointmentModel(
      id: item.id,
      patientName: item.patientName,
      time: item.time,
      diagnosis: item.diagnosis,
      status: status,
    );

    Get.to(() => PatientDetails(patient: patient, appointment: appointment))
        ?.then((_) => _loadPersistedStatuses());
  }

  // ── Calendar ──

  Widget _buildCalendarDateFilter() {
    final firstOfMonth =
        DateTime(_selectedDate.year, _selectedDate.month, 1);
    final totalDays = _daysInMonth(_selectedDate);
    final leadingEmpty = firstOfMonth.weekday % 7;
    final totalCells = leadingEmpty + totalDays;
    final weekCount = (totalCells / 7).ceil();
    final monthYear =
        '${_monthLabel(_selectedDate.month)} ${_selectedDate.year}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month navigation
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  setState(() {
                    _selectedDate = DateTime(
                        _selectedDate.year, _selectedDate.month - 1, 1);
                  });
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _jumpToSelectedWeek());
                },
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.chevron_left_rounded, color: _kAccent),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    monthYear,
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
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _jumpToSelectedWeek());
                },
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.chevron_right_rounded, color: _kAccent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Day labels
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
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
          // Week swiper
          SizedBox(
            height: 36,
            child: PageView.builder(
              controller: _weekPageController,
              itemCount: weekCount,
              itemBuilder: (context, weekIndex) {
                return Row(
                  children: List.generate(7, (dayIndex) {
                    final cell = weekIndex * 7 + dayIndex;
                    final dayNumber = cell - leadingEmpty + 1;
                    if (dayNumber < 1 || dayNumber > totalDays) {
                      return const Expanded(child: SizedBox.shrink());
                    }
                    final date = DateTime(
                        _selectedDate.year, _selectedDate.month, dayNumber);
                    final isSelected =
                        DateUtils.isSameDay(date, _selectedDate);
                    return Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() => _selectedDate = date),
                        child: Center(
                          child: Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: _kAccent, width: 1.6)
                                  : null,
                            ),
                            child: Text(
                              '$dayNumber',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color:
                                    isSelected ? _kAccent : Colors.black87,
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
}
