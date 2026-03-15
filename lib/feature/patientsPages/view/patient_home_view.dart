import 'package:doctor_app/feature/doctorPages/view/doc_notification_view.dart';
import 'package:doctor_app/feature/patientsPages/view/patient_footer_view.dart';
import 'package:doctor_app/feature/patientsPages/view/patient_profile_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PatientHomePage extends StatefulWidget {
  final String name;
  const PatientHomePage({super.key, required this.name});

  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  String patientName = "";

  @override
  void initState() {
    super.initState();
    patientName = widget.name;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: _buildProfileCard(),
        ),
        body: Column(
          children: [
            _upcomingAppointments(),
          ],
        ),
        bottomSheet: PatientFooterPage(),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: EdgeInsets.only(left: 20, top: 50, right: 20),
      color: const Color(0xFFF5F7FA), // Soft Whisper White
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                  onPressed: () {
                    Get.to(PatientProfilePage(
                      name: patientName,
                      onEditProfile: () {},
                    ));
                  },
                  icon: Icon(
                    Icons.person,
                    color: const Color(0xFF6B9AC4),
                  )), // Soft Azure
              IconButton(
                  onPressed: () {
                    Get.to(DoctorNotificationsPage());
                  },
                  icon: Icon(
                    Icons.notifications_active,
                    color: const Color(0xFF6B9AC4),
                  )), // Soft Azure
            ],
          ),
          SizedBox(height: 10),
          Text(
            "Welcome $patientName",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ],
      ),
    );
  }

  Widget _searchDoctors() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(8),
          child: TextField(
            decoration: InputDecoration(
              labelText: "Search",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _upcomingAppointments() {
    return Container(
      padding: EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Upcoming Appointments",
                  style: TextStyle(fontWeight: FontWeight.w500)),
              // TextButton(
              //     onPressed: () {
              //       Get.to(AppointmentsPage());
              //     },
              //     child: Text("See all"))
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
                  children: [
                    Icon(
                      Icons.medical_information,
                      size: 50,
                      color: const Color(0xFF9AC6C5),
                    ), // Soft Teal
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Dr. Shubham Chaudhary",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Cardiologist",
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            size: 20,
                            color: const Color(0xFF9AC6C5),
                          ), // Soft Teal
                          SizedBox(width: 10),
                          Text("9-sept-2025"),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: const Color(0xFF6B9AC4), // Soft Azure
                          ),
                          child: Text("View Appointment",
                              style: TextStyle(color: Colors.white)),
                        ),
                      )
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
