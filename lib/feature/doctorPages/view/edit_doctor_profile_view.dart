import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:get/get.dart';
import 'package:mediverse/common/services/storage_service.dart';
import 'package:mediverse/feature/doctorPages/controller/doctor_profile_controller.dart';
import 'package:mediverse/feature/doctorPages/model/doctor_profile_model.dart';

class EditDoctorProfileView extends StatefulWidget {
  final String currentName;
  final String currentSpecialization;
  final Function(String, String) onSave;

  const EditDoctorProfileView({
    super.key,
    required this.currentName,
    required this.currentSpecialization,
    required this.onSave,
  });

  @override
  State<EditDoctorProfileView> createState() => _EditDoctorProfileViewState();
}

class _EditDoctorProfileViewState extends State<EditDoctorProfileView> {
  int? _currentDoctorId;

  late TextEditingController _nameController;
  late TextEditingController _specializationController;
  final ImagePicker _imagePicker = ImagePicker();
  File? _profileImageFile;
  String? _currentUsername;

  // New fields
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _clinicAddressController =
      TextEditingController();
  final TextEditingController _consultationFeeController =
      TextEditingController();
  final DoctorProfileController _doctorProfileController =
      Get.put(DoctorProfileController());

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _specializationController =
        TextEditingController(text: widget.currentSpecialization);
    _loadDoctorIdAndData();
    _loadSessionProfileDetails();
    _loadSavedProfileImage();
  }

  Future<void> _loadDoctorIdAndData() async {
    try {
      final storage = await StorageService.getInstance();
      final profile = await storage.getCurrentUserProfile();
      final rawId = profile?['userId'] ?? profile?['id'];
      if (rawId != null) {
        setState(() {
          _currentDoctorId = int.tryParse(rawId.toString());
        });
        if (_currentDoctorId != null) {
          _loadCachedDoctorProfile();
          // Also fetch fresh from API
          _fetchFreshProfile();
        }
      }
    } catch (e) {
      if (kDebugMode) print("Error loading doctor ID: $e");
    }
  }

  Future<void> _fetchFreshProfile() async {
    if (_currentDoctorId == null) return;
    final profile =
        await _doctorProfileController.fetchDoctorProfile(_currentDoctorId!);
    if (profile != null && mounted) {
      setState(() {
        _applyProfileData(profile);
      });
    }
  }

  Future<void> _loadSessionProfileDetails() async {
    try {
      final storage = await StorageService.getInstance();
      final profile = await storage.getCurrentUserProfile();
      if (!mounted || profile == null) return;
      final phone = profile['phoneNumber'] ?? '';
      if (phone.isNotEmpty) {
        setState(() {
          _phoneController.text = phone;
        });
      }
    } catch (_) {
      // Ignore profile load failures and keep default values.
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specializationController.dispose();
    _experienceController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _clinicAddressController.dispose();
    _consultationFeeController.dispose();
    super.dispose();
  }

  int _extractInt(String value, {int fallback = 0}) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? fallback;
  }

  void _applyProfileData(DoctorProfile profile) {
    _nameController.text =
        profile.personalInfo?.fullName ?? _nameController.text;
    _specializationController.text =
        profile.personalInfo?.specialization ?? _specializationController.text;
    _experienceController.text =
        profile.personalInfo?.experienceYears?.toString() ??
            _experienceController.text;
    _phoneController.text =
        profile.contactDetails?.phoneNumber ?? _phoneController.text;
    _emailController.text =
        profile.contactDetails?.email ?? _emailController.text;
    _clinicAddressController.text =
        profile.clinicDetails?.clinicAddress ?? _clinicAddressController.text;
    _consultationFeeController.text =
        profile.clinicDetails?.consultationFee?.toString() ??
            _consultationFeeController.text;
  }

  Future<void> _loadCachedDoctorProfile() async {
    try {
      if (_currentDoctorId == null) return;
      final storage = await StorageService.getInstance();
      final raw = storage.getString(_doctorProfileCacheKey(_currentDoctorId!));
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      if (!mounted) return;
      setState(() {
        _experienceController.text =
            (decoded['experienceYears'] ?? _experienceController.text)
                .toString();
        _emailController.text =
            (decoded['email'] ?? _emailController.text).toString();
        _clinicAddressController.text =
            (decoded['clinicAddress'] ?? _clinicAddressController.text)
                .toString();
        _consultationFeeController.text =
            (decoded['consultationFee'] ?? _consultationFeeController.text)
                .toString();
      });
    } catch (_) {
      // Ignore cache parse/read failures.
    }
  }

  String _doctorProfileCacheKey(int doctorId) =>
      'doctor_profile_cache_$doctorId';

  Future<void> _saveDoctorProfile() async {
    if (_doctorProfileController.isSaving.value) return;
    if (_currentDoctorId == null) return;

    try {
      final profile = DoctorProfile(
        doctorId: _currentDoctorId,
        personalInfo: PersonalInfo(
          fullName: _nameController.text.trim(),
          specialization: _specializationController.text.trim(),
          experienceYears: _extractInt(_experienceController.text, fallback: 0),
        ),
        contactDetails: ContactDetails(
          phoneNumber: _phoneController.text.trim(),
          email: _emailController.text.trim(),
        ),
        clinicDetails: ClinicDetails(
          clinicAddress: _clinicAddressController.text.trim(),
          consultationFee:
              _extractInt(_consultationFeeController.text, fallback: 0),
        ),
      );

      final saved = await _doctorProfileController.saveDoctorProfile(profile);
      if (saved != null) {
        _applyProfileData(saved);
        
        // Cache locally
        final storage = await StorageService.getInstance();
        await storage.setString(_doctorProfileCacheKey(_currentDoctorId!),
            jsonEncode(saved.toJson()));
        
        widget.onSave(_nameController.text, _specializationController.text);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    }
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile == null) return;
      final file = File(pickedFile.path);
      setState(() {
        _profileImageFile = file;
      });
      await _saveProfileImagePath(file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to pick image: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  String _profileImageKey(String username) => "doctor_profile_image_$username";

  Future<void> _loadSavedProfileImage() async {
    try {
      final storage = await StorageService.getInstance();
      final profile = await storage.getCurrentUserProfile();
      final username = profile?['username'];
      if (username == null || username.isEmpty) return;
      _currentUsername = username;
      final savedPath = storage.getString(_profileImageKey(username));
      if (savedPath == null || savedPath.isEmpty) return;
      final file = File(savedPath);
      if (!file.existsSync()) return;
      if (!mounted) return;
      setState(() {
        _profileImageFile = file;
      });
    } catch (_) {
      // Ignore failures and continue with default avatar.
    }
  }

  Future<void> _saveProfileImagePath(String path) async {
    final storage = await StorageService.getInstance();
    String? username = _currentUsername;
    if (username == null || username.isEmpty) {
      final profile = await storage.getCurrentUserProfile();
      username = profile?['username'];
      _currentUsername = username;
    }
    if (username == null || username.isEmpty) return;
    await storage.setString(_profileImageKey(username), path);
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickProfileImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickProfileImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF9), // Very pale mint background
      appBar: AppBar(
        title: const Text("Edit Profile",
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Profile Picture Placeholder
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFFC4DAD2), width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Color(0xFFC4DAD2),
                          backgroundImage: _profileImageFile != null
                              ? FileImage(_profileImageFile!)
                              : null,
                          child: _profileImageFile == null
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _showImageSourceSheet,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF6A9C89),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 30),
                        _buildSectionTitle("Personal Information"),
                        const SizedBox(height: 15),
                        _buildTextField(
                            "Full Name", _nameController, Icons.person_outline),
                        const SizedBox(height: 15),
                        _buildTextField(
                            "Specialization",
                            _specializationController,
                            Icons.medical_services_outlined),
                        const SizedBox(height: 15),
                        _buildTextField("Years of Experience",
                            _experienceController, Icons.work_history_outlined,
                            hint: "e.g. 5", keyboardType: TextInputType.number),
                        const SizedBox(height: 25),
                        _buildSectionTitle("Contact Details"),
                        const SizedBox(height: 15),
                        _buildTextField("Phone Number", _phoneController,
                            Icons.phone_outlined,
                            hint: "e.g. +91 9876543210",
                            keyboardType: TextInputType.phone),
                        const SizedBox(height: 15),
                        _buildTextField("Email Address", _emailController,
                            Icons.email_outlined,
                            hint: "e.g. doctor@clinic.com",
                            keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 25),
                        _buildSectionTitle("Clinic Details"),
                        const SizedBox(height: 15),
                        _buildTextField(
                            "Clinic Address",
                            _clinicAddressController,
                            Icons.location_on_outlined,
                            hint: "Enter clinic full address",
                            minLines: 1,
                            autoGrow: true),
                        const SizedBox(height: 15),
                        _buildTextField(
                            "Consultation Fee (₹)",
                            _consultationFeeController,
                            Icons.currency_rupee_outlined,
                            hint: "e.g. 500",
                            keyboardType: TextInputType.number),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            child: Obx(
              () => SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _doctorProfileController.isSaving.value
                      ? null
                      : _saveDoctorProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A9C89),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 2,
                  ),
                  child: _doctorProfileController.isSaving.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Save Changes",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF6A9C89),
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon,
      {String? hint,
      int maxLines = 1,
      int? minLines,
      bool autoGrow = false,
      TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      maxLines: autoGrow ? null : maxLines,
      minLines: autoGrow ? (minLines ?? 1) : minLines,
      keyboardType: autoGrow ? TextInputType.multiline : keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF6A9C89)),
        alignLabelWithHint: autoGrow || maxLines > 1,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF6A9C89), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FBF9),
      ),
    );
  }
}
