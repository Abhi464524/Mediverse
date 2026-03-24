import 'package:mediverse/feature/patientsPages/model/patient_repository.dart';
import 'package:mediverse/feature/patientsPages/model/patient_models.dart';
import 'package:mediverse/feature/patientsPages/view/patient_doctor_details_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// List of doctors. Patient can view details and then book.
class PatientDoctorsPage extends StatefulWidget {
  const PatientDoctorsPage({super.key});

  @override
  State<PatientDoctorsPage> createState() => _PatientDoctorsPageState();
}

class _PatientDoctorsPageState extends State<PatientDoctorsPage> {
  final PatientRepository _repository = PatientRepository.instance;
  List<PatientDoctor> _doctors = <PatientDoctor>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() => _loading = true);
    final doctors = await _repository.getAvailableDoctors();
    if (!mounted) return;
    setState(() {
      _doctors = doctors;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Select doctor',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6B9AC4)))
          : _doctors.isEmpty
              ? Center(
                  child: Text(
                    'No doctors available right now.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF6B9AC4),
                  onRefresh: _loadDoctors,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: _doctors.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final d = _doctors[i];
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            Get.to(
                              () => PatientDoctorDetailsPage(doctor: d),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Color(0xFFE8F0FE),
                                  child: Icon(Icons.person, color: Color(0xFF6B9AC4)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        d.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        d.specialty,
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${d.experience} · ${d.clinic}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF7E6),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '★ ${d.rating}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'View details',
                                      style: TextStyle(
                                        color: Color(0xFF6B9AC4),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
