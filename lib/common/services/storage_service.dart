import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized Storage Service
/// - User accounts & sessions: SharedPreferences only (no Firebase)
/// - Other local data (appointments, medicines): SharedPreferences
class StorageService {
  // Singleton pattern
  static StorageService? _instance;
  static SharedPreferences? _prefs;

  // Private constructor
  StorageService._();

  // Get singleton instance
  static Future<StorageService> getInstance() async {
    _instance ??= StorageService._();
    _prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // ==================== USER MANAGEMENT (SharedPreferences) ====================

  static const String _usersKey = 'users';
  static const String _currentUsernameKey = 'current_username';
  static const String _currentPhoneKey = 'current_phone';
  static const String _currentRoleKey = 'current_role';
  static const String _currentSpecialityKey = 'current_speciality';
  static const String _appointmentStatusPrefix = 'appointment_status_';
  static const String _patientNotesPrefix = 'patient_notes_';
  static const String _patientFilesPrefix = 'patient_files_';
  static const String _patientDetailsPrefix = 'patient_details_';
  static const String _patientSelfProfilePrefix = 'patient_self_profile_';
  static const String _patientBookingRequestsPrefix = 'patient_bookings_';

  /// Register new user in local storage.
  /// Users are stored as a String list: "username|password|role|speciality".
  Future<bool> saveUser({
    required String username,
    required String password,
    required String role,
    String speciality = "",
  }) async {
    try {
      final prefs = _prefs;
      if (prefs == null) return false;

      final List<String> users = prefs.getStringList(_usersKey) ?? [];

      // Prevent duplicate usernames.
      final exists = users.any((u) {
        final parts = u.split('|');
        return parts.isNotEmpty && parts[0] == username;
      });
      if (exists) {
        return false;
      }

      users.add('$username|$password|${role.toLowerCase()}|$speciality');
      return await prefs.setStringList(_usersKey, users);
    } catch (e) {
      print("❌ Error saving user locally: $e");
      return false;
    }
  }

  /// Sign in against locally stored users and return user profile.
  Future<Map<String, String>?> signIn(String username, String password) async {
    try {
      final prefs = _prefs;
      if (prefs == null) return null;

      final List<String> users = prefs.getStringList(_usersKey) ?? [];
      for (final u in users) {
        final parts = u.split('|');
        if (parts.length < 4) continue;
        final storedUsername = parts[0];
        final storedPassword = parts[1];
        final storedRole = parts[2];
        final storedSpeciality = parts[3];

        if (storedUsername == username && storedPassword == password) {
          // Persist current session.
          await prefs.setString(_currentUsernameKey, storedUsername);
          await prefs.setString(_currentPhoneKey, '');
          await prefs.setString(_currentRoleKey, storedRole);
          await prefs.setString(_currentSpecialityKey, storedSpeciality);

          return {
            'username': storedUsername,
            'role': storedRole,
            'speciality': storedSpeciality,
          };
        }
      }
      return null;
    } catch (e) {
      print("❌ Local sign in error: $e");
      return null;
    }
  }

  /// Fetch the current logged-in user's profile from local storage.
  Future<Map<String, String>?> getCurrentUserProfile() async {
    try {
      final prefs = _prefs;
      if (prefs == null) return null;

      final username = prefs.getString(_currentUsernameKey);
      if (username == null || username.isEmpty) return null;

      final phoneNumber = prefs.getString(_currentPhoneKey) ?? '';
      final role = prefs.getString(_currentRoleKey) ?? '';
      final speciality = prefs.getString(_currentSpecialityKey) ?? '';
      return {
        'username': username,
        'phoneNumber': phoneNumber,
        'role': role,
        'speciality': speciality,
      };
    } catch (e) {
      print("❌ Error getting local user profile: $e");
      return null;
    }
  }

  /// Set the current logged-in session directly (used for Firebase phone login).
  Future<void> setCurrentSession({
    required String username,
    required String role,
    String phoneNumber = '',
    String speciality = '',
  }) async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setString(_currentUsernameKey, username);
    await prefs.setString(_currentPhoneKey, phoneNumber);
    await prefs.setString(_currentRoleKey, role.toLowerCase());
    await prefs.setString(_currentSpecialityKey, speciality);
  }

