import 'package:mediverse/feature/patientsPages/model/patient_repository.dart';
import 'package:mediverse/feature/patientsPages/model/patient_models.dart';
import 'package:mediverse/feature/patientsPages/view/patient_book_appointment_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Lists the patient's bookings; tap a card for full appointment details.
class PatientMyAppointmentsPage extends StatefulWidget {
  const PatientMyAppointmentsPage({super.key});

  @override
  State<PatientMyAppointmentsPage> createState() =>
      _PatientMyAppointmentsPageState();
}

class _PatientMyAppointmentsPageState extends State<PatientMyAppointmentsPage> {
  final PatientRepository _repository = PatientRepository.instance;
  List<PatientBooking> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final list = await _repository.getBookings();
    if (!mounted) return;
    setState(() {
      _items = list.reversed.toList();
      _loading = false;
    });
  }

  void _showAppointmentDetails(PatientBooking b) {
    String fmt(String value) => value.trim().isEmpty ? '—' : value;

    String submitted = fmt(b.submittedAt);
    try {
      final dt = DateTime.tryParse(b.submittedAt);
      if (dt != null) {
        submitted =
            '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {}

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, scroll) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: ListView(
                controller: scroll,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Appointment details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 20),
                  _detailRow('Doctor', fmt(b.doctorName)),
                  _detailRow('Specialty', fmt(b.doctorSpecialty)),
                  _detailRow('Status', fmt(b.status)),
                  _detailRow('Requested date', fmt(b.preferredDate)),
                  _detailRow('Requested time', fmt(b.preferredTime)),
                  _detailRow('Visit type', fmt(b.visitType)),
                  _detailRow('Reason / symptoms', fmt(b.symptomsReason)),
                  const Divider(height: 28),
                  _detailRow('Your name', fmt(b.patientName)),
                  _detailRow('Phone', fmt(b.patientPhone)),
                  _detailRow('Email', fmt(b.patientEmail)),
                  _detailRow('Submitted', submitted),
                  const SizedBox(height: 16),
                  Text(
                    'When your clinic connects this app, status updates will appear here.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF6B9AC4);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My appointments',
            style: TextStyle(
                fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Get.to(() => const BookAppointmentPage());
          _refresh();
        },
        backgroundColor: accent,
        icon: const Icon(Icons.add),
        label: const Text('Book'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: accent))
          : _items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No booking requests yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Book an appointment with $kPatientAppDoctorName — your requests will show here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () async {
                            await Get.to(() => const BookAppointmentPage());
                            _refresh();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                          ),
                          icon: const Icon(Icons.calendar_month),
                          label: const Text('Book appointment'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: accent,
                  onRefresh: _refresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final b = _items[i];
                      final status = b.status;
                      Color statusColor = Colors.orange;
                      if (status.toLowerCase().contains('confirm')) {
                        statusColor = Colors.green;
                      } else if (status.toLowerCase().contains('cancel')) {
                        statusColor = Colors.red;
                      }
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _showAppointmentDetails(b),
                          child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      b.doctorName.isEmpty
                                          ? kPatientAppDoctorName
                                          : b.doctorName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Poppins',
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                b.doctorSpecialty.isEmpty
                                    ? kPatientAppDoctorSpecialty
                                    : b.doctorSpecialty,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                              const Divider(height: 20),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      size: 16, color: Colors.grey.shade600),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${b.preferredDate} · ${b.preferredTime}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.medical_information_outlined,
                                      size: 16, color: Colors.grey.shade600),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      b.visitType,
                                      style: TextStyle(
                                          color: Colors.grey.shade800),
                                    ),
                                  ),
                                ],
                              ),
                              if (b.symptomsReason.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  b.symptomsReason,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                'Tap for full details',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: const Color(0xFF6B9AC4),
                                  fontWeight: FontWeight.w600,
                                ),
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
