import 'package:mediverse/feature/patientsPages/model/patient_repository.dart';
import 'package:mediverse/feature/patientsPages/model/patient_models.dart';
import 'package:mediverse/feature/patientsPages/view/patient_notifications_view.dart';
import 'package:mediverse/feature/patientsPages/view/patient_book_appointment_view.dart';
import 'package:mediverse/feature/patientsPages/view/patient_doctors_view.dart';
import 'package:mediverse/feature/patientsPages/view/patient_footer_view.dart';
import 'package:mediverse/feature/patientsPages/view/patient_profile_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

class PatientHomePage extends StatefulWidget {
  final String name;
  const PatientHomePage({super.key, required this.name});

  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  final PatientRepository _repository = PatientRepository.instance;
  String patientName = "";
  int _totalBookings = 0;
  int _pendingCount = 0;
  List<PatientDoctor> _featuredDoctors = [];
  final PageController _pageController = PageController();
  Timer? _carouselTimer;

  @override
  void initState() {
    super.initState();
    patientName = widget.name;
    _loadNextBooking();
    _startCarousel();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startCarousel() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_featuredDoctors.isNotEmpty) {
        int nextItem = (_pageController.page?.toInt() ?? 0) + 1;
        if (nextItem >= _featuredDoctors.length) {
          nextItem = 0;
        }
        _pageController.animateToPage(
          nextItem,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadNextBooking() async {
    if (!mounted) return;
    final summary = await _repository.getHomeSummary();
    if (!mounted) return;
    setState(() {
      _totalBookings = summary.totalBookings;
      _pendingCount = summary.pendingCount;
    });
    // Fetch doctors for carousel
    final doctors = await _repository.getAvailableDoctors();
    if (!mounted) return;
    setState(() {
      _featuredDoctors = doctors.take(5).toList();
    });
  }

  String _todayLine() {
    final d = DateTime.now();
    const w = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${w[d.weekday - 1]}, ${m[d.month - 1]} ${d.day}, ${d.year}';
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
                // _chooseDoctorCard(),
                _bookingOptionsSection(),
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
          border: Border.all(
              color: const Color(0xFF6B9AC4).withValues(alpha: 0.22)),
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

  Widget _bookingOptionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _bookingOptionCard(
                  title: 'Physical\nAppointment',
                  subtitle: 'Clinic visit',
                  icon: Icons.local_hospital_rounded,
                  color: const Color(0xFF6B9AC4),
                  onTap: () async {
                    await Get.to(() => const BookAppointmentPage(
                          initialVisitType: 'In-person consultation',
                        ));
                    _loadNextBooking();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _bookingOptionCard(
                  title: 'Instant Video\nConsult',
                  subtitle: 'Online visit',
                  icon: Icons.videocam_rounded,
                  color: const Color(0xFF6A9C89),
                  onTap: () async {
                    await Get.to(() => const BookAppointmentPage(
                          initialVisitType: 'Video consultation',
                        ));
                    _loadNextBooking();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _bookingOptionCard(
            title: 'Emergency / SOS',
            subtitle: 'Immediate medical attention',
            icon: Icons.emergency_rounded,
            color: const Color(0xFFE53935),
            isWide: true,
            onTap: () {
              Get.snackbar(
                'Emergency SOS',
                'Connecting to emergency services...',
                backgroundColor: const Color(0xFFFFEBEE),
                colorText: const Color(0xFFB71C1C),
                icon: const Icon(Icons.emergency_share, color: Color(0xFFB71C1C)),
                duration: const Duration(seconds: 4),
              );
              // TODO: Navigate to emergency booking or trigger SOS logic
            },
          ),
        ],
      ),
    );
  }

  Widget _bookingOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isWide = false,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: isWide ? double.infinity : null,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5EDF6)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: isWide
              ? Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: color.withOpacity(0.5)),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        height: 1.2,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // Widget _chooseDoctorCard() {
  //   const accent = Color(0xFF6B9AC4);
  //   return Padding(
  //     padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
  //     child: Material(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(16),
  //       child: InkWell(
  //         borderRadius: BorderRadius.circular(16),
  //         onTap: () async {
  //           await Get.to(() => const PatientDoctorsPage());
  //           _loadNextBooking();
  //         },
  //         child: Container(
  //           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  //           decoration: BoxDecoration(
  //             borderRadius: BorderRadius.circular(16),
  //             border: Border.all(color: const Color(0xFFE5EDF6)),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: Colors.black.withValues(alpha: 0.03),
  //                 blurRadius: 6,
  //                 offset: const Offset(0, 2),
  //               ),
  //             ],
  //           ),
  //           child: Row(
  //             children: [
  //               Container(
  //                 padding: const EdgeInsets.all(10),
  //                 decoration: BoxDecoration(
  //                   color: const Color(0xFFE8F4FC),
  //                   borderRadius: BorderRadius.circular(10),
  //                 ),
  //                 child: const Icon(
  //                   Icons.medical_services_outlined,
  //                   color: accent,
  //                 ),
  //               ),
  //               const SizedBox(width: 12),
  //               const Expanded(
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Text(
  //                       'Choose a doctor',
  //                       style: TextStyle(
  //                         fontWeight: FontWeight.bold,
  //                         fontFamily: 'Poppins',
  //                         fontSize: 16,
  //                       ),
  //                     ),
  //                     SizedBox(height: 2),
  //                     Text(
  //                       'Select preferred doctor and then book',
  //                       style: TextStyle(fontSize: 12, color: Colors.black54),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //               const Icon(Icons.chevron_right, color: Colors.black45),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

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
              Text("Doctors", style: TextStyle(fontWeight: FontWeight.w500)),
              TextButton(
                onPressed: () async {
                  await Get.to(() => const PatientDoctorsPage());
                  _loadNextBooking();
                },
                child: const Text('See all'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: _featuredDoctors.isEmpty
                ? _doctorCardPlaceholder()
                : PageView.builder(
                    controller: _pageController,
                    itemCount: _featuredDoctors.length,
                    itemBuilder: (context, index) {
                      return _doctorCarouselItem(_featuredDoctors[index]);
                    },
                  ),
          ),
          if (_featuredDoctors.length > 1) ...[
            const SizedBox(height: 10),
            Center(
              child: AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  int current = 0;
                  try {
                    current = _pageController.page?.round() ?? 0;
                  } catch (_) {}
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _featuredDoctors.length,
                      (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: current == i ? 12 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: current == i
                              ? const Color(0xFF6B9AC4)
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _doctorCardPlaceholder() {
    return _doctorCarouselItem(const PatientDoctor(
      id: '0',
      name: 'Dr. Shubham Chaudhary',
      specialty: 'Cardiologist',
      experience: '10 years',
      clinic: 'Mediverse Clinic',
      clinicPhone: '',
      rating: '4.5',
    ));
  }

  Widget _doctorCarouselItem(PatientDoctor d) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA), // Soft Whisper White
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4FC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.medical_information,
                  size: 32,
                  color: Color(0xFF9AC6C5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      d.specialty,
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          d.rating,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          d.experience,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: Color(0xFF9AC6C5),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          d.clinic,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    await Get.to(() => const PatientDoctorsPage());
                    _loadNextBooking();
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color(0xFF6B9AC4),
                    ),
                    child: const Text(
                      "Book now",
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
    );
  }
}
