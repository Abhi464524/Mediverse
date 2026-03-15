import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
  late TextEditingController _nameController;
  late TextEditingController _specializationController;

  // New fields
  final TextEditingController _experienceController =
      TextEditingController(text: "8 Years");
  final TextEditingController _phoneController =
      TextEditingController(text: "+1 234-567-8900");
  final TextEditingController _emailController =
      TextEditingController(text: "doctor@clinic.com");
  final TextEditingController _clinicAddressController =
      TextEditingController(text: "123 Health Avenue, Medical District");
  final TextEditingController _consultationFeeController =
      TextEditingController(text: "500");

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _specializationController =
        TextEditingController(text: widget.currentSpecialization);
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
      body: SingleChildScrollView(
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
                    border:
                        Border.all(color: const Color(0xFFC4DAD2), width: 3),
                  ),
                  child: const CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFFC4DAD2),
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF6A9C89),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt,
                      color: Colors.white, size: 20),
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
                  _buildTextField("Specialization", _specializationController,
                      Icons.medical_services_outlined),
                  const SizedBox(height: 15),
                  _buildTextField("Years of Experience", _experienceController,
                      Icons.work_history_outlined,
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 25),
                  _buildSectionTitle("Contact Details"),
                  const SizedBox(height: 15),
                  _buildTextField(
                      "Phone Number", _phoneController, Icons.phone_outlined,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 15),
                  _buildTextField(
                      "Email Address", _emailController, Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 25),
                  _buildSectionTitle("Clinic Details"),
                  const SizedBox(height: 15),
                  _buildTextField("Clinic Address", _clinicAddressController,
                      Icons.location_on_outlined,
                      maxLines: 2),
                  const SizedBox(height: 15),
                  _buildTextField("Consultation Fee (₹)",
                      _consultationFeeController, Icons.currency_rupee_outlined,
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onSave(_nameController.text,
                            _specializationController.text);
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A9C89), // Sage Green
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        "Save Changes",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
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
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6A9C89)),
        alignLabelWithHint: maxLines > 1,
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
