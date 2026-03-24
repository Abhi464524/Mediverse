import 'package:flutter/material.dart';
import 'package:mediverse/common/services/storage_service.dart';
import 'dart:convert';

class WorkingHoursView extends StatefulWidget {
  const WorkingHoursView({super.key});

  @override
  State<WorkingHoursView> createState() => _WorkingHoursViewState();
}

class _WorkingHoursViewState extends State<WorkingHoursView> {
  static const String _workingHoursKey = "doctor_working_hours_v1";

  final List<Map<String, dynamic>> _days = [
    {
      "day": "Monday",
      "isOpen": true,
      "allDay": true,
      "openTime": "09:00 AM",
      "closeTime": "05:00 PM",
      "morningOpenTime": "09:00 AM",
      "morningCloseTime": "12:00 PM",
      "eveningOpenTime": "04:00 PM",
      "eveningCloseTime": "08:00 PM",
    },
    {
      "day": "Tuesday",
      "isOpen": true,
      "allDay": true,
      "openTime": "09:00 AM",
      "closeTime": "05:00 PM",
      "morningOpenTime": "09:00 AM",
      "morningCloseTime": "12:00 PM",
      "eveningOpenTime": "04:00 PM",
      "eveningCloseTime": "08:00 PM",
    },
    {
      "day": "Wednesday",
      "isOpen": true,
      "allDay": true,
      "openTime": "09:00 AM",
      "closeTime": "05:00 PM",
      "morningOpenTime": "09:00 AM",
      "morningCloseTime": "12:00 PM",
      "eveningOpenTime": "04:00 PM",
      "eveningCloseTime": "08:00 PM",
    },
    {
      "day": "Thursday",
      "isOpen": true,
      "allDay": true,
      "openTime": "09:00 AM",
      "closeTime": "05:00 PM",
      "morningOpenTime": "09:00 AM",
      "morningCloseTime": "12:00 PM",
      "eveningOpenTime": "04:00 PM",
      "eveningCloseTime": "08:00 PM",
    },
    {
      "day": "Friday",
      "isOpen": true,
      "allDay": true,
      "openTime": "09:00 AM",
      "closeTime": "05:00 PM",
      "morningOpenTime": "09:00 AM",
      "morningCloseTime": "12:00 PM",
      "eveningOpenTime": "04:00 PM",
      "eveningCloseTime": "08:00 PM",
    },
    {
      "day": "Saturday",
      "isOpen": false,
      "allDay": true,
      "openTime": "09:00 AM",
      "closeTime": "01:00 PM",
      "morningOpenTime": "09:00 AM",
      "morningCloseTime": "12:00 PM",
      "eveningOpenTime": "04:00 PM",
      "eveningCloseTime": "08:00 PM",
    },
    {
      "day": "Sunday",
      "isOpen": false,
      "allDay": true,
      "openTime": "09:00 AM",
      "closeTime": "01:00 PM",
      "morningOpenTime": "09:00 AM",
      "morningCloseTime": "12:00 PM",
      "eveningOpenTime": "04:00 PM",
      "eveningCloseTime": "08:00 PM",
    },
  ];

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  @override
  void initState() {
    super.initState();
    _loadSavedSchedule();
  }

  Future<void> _loadSavedSchedule() async {
    final storage = await StorageService.getInstance();
    final raw = storage.getString(_workingHoursKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      final byDay = <String, Map<String, dynamic>>{};
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final dayName = item["day"]?.toString() ?? "";
          if (dayName.isNotEmpty) byDay[dayName] = item;
        } else if (item is Map) {
          final normalized = item.map(
            (key, value) => MapEntry(key.toString(), value),
          );
          final dayName = normalized["day"]?.toString() ?? "";
          if (dayName.isNotEmpty) byDay[dayName] = normalized;
        }
      }