  /// Convenience helper: returns the current doctor's display name (username).
  /// Falls back to null if no user is logged in or profile cannot be loaded.
  Future<String?> getDoctorName() async {
    final profile = await getCurrentUserProfile();
    return profile?['username'];
  }

  // ==================== LOGIN SESSION (SharedPreferences) ====================

  /// Check if a user is currently logged in
  bool isLoggedIn() {
    try {
      return (_prefs?.getString(_currentUsernameKey) ?? '').isNotEmpty;
    } catch (e) {
      print("❌ Error checking login status: $e");
      return false;
    }
  }

  /// Sign out
  Future<void> clearSession() async {
    try {
      await _prefs?.remove(_currentUsernameKey);
      await _prefs?.remove(_currentPhoneKey);
      await _prefs?.remove(_currentRoleKey);
      await _prefs?.remove(_currentSpecialityKey);
    } catch (e) {
      print("❌ Error clearing session: $e");
    }
  }

  /// Permanently delete the current logged-in account and related local data.
  Future<bool> deleteCurrentAccount() async {
    try {
      final prefs = _prefs;
      if (prefs == null) return false;

      final username = prefs.getString(_currentUsernameKey);
      if (username == null || username.isEmpty) return false;

      final role = prefs.getString(_currentRoleKey) ?? '';
      final users = prefs.getStringList(_usersKey) ?? <String>[];
      final filtered = users.where((u) {
        final parts = u.split('|');
        return parts.isEmpty || parts[0] != username;
      }).toList();
      await prefs.setStringList(_usersKey, filtered);

      // Remove role-specific/user-specific stored data.
      await prefs.remove('doctor_profile_image_$username');
      await prefs.remove('patient_profile_image_$username');
      await prefs.remove('$_patientSelfProfilePrefix$username');
      await prefs.remove('$_patientBookingRequestsPrefix$username');

      // If doctor, clear all appointment statuses and attached per-patient data.
      if (role.toLowerCase() == 'doctor') {
        final keys = prefs.getKeys();
        for (final key in keys) {
          if (key.startsWith(_appointmentStatusPrefix) ||
              key.startsWith(_patientNotesPrefix) ||
              key.startsWith(_patientFilesPrefix) ||
              key.startsWith(_patientDetailsPrefix)) {
            await prefs.remove(key);
          }
        }
      }

      await clearSession();
      return true;
    } catch (e) {
      print("❌ Error deleting current account: $e");
      return false;
    }
  }

  /// Update password for the current logged-in user.
  Future<bool> updatePassword(String newPassword) async {
    try {
      final prefs = _prefs;
      if (prefs == null) return false;

      final currentUsername = prefs.getString(_currentUsernameKey);
      if (currentUsername == null || currentUsername.isEmpty) return false;

      final List<String> users = prefs.getStringList(_usersKey) ?? [];
      bool updated = false;

      final updatedUsers = users.map((u) {
        final parts = u.split('|');
        if (parts.isNotEmpty && parts[0] == currentUsername) {
          updated = true;
          // Rebuild string with new password: username|newPassword|role|speciality
          // Note: parts[0]=name, parts[1]=pass, parts[2]=role, parts[3]=speciality
          String role = parts.length > 2 ? parts[2] : "";
          String spec = parts.length > 3 ? parts[3] : "";
          return '$currentUsername|$newPassword|$role|$spec';
        }
        return u;
      }).toList();

      if (updated) {
        return await prefs.setStringList(_usersKey, updatedUsers);
      }
      return false;
    } catch (e) {
      print("❌ Error updating password locally: $e");
      return false;
    }
  }

