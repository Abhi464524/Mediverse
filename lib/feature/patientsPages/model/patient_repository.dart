import 'package:mediverse/common/services/storage_service.dart';
import 'package:mediverse/feature/patientsPages/model/patient_models.dart';

abstract class PatientRepository {
  static PatientRepository instance = LocalPatientRepository();

  Future<String?> currentUsername();
  Future<List<PatientDoctor>> getAvailableDoctors();
  Future<PatientProfileData?> getProfile();
  Future<bool> saveProfile(PatientProfileData profile);
  Future<List<PatientBooking>> getBookings();
  Future<PatientHomeSummary> getHomeSummary();
  Future<bool> createBooking(PatientBooking booking);
  Future<List<PatientSlot>> getSlotsForDate(DateTime date);
}

class LocalPatientRepository implements PatientRepository {
  // Temporary local fallback slot source.
  static const List<String> _baseSlots = <String>[
    '10:00 AM',
    '11:30 AM',
    '02:00 PM',
    '04:15 PM',
    '06:00 PM',
  ];
  static const List<PatientDoctor> _demoDoctors = <PatientDoctor>[
    PatientDoctor(
      id: 'doc_1',
      name: 'Dr. Shubham Chaudhary',
      specialty: 'Cardiologist',
      experience: '8 years',
      clinic: 'City Heart Clinic',
      clinicPhone: '+91 7900464524',
      rating: '4.7',
    ),
    PatientDoctor(
      id: 'doc_2',
      name: 'Dr. Aditi Verma',
      specialty: 'Dermatologist',
      experience: '6 years',
      clinic: 'SkinCare Center',
      clinicPhone: '+91 7900464525',
      rating: '4.6',
    ),
    PatientDoctor(
      id: 'doc_3',
      name: 'Dr. Shruti Chaudhary',
      specialty: 'General Physician',
      experience: '10 years',
      clinic: 'Health Plus Clinic',
      clinicPhone: '+91 7900464526',
      rating: '4.8',
    ),
  ];

  @override
  Future<String?> currentUsername() async {
    final storage = await StorageService.getInstance();
    final user = await storage.getCurrentUserProfile();
    final username = user?['username'];
    if (username == null || username.isEmpty) return null;
    return username;
  }

  @override
  Future<List<PatientDoctor>> getAvailableDoctors() async {
    // TODO(backend): replace with doctor listing API.
    return _demoDoctors;
  }

  @override
  Future<PatientProfileData?> getProfile() async {
    final username = await currentUsername();
    if (username == null) return null;
    final storage = await StorageService.getInstance();
    final map = storage.getPatientSelfProfile(username);
    if (map == null) return null;
    return PatientProfileData.fromStorageMap(map);
  }

  @override
  Future<bool> saveProfile(PatientProfileData profile) async {
    final username = await currentUsername();
    if (username == null) return false;
    final storage = await StorageService.getInstance();
    return storage.savePatientSelfProfile(username, profile.toStorageMap());
  }

  @override
  Future<List<PatientBooking>> getBookings() async {
    final username = await currentUsername();
    if (username == null) return <PatientBooking>[];
    final storage = await StorageService.getInstance();
    final list = storage.getPatientBookingRequests(username);
    return list.map(PatientBooking.fromStorageMap).toList();
  }

  @override
  Future<PatientHomeSummary> getHomeSummary() async {
    final bookings = await getBookings();
    final pending = bookings.where((b) {
      final s = b.status.toLowerCase();
      return s.contains('pending') || s == 'scheduled';
    }).length;
    return PatientHomeSummary(
      totalBookings: bookings.length,
      pendingCount: pending,
      latestBooking: bookings.isEmpty ? null : bookings.last,
    );
  }

  @override
  Future<bool> createBooking(PatientBooking booking) async {
    final username = await currentUsername();
    if (username == null) return false;
    final storage = await StorageService.getInstance();
    return storage.addPatientBookingRequest(username, booking.toStorageMap());
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _normalizeTime(String raw) {
    final input = raw.trim();
    if (input.isEmpty) return '';
    final amPmMatch =
        RegExp(r'^(\d{1,2}):(\d{2})\s*([APap][Mm])$').firstMatch(input);
    if (amPmMatch != null) {
      final hour = int.tryParse(amPmMatch.group(1) ?? '') ?? 0;
      final minute = int.tryParse(amPmMatch.group(2) ?? '') ?? 0;
      final period = (amPmMatch.group(3) ?? '').toUpperCase();
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
    }
    return input.toUpperCase();
  }

  @override
  Future<List<PatientSlot>> getSlotsForDate(DateTime date) async {
    // TODO(backend): replace this with API response mapping.
    final bookings = await getBookings();
    final key = _dateKey(date);
    final taken = <String>{};
    for (final booking in bookings) {
      if (booking.preferredDate != key) continue;
      if (booking.status.toLowerCase().contains('cancel')) continue;
      final normalized = _normalizeTime(booking.preferredTime);
      if (normalized.isNotEmpty) taken.add(normalized);
    }
    return _baseSlots.map((slot) {
      final normalized = _normalizeTime(slot);
      return PatientSlot(label: normalized, isBooked: taken.contains(normalized));
    }).toList();
  }
}
