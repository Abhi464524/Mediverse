import 'package:flutter/material.dart';

class WorkingHoursView extends StatefulWidget {
  const WorkingHoursView({super.key});

  @override
  State<WorkingHoursView> createState() => _WorkingHoursViewState();
}

class _WorkingHoursViewState extends State<WorkingHoursView> {
  final List<Map<String, dynamic>> _days = [
    {
      "day": "Monday",
      "isOpen": true,
      "openTime": "09:00 AM",
      "closeTime": "05:00 PM"
    },
    {
      "day": "Tuesday",
      "isOpen": true,
      "openTime": "09:00 AM",
      "closeTime": "05:00 PM"
    },
    {
      "day": "Wednesday",
      "isOpen": true,
      "openTime": "09:00 AM",
      "closeTime": "05:00 PM"
    },
    {
      "day": "Thursday",
      "isOpen": true,
      "openTime": "09:00 AM",
      "closeTime": "05:00 PM"
    },
    {
      "day": "Friday",
      "isOpen": true,
      "openTime": "09:00 AM",
      "closeTime": "05:00 PM"
    },
    {
      "day": "Saturday",
      "isOpen": false,
      "openTime": "09:00 AM",
      "closeTime": "01:00 PM"
    },
    {
      "day": "Sunday",
      "isOpen": false,
      "openTime": "09:00 AM",
      "closeTime": "01:00 PM"
    },
  ];

  Future<void> _selectTime(
      BuildContext context, int index, bool isOpentime) async {
    final Map<String, dynamic> dayData = _days[index];
    final String currentTimeStr =
        isOpentime ? dayData["openTime"] : dayData["closeTime"];

    // Parse existing time string for initial selected time
    final parts = currentTimeStr.split(' ');
    final timeParts = parts[0].split(':');
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);
    if (parts[1] == "PM" && hour != 12) hour += 12;
    if (parts[1] == "AM" && hour == 12) hour = 0;

    final TimeOfDay initialTime = TimeOfDay(hour: hour, minute: minute);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6A9C89), // Sage Green
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        // Format time string
        String formattedTime = picked.format(context);
        if (isOpentime) {
          _days[index]["openTime"] = formattedTime;
        } else {
          _days[index]["closeTime"] = formattedTime;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF9), // Pale mint
      appBar: AppBar(
        title: const Text("Working Hours",
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            alignment: Alignment.centerLeft,
            child: const Text(
              "Set your regular clinic hours below. Patients can only book appointments during these times.",
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _days.length,
              itemBuilder: (context, index) {
                final day = _days[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            day["day"],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Switch(
                            value: day["isOpen"],
                            activeColor: const Color(0xFF6A9C89),
                            onChanged: (val) {
                              setState(() {
                                day["isOpen"] = val;
                              });
                            },
                          ),
                        ],
                      ),
                      if (day["isOpen"]) ...[
                        const Divider(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _selectTime(context, index, true),
                                child: _buildTimeBox("Opens", day["openTime"]),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.arrow_forward_rounded,
                                color: Colors.grey, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _selectTime(context, index, false),
                                child:
                                    _buildTimeBox("Closes", day["closeTime"]),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Working hours saved successfully!"),
                      backgroundColor: Color(0xFF6A9C89),
                    ),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A9C89), // Sage Green
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  "Save Schedule",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBox(String label, String time) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F7F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFC4DAD2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                time,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const Icon(Icons.access_time, size: 16, color: Color(0xFF6A9C89)),
            ],
          ),
        ],
      ),
    );
  }
}