  /// Verify if the provided password matches the current user's password.
  Future<bool> verifyCurrentPassword(String currentPassword) async {
    try {
      final prefs = _prefs;
      if (prefs == null) return false;

      final currentUsername = prefs.getString(_currentUsernameKey);
      if (currentUsername == null || currentUsername.isEmpty) return false;

      final List<String> users = prefs.getStringList(_usersKey) ?? [];
      for (final u in users) {
        final parts = u.split('|');
        if (parts.length >= 2 && parts[0] == currentUsername) {
          return parts[1] == currentPassword;
        }
      }
      return false;
    } catch (e) {
      print("❌ Error verifying password: $e");
      return false;
    }
  }

  // ==================== GENERIC STORAGE METHODS (SharedPreferences) ====================

  /// Save String value
  Future<bool> setString(String key, String value) async {
    try {
      return await _prefs?.setString(key, value) ?? false;
    } catch (e) {
      print("❌ Error setting string '$key': $e");
      return false;
    }
  }

  /// Get String value
  String? getString(String key) {
    try {
      return _prefs?.getString(key);
    } catch (e) {
      print("❌ Error getting string '$key': $e");
      return null;
    }
  }

  /// Save bool value
  Future<bool> setBool(String key, bool value) async {
    try {
      return await _prefs?.setBool(key, value) ?? false;
    } catch (e) {
      print("❌ Error setting bool '$key': $e");
      return false;
    }
  }

  /// Get bool value
  bool? getBool(String key) {
    try {
      return _prefs?.getBool(key);
    } catch (e) {
      print("❌ Error getting bool '$key': $e");
      return null;
    }
  }

  /// Save int value
  Future<bool> setInt(String key, int value) async {
    try {
      return await _prefs?.setInt(key, value) ?? false;
    } catch (e) {
      print("❌ Error setting int '$key': $e");
      return false;
    }
  }

  /// Get int value
  int? getInt(String key) {
    try {
      return _prefs?.getInt(key);
    } catch (e) {
      print("❌ Error getting int '$key': $e");
      return null;
    }
  }

  /// Save double value
  Future<bool> setDouble(String key, double value) async {
    try {
      return await _prefs?.setDouble(key, value) ?? false;
    } catch (e) {
      print("❌ Error setting double '$key': $e");
      return false;
    }
  }

  /// Get double value
  double? getDouble(String key) {
    try {
      return _prefs?.getDouble(key);
    } catch (e) {
      print("❌ Error getting double '$key': $e");
      return null;
    }
  }

  /// Save String list
  Future<bool> setStringList(String key, List<String> value) async {
    try {
      return await _prefs?.setStringList(key, value) ?? false;
    } catch (e) {
      print("❌ Error setting string list '$key': $e");
      return false;
    }
  }

  /// Get String list
  List<String>? getStringList(String key) {
    try {
      return _prefs?.getStringList(key);
    } catch (e) {
      print("❌ Error getting string list '$key': $e");
      return null;
    }
  }

  /// Remove a key
  Future<bool> remove(String key) async {
    try {
      return await _prefs?.remove(key) ?? false;
    } catch (e) {
      print("❌ Error removing '$key': $e");
      return false;
    }
  }

  // ==================== APP PREFERENCES ====================

  /// Save selected language (e.g. 'en_US', 'hi_IN')
  Future<bool> saveLanguage(String languageCode) async {
    return await setString('app_language', languageCode);
  }

  /// Get selected language
  String getLanguage() {
    return getString('app_language') ?? 'en_US'; // Default to English
  }

  /// Save Dark Mode preference
  Future<bool> saveDarkMode(bool isDark) async {
    return await setBool('app_dark_mode', isDark);
  }

  /// Get Dark Mode preference
  bool getDarkMode() {
    return getBool('app_dark_mode') ?? false; // Default to light mode
  }

  // ==================== APPOINTMENTS ====================

