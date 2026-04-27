import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'doctor_footer_view.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../common/services/storage_service.dart';

class DigitalPrescriptionView extends StatefulWidget {
  final String? patientId;
  final String? appointmentId;
  final String? initialPatientName;
  final String? initialAge;
  final String? initialGender;
  final String? initialSymptoms;
  final String? initialDiagnosis;

  const DigitalPrescriptionView({
    super.key,
    this.patientId,
    this.appointmentId,
    this.initialPatientName,
    this.initialAge,
    this.initialGender,
    this.initialSymptoms,
    this.initialDiagnosis,
  });

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

  late String _selectedGender;

  @override
  void initState() {
    super.initState();
    _patientNameController.text = widget.initialPatientName ?? '';
    _ageController.text = widget.initialAge ?? '';
    _selectedGender = (widget.initialGender != null && widget.initialGender!.isNotEmpty) ? widget.initialGender! : 'Male';
    if (!['Male', 'Female', 'Other'].contains(_selectedGender)) {
      _selectedGender = 'Male';
    }
    _symptomsController.text = widget.initialSymptoms ?? '';
    _diagnosisController.text = widget.initialDiagnosis ?? '';
  }

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

  Future<void> _generateAndSavePdf() async {
    if (_medicinesController.text.isEmpty) {
      Get.snackbar(
        "Error",
        "Please add required details before generating Rx",
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return;
    }

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Header(
                    level: 0,
                    child: pw.Text("Digital Prescription",
                        style: pw.TextStyle(
                            fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text("Patient Details",
                      style: pw.TextStyle(
                          fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Divider(),
                  pw.Text("Name: ${_patientNameController.text}"),
                  pw.Text("Age: ${_ageController.text}"),
                  pw.Text("Gender: $_selectedGender"),
                  pw.SizedBox(height: 20),
                  pw.Text("Consultation Details",
                      style: pw.TextStyle(
                          fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Divider(),
                  pw.Text("Symptoms: ${_symptomsController.text}"),
                  pw.Text("Diagnosis: ${_diagnosisController.text}"),
                  pw.SizedBox(height: 20),
                  pw.Text("Prescription",
                      style: pw.TextStyle(
                          fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Divider(),
                  pw.Text("Medicines:"),
                  pw.Paragraph(text: _medicinesController.text),
                  pw.SizedBox(height: 10),
                  pw.Text("Notes:"),
                  pw.Paragraph(text: _notesController.text),
                  pw.SizedBox(height: 40),
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Column(
                      children: [
                        pw.SizedBox(
                          width: 150,
                          child: pw.Divider(thickness: 1),
                        ),
                        pw.Text("Doctor's Signature"),
                      ],
                    ),
                  ),
                  pw.Spacer(),
                  pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Text("Generated via Mediverse",
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                  ),
                ],
              ),
            );
          },
        ),
      );

      final output = await getApplicationDocumentsDirectory();
      final fileName = "Prescription_${_patientNameController.text.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final file = File("${output.path}/$fileName");
      await file.writeAsBytes(await pdf.save());

      // Save to StorageService
      final storage = await StorageService.getInstance();
      await storage.addPatientFile(widget.patientId ?? 'unknown', fileName, file.path);

      Get.snackbar(
        "Success",
        "Digital Prescription generated & saved successfully!",
        backgroundColor: const Color(0xFFC4DAD2),
        colorText: Colors.black87,
        icon: const Icon(Icons.check_circle, color: Colors.green),
      );

      // Offer to share/print
      await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save());

    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to generate PDF: $e",
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    }
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
                onPressed: _generateAndSavePdf,
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
      bottomSheet: const DoctorFooter(selectedIndex: 1),
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
