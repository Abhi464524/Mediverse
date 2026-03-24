import 'package:mediverse/feature/patientsPages/model/patient_repository.dart';
import 'package:mediverse/feature/patientsPages/model/patient_models.dart';
import 'package:mediverse/feature/patientsPages/view/patient_notifications_view.dart';
import 'package:mediverse/feature/patientsPages/view/patient_book_appointment_view.dart';
import 'package:mediverse/feature/patientsPages/view/patient_doctors_view.dart';
import 'package:mediverse/feature/patientsPages/view/patient_footer_view.dart';
import 'package:mediverse/feature/patientsPages/view/patient_profile_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PatientHomePage extends StatefulWidget {
  final String name;
  const PatientHomePage({super.key, required this.name});

  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  final PatientRepository _repository = PatientRepository.instance;
  String patientName = "";
  PatientBooking? _nextBooking;
  int _totalBookings = 0;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    patientName = widget.name;
    _loadNextBooking();
  }

  Future<void> _loadNextBooking() async {
    if (!mounted) return;
    final summary = await _repository.getHomeSummary();
    if (!mounted) return;
    setState(() {
      _totalBookings = summary.totalBookings;
      _pendingCount = summary.pendingCount;
      _nextBooking = summary.latestBooking;
    });
  }

  String _todayLine() {
    final d = DateTime.now();
    const w = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${w[d.weekday - 1]}, ${m[d.month - 1]} ${d.day}, ${d.year}';
  }

  Color _statusColor(String? status) {
    final s = (status ?? '').toLowerCase();
    if (s.contains('confirm') || s.contains('done')) {
      return Colors.green.shade700;
    }
    if (s.contains('cancel')) return Colors.red.shade700;
    return Colors.orange.shade800;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: PreferredSize(
          // Must fit: padding + icon row + welcome + date (avoid Column overflow in AppBar).
          preferredSize: const Size.fromHeight(168),
          child: _buildProfileCard(),
        ),
        body: RefreshIndicator(
          color: const Color(0xFF6B9AC4),
          onRefresh: _loadNextBooking,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _quickStatsRow(),
                _tipBanner(),
                _chooseDoctorCard(),
                _bookAppointmentCard(),
                _upcomingAppointments(),
                const SizedBox(height: 88),
              ],
            ),
          ),
        ),
        bottomSheet: PatientFooterPage(
          onAppointments: _loadNextBooking,
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.only(left: 20, top: 44, right: 20, bottom: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFECF5FF),
            Color(0xFFF8FAFC),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                  onPressed: () {
                    Get.to(PatientProfilePage(name: patientName));
                  },
                  icon: Icon(
                    Icons.person,
                    color: const Color(0xFF6B9AC4),
                  )), // Soft Azure
              IconButton(
                  onPressed: () {
                    Get.to(const PatientNotificationsPage());
                  },
                  icon: Icon(
                    Icons.notifications_active,
                    color: const Color(0xFF6B9AC4),
                  )), // Soft Azure
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Welcome $patientName",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _todayLine(),
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickStatsRow() {
    const accent = Color(0xFF6B9AC4);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: _statTile(
              icon: Icons.event_available_rounded,
              label: 'My requests',
              value: '$_totalBookings',
              accent: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _statTile(
              icon: Icons.hourglass_top_rounded,
              label: 'Awaiting reply',
              value: '$_pendingCount',
              accent: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EDF6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF7FF),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: const Color(0xFF6B9AC4).withValues(alpha: 0.22)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lightbulb_outline_rounded,
                color: Color(0xFF6B9AC4), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tip: Choose your doctor first, then book your preferred slot for faster confirmation.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bookAppointmentCard() {
    const accent = Color(0xFF6B9AC4);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            await Get.to(() => const BookAppointmentPage());
            _loadNextBooking();
          },
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent,
                  const Color(0xFF7AA8D0),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.calendar_month_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Book an appointment',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Share your details & preferred time with the clinic',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chooseDoctorCard() {
    const accent = Color(0xFF6B9AC4);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Get.to(() => const PatientDoctorsPage());
            _loadNextBooking();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5EDF6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F4FC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.medical_services_outlined,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose a doctor',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Select preferred doctor and then book',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black45),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _upcomingAppointments() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 2, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EDF6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Doctors",
                  style: TextStyle(fontWeight: FontWeight.w500)),
              TextButton(
                onPressed: () async {
                  await Get.to(() => const PatientDoctorsPage());
                  _loadNextBooking();
                },
                child: const Text('See all'),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA), // Soft Whisper White
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.medical_information,
                      size: 50,
                      color: const Color(0xFF9AC6C5),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            kPatientAppDoctorName,
                            style: TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            kPatientAppDoctorSpecialty,
                            style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_nextBooking != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusColor(_nextBooking!.status)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _nextBooking!.status,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _statusColor(_nextBooking!.status),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (_nextBooking != null &&
                    _nextBooking!.symptomsReason.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Reason: ${_nextBooking!.symptomsReason}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.calendar_month,
                              size: 20,
                              color: const Color(0xFF9AC6C5),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _nextBooking != null
                                    ? "${_nextBooking!.preferredDate} · ${_nextBooking!.preferredTime}"
                                    : "No booking yet — tap Book above",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          await Get.to(() => const PatientDoctorsPage());
                          _loadNextBooking();
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 8, horizontal: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: const Color(0xFF6B9AC4),
                          ),
                          child: Text(
                            "View doctors",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