  /// Save appointments
  Future<bool> saveAppointments(List<Map<String, String>> appointments) async {
    try {
      List<String> appointmentStrings = appointments.map((app) {
        return "${app['name']}:${app['time']}:${app['diagnosis']}";
      }).toList();
      return await setStringList("appointments", appointmentStrings);
    } catch (e) {
      print("❌ Error saving appointments: $e");
      return false;
    }
  }

  /// Get appointments
  List<Map<String, String>> getAppointments() {
    try {
      List<String>? appointmentStrings = getStringList("appointments");
      if (appointmentStrings == null) return [];
      return appointmentStrings.map((str) {
        List<String> parts = str.split(":");
        return {
          "name": parts.length > 0 ? parts[0] : "",
          "time": parts.length > 1 ? parts[1] : "",
          "diagnosis": parts.length > 2 ? parts[2] : "",
        };
      }).toList();
    } catch (e) {
      print("❌ Error getting appointments: $e");
      return [];
    }
  }

  /// Persist appointment status by its unique id.
  Future<bool> saveAppointmentStatus(String appointmentId, String status) {
    return setString("$_appointmentStatusPrefix$appointmentId", status);
  }

  /// Read persisted appointment status for a given id, or null if none.
  String? getAppointmentStatus(String appointmentId) {
    return getString("$_appointmentStatusPrefix$appointmentId");
  }

  /// Append a doctor note for a patient. Notes are stored as a String list.
  Future<bool> addPatientNote(String patientId, String note) async {
    try {
      final prefs = _prefs;
      if (prefs == null) return false;
      final key = "$_patientNotesPrefix$patientId";
      final existing = prefs.getStringList(key) ?? <String>[];
      final trimmed = note.trim();
      if (trimmed.isEmpty) return false;
      // Store as "ISO_TIMESTAMP|note" so we can display date+time later.
      final ts = DateTime.now().toIso8601String();
      existing.add("$ts|$trimmed");
      return await prefs.setStringList(key, existing);
    } catch (e) {
      print("❌ Error saving patient note: $e");
      return false;
    }
  }

  /// Get all saved doctor notes for a patient.
  List<String> getPatientNotes(String patientId) {
    try {
      final prefs = _prefs;
      if (prefs == null) return <String>[];
      final key = "$_patientNotesPrefix$patientId";
      return prefs.getStringList(key) ?? <String>[];
    } catch (e) {
      print("❌ Error getting patient notes: $e");
      return <String>[];
    }
  }

  /// Append an attached file (lab report, etc.) for a patient.
  /// Files are stored as JSON strings with {name, path, ts}.
  Future<bool> addPatientFile(
      String patientId, String name, String path) async {
    try {
      final prefs = _prefs;
      if (prefs == null) return false;
      final key = "$_patientFilesPrefix$patientId";
      final existing = prefs.getStringList(key) ?? <String>[];
      final ts = DateTime.now().toIso8601String();
      final entry = jsonEncode({
        'name': name,
        'path': path,
        'ts': ts,
      });
      existing.add(entry);
      return await prefs.setStringList(key, existing);
    } catch (e) {
      print("❌ Error saving patient file: $e");
      return false;
    }
  }