      setState(() {
        for (final day in _days) {
          final dayName = day["day"]?.toString() ?? "";
          final saved = byDay[dayName];
          if (saved == null) continue;

          day["isOpen"] = (saved["isOpen"] is bool)
              ? saved["isOpen"]
              : (saved["isOpen"]?.toString().toLowerCase() == "true");
          day["allDay"] = (saved["allDay"] is bool)
              ? saved["allDay"]
              : (saved["allDay"]?.toString().toLowerCase() != "false");

          day["openTime"] =
              saved["openTime"]?.toString().trim().isNotEmpty == true
                  ? saved["openTime"].toString()
                  : day["openTime"];
          day["closeTime"] =
              saved["closeTime"]?.toString().trim().isNotEmpty == true
                  ? saved["closeTime"].toString()
                  : day["closeTime"];
          day["morningOpenTime"] =
              saved["morningOpenTime"]?.toString().trim().isNotEmpty == true
                  ? saved["morningOpenTime"].toString()
                  : day["morningOpenTime"];
          day["morningCloseTime"] =
              saved["morningCloseTime"]?.toString().trim().isNotEmpty == true
                  ? saved["morningCloseTime"].toString()
                  : day["morningCloseTime"];
          day["eveningOpenTime"] =
              saved["eveningOpenTime"]?.toString().trim().isNotEmpty == true
                  ? saved["eveningOpenTime"].toString()
                  : day["eveningOpenTime"];
          day["eveningCloseTime"] =
              saved["eveningCloseTime"]?.toString().trim().isNotEmpty == true
                  ? saved["eveningCloseTime"].toString()
                  : day["eveningCloseTime"];
        }
      });
    } catch (_) {
      // Ignore malformed persisted schedule and keep defaults.
    }
  }

  Future<void> _saveSchedule() async {
    final storage = await StorageService.getInstance();
    final encoded = jsonEncode(_days);
    await storage.setString(_workingHoursKey, encoded);
  }

  String _timeFromDay(
    Map<String, dynamic> day,
    String key, {
    String fallback = "09:00 AM",
  }) {
    final value = day[key];
    if (value is String && value.isNotEmpty) return value;
    return fallback;
  }

  bool _isAllDay(Map<String, dynamic> day) {
    final value = day["allDay"];
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == "true";
    return true;
  }

  bool _isAllowedByShift(String shift, TimeOfDay picked) {
    final minutes = _toMinutes(picked);
    if (shift == "Morning") {
      return minutes <= (12 * 60);
    }
    if (shift == "Evening") {
      return minutes >= (16 * 60);
    }
    return true;
  }

  TimeOfDay _parseStoredTime(String input) {
    final normalized = input
        .replaceAll('\u202F', ' ')
        .replaceAll('\u00A0', ' ')
        .trim()
        .toUpperCase();

    // Supports both "09:30 AM" and 24h formats like "21:30".
    final match = RegExp(r'^(\d{1,2}):(\d{2})(?:\s*([AP]M))?$').firstMatch(
      normalized,
    );
    if (match == null) {
      return const TimeOfDay(hour: 9, minute: 0);
    }

    int hour = int.tryParse(match.group(1) ?? '') ?? 9;
    final int minute = int.tryParse(match.group(2) ?? '') ?? 0;
    final period = match.group(3);

    if (period != null) {
      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;
    }

    hour = hour.clamp(0, 23);
    final safeMinute = minute.clamp(0, 59);
    return TimeOfDay(hour: hour, minute: safeMinute);
  }

  Future<void> _selectTime(
    BuildContext context,
    int index, {
    required String timeKey,
    required String shift,
  }) async {
    final Map<String, dynamic> dayData = _days[index];
    final String currentTimeStr = _timeFromDay(dayData, timeKey);
    final TimeOfDay initialTime = _parseStoredTime(currentTimeStr);

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
      if (!_isAllowedByShift(shift, picked)) {
        final message = shift == "Morning"
            ? "Morning slot allows time only up to 12:00 PM."
            : "Evening slot allows time only from 4:00 PM.";
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: const Color(0xFF6A9C89),
            ),
          );
        }
        return;
      }
      setState(() {
        final formattedTime = picked.format(context);
        _days[index][timeKey] = formattedTime;
      });
      await _saveSchedule();
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
                              _saveSchedule();
                            },
                          ),
                        ],
                      ),
                      if (day["isOpen"]) ...[
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Text(
                              "All Day",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                            const Spacer(),
                            Switch(
                              value: _isAllDay(day),
                              activeColor: const Color(0xFF6A9C89),
                              onChanged: (value) {
                                setState(() {
                                  day["allDay"] = value;
                                });
                                _saveSchedule();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_isAllDay(day))
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _selectTime(
                                    context,
                                    index,
                                    timeKey: "openTime",
                                    shift: "All Day",
                                  ),
                                  child: _buildTimeBox(
                                      "Opens", _timeFromDay(day, "openTime")),
                                  
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.arrow_forward_rounded,
                                  color: Colors.grey, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _selectTime(
                                    context,
                                    index,
                                    timeKey: "closeTime",
                                    shift: "All Day",
                                  ),
                                  child: _buildTimeBox(
                                      "Closes", _timeFromDay(day, "closeTime")),
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _buildShiftHeader("Morning"),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _selectTime(
                                    context,
                                    index,
                                    timeKey: "morningOpenTime",
                                    shift: "Morning",
                                  ),
                                  child: _buildTimeBox(
                                      "Opens",
                                      _timeFromDay(day, "morningOpenTime")),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.arrow_forward_rounded,
                                  color: Colors.grey, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _selectTime(
                                    context,
                                    index,
                                    timeKey: "morningCloseTime",
                                    shift: "Morning",
                                  ),
                                  child: _buildTimeBox(
                                      "Closes",
                                      _timeFromDay(day, "morningCloseTime")),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildShiftHeader("Evening"),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _selectTime(
                                    context,
                                    index,
                                    timeKey: "eveningOpenTime",
                                    shift: "Evening",
                                  ),
                                  child: _buildTimeBox(
                                      "Opens",
                                      _timeFromDay(day, "eveningOpenTime")),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.arrow_forward_rounded,
                                  color: Colors.grey, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _selectTime(
                                    context,
                                    index,
                                    timeKey: "eveningCloseTime",
                                    shift: "Evening",
                                  ),
                                  child: _buildTimeBox(
                                      "Closes",
                                      _timeFromDay(day, "eveningCloseTime")),
                                ),
                              ),
                            ],
                          ),
                        ],
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
                  _saveSchedule().then((_) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Working hours saved successfully!"),
                        backgroundColor: Color(0xFF6A9C89),
                      ),
                    );
                    Navigator.pop(context);
                  });
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

  Widget _buildShiftHeader(String shift) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            shift,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6A9C89),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFC4DAD2),
            ),
          ),
        ],
      ),
    );
  }
}
