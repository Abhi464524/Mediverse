import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'doctor_footer_view.dart';

class DigitalPrescriptionView extends StatefulWidget {
  const DigitalPrescriptionView({super.key});

  @override
  State<DigitalPrescriptionView> createState() =>
      _DigitalPrescriptionViewState();
}

class _DigitalPrescriptionViewState extends State<DigitalPrescriptionView> {
  final TextEditingController _patientNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _medicinesController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedGender = 'Male';

  void _applyTemplate(String templateName) {
    setState(() {
      if (templateName == 'Viral Fever') {
        _symptomsController.text = 'High Fever, Headaches, Weakness';
        _diagnosisController.text = 'Viral Infection';
        _medicinesController.text =
            '1. Paracetamol 500mg - 1 tablet (SOS) - 3 days\n2. Vitamin C - 1 tablet (OD) - 5 days';
        _notesController.text = 'Drink plenty of warm fluids. Rest for 3 days.';
      } else if (templateName == 'Allergies') {
        _symptomsController.text = 'Runny nose, Sneezing, Itchy eyes';
        _diagnosisController.text = 'Allergic Rhinitis';
        _medicinesController.text =
            '1. Cetirizine 10mg - 1 tablet (OD at night) - 5 days';
        _notesController.text = 'Avoid dust and cold exposure.';
      } else if (templateName == 'Gastric Issues') {
        _symptomsController.text = 'Stomach ache, Acidity, Bloating';
        _diagnosisController.text = 'Gastritis';
        _medicinesController.text =
            '1. Pantoprazole 40mg - 1 tablet (Empty stomach) - 5 days\n2. Digene Gel - 2 tsps after meals - 3 days';
        _notesController.text = 'Avoid spicy food. Eat light meals.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('generate_digital_rx'.tr,
            style: const TextStyle(color: Colors.black)),
        backgroundColor: const Color(0xFFF2F7F5), // Soft Mint
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('quick_rx_templates'.tr),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTemplateChip('viral_fever'.tr),
                  const SizedBox(width: 8),
                  _buildTemplateChip('allergies'.tr),
                  const SizedBox(width: 8),
                  _buildTemplateChip('gastric_issues'.tr),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('patient_details'.tr),
            const SizedBox(height: 10),
            _buildTextField('patient_name'.tr, _patientNameController),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _buildTextField('age'.tr, _ageController,
                        keyboardType: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: InputDecoration(
                      labelText: 'gender'.tr,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFC4DAD2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFF6A9C89), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: ['Male', 'Female', 'Other'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedGender = newValue!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('consultation_details'.tr),
            const SizedBox(height: 10),
            _buildTextField('symptoms'.tr, _symptomsController, maxLines: 2),
            const SizedBox(height: 10),
            _buildTextField('diagnosis'.tr, _diagnosisController),
            const SizedBox(height: 20),
            _buildSectionTitle('prescription'.tr),
            const SizedBox(height: 10),
            _buildTextField('medicines_format'.tr, _medicinesController,
                maxLines: 5),
            const SizedBox(height: 10),
            _buildTextField('notes'.tr, _notesController, maxLines: 3),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Simulate PDF Generation
                  if (_medicinesController.text.isEmpty) {
                    Get.snackbar(
                      "Error",
                      "Please add required details before generating Rx",
                      backgroundColor: Colors.red.shade100,
                      colorText: Colors.red.shade900,
                    );
                    return;
                  }

                  Get.snackbar(
                    "Success",
                    "Digital Prescription generated & saved successfully!",
                    backgroundColor: const Color(0xFFC4DAD2),
                    colorText: Colors.black87,
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                  );
                },
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                label: Text(
                  'generate_pdf'.tr,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A9C89),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 100), // added space for the footer
          ],
        ),
      ),
      bottomSheet: const DoctorFooter(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF6A9C89), // Sage Green
      ),
    );
  }

  Widget _buildTemplateChip(String label) {
    return ActionChip(
      label: Text(label),
      backgroundColor: const Color(0xFFF2F7F5),
      labelStyle: const TextStyle(
          color: Color(0xFF6A9C89), fontWeight: FontWeight.w600),
      side: const BorderSide(color: Color(0xFFC4DAD2)),
      onPressed: () => _applyTemplate(label),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: maxLines > 1,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFC4DAD2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFC4DAD2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF6A9C89), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