  /// Get all saved files for a patient as maps: {name, path, ts}.
  List<Map<String, String>> getPatientFiles(String patientId) {
    try {
      final prefs = _prefs;
      if (prefs == null) return <Map<String, String>>[];
      final key = "$_patientFilesPrefix$patientId";
      final entries = prefs.getStringList(key) ?? <String>[];
      final List<Map<String, String>> files = [];
      for (final raw in entries) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            files.add({
              'name': decoded['name']?.toString() ?? '',
              'path': decoded['path']?.toString() ?? '',
              'ts': decoded['ts']?.toString() ?? '',
            });
          }
        } catch (_) {
          // Skip malformed entries.
        }
      }
      return files;
    } catch (e) {
      print("❌ Error getting patient files: $e");
      return <Map<String, String>>[];
    }
  }

  /// Persist editable patient details (contact info, overview, current visit).
  /// Data is stored as JSON map of string fields keyed by patient id.
  Future<bool> savePatientDetails(
      String patientId, Map<String, String> details) async {
    try {
      final prefs = _prefs;
      if (prefs == null) return false;
      final key = "$_patientDetailsPrefix$patientId";
      final json = jsonEncode(details);
      return await prefs.setString(key, json);
    } catch (e) {
      print("❌ Error saving patient details: $e");
      return false;
    }
  }

  /// Load persisted patient details, or null if none.
  Map<String, String>? getPatientDetails(String patientId) {
    try {
      final prefs = _prefs;
      if (prefs == null) return null;
      final key = "$_patientDetailsPrefix$patientId";
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return decoded.map<String, String>(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    } catch (e) {
      print("❌ Error getting patient details: $e");
      return null;
    }
  }

  // ==================== PATIENT APP (SELF-SERVICE) ====================

  /// Patient's own profile (mirrors fields shown to doctors: demographics, contact, medical).
  /// Keyed by login username.
  Future<bool> savePatientSelfProfile(
      String username, Map<String, String> profile) async {
    try {
      final prefs = _prefs;
      if (prefs == null || username.isEmpty) return false;
      final key = '$_patientSelfProfilePrefix$username';
      return await prefs.setString(key, jsonEncode(profile));
    } catch (e) {
      print("❌ Error saving patient self profile: $e");
      return false;
    }
  }

  Map<String, String>? getPatientSelfProfile(String username) {
    try {
      final prefs = _prefs;
      if (prefs == null || username.isEmpty) return null;
      final key = '$_patientSelfProfilePrefix$username';
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return decoded.map<String, String>(
        (k, v) => MapEntry(k.toString(), v.toString()),
      );
    } catch (e) {
      print("❌ Error reading patient self profile: $e");
      return null;
    }
  }

  /// Append a booking request (local demo until backend exists).
  Future<bool> addPatientBookingRequest(
      String username, Map<String, String> request) async {
    try {
      final prefs = _prefs;
      if (prefs == null || username.isEmpty) return false;
      final list = getPatientBookingRequests(username);
      list.add(request);
      final key = '$_patientBookingRequestsPrefix$username';
      final encoded =
          jsonEncode(list.map((m) => m).toList());
      return await prefs.setString(key, encoded);
    } catch (e) {
      print("❌ Error saving booking request: $e");
      return false;
    }
  }

  List<Map<String, String>> getPatientBookingRequests(String username) {
    try {
      final prefs = _prefs;
      if (prefs == null || username.isEmpty) return [];
      final key = '$_patientBookingRequestsPrefix$username';
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.map<Map<String, String>>((e) {
        if (e is! Map) return <String, String>{};
        return e.map((k, v) => MapEntry(k.toString(), v.toString()));
      }).toList();
    } catch (e) {
      print("❌ Error reading booking requests: $e");
      return [];
    }
  }

  // ==================== MEDICINES ====================

  /// Save medicines
  Future<bool> saveMedicines(List<Map<String, String>> medicines) async {
    try {
      List<String> medicineStrings = medicines.map((med) {
        return "${med['id']}:${med['title']}:${med['available']}:${med['count']}";
      }).toList();
      return await setStringList("medicines", medicineStrings);
    } catch (e) {
      print("❌ Error saving medicines: $e");
      return false;
    }
  }

  /// Get medicines
  List<Map<String, String>> getMedicines() {
    try {
      List<String>? medicineStrings = getStringList("medicines");
      if (medicineStrings == null) return [];
      return medicineStrings.map((str) {
        List<String> parts = str.split(":");
        return {
          "id": parts.length > 0 ? parts[0] : "",
          "title": parts.length > 1 ? parts[1] : "",
          "available": parts.length > 2 ? parts[2] : "",
          "count": parts.length > 3 ? parts[3] : "",
        };
      }).toList();
    } catch (e) {
      print("❌ Error getting medicines: $e");
      return [];
    }
  }
}
