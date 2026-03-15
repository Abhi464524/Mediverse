import 'package:flutter/material.dart';
import '../model/doctor_notification_model.dart';

/// Abstract source of notifications. Later you can implement this
/// with a real API client without touching the UI.
abstract class DoctorNotificationRepository {
  Future<List<DoctorNotification>> fetchNotifications();
}

/// Temporary/local implementation – replace this with your API later.
class DummyDoctorNotificationRepository implements DoctorNotificationRepository {
  @override
  Future<List<DoctorNotification>> fetchNotifications() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 400));
    return const [
      DoctorNotification(
        id: '1',
        name: 'Jack',
        message: 'wants to book an appointment with you regarding his issues',
        timeAgo: '5 mins ago',
      ),
      DoctorNotification(
        id: '2',
        name: 'Miller',
        message: 'wants to book an appointment with you regarding his issues',
        timeAgo: '10 mins ago',
      ),
      DoctorNotification(
        id: '3',
        name: 'Mateo',
        message: 'wants to book an appointment with you regarding his issues',
        timeAgo: '15 mins ago',
      ),
      DoctorNotification(
        id: '4',
        name: 'Steve',
        message: 'wants to book an appointment with you regarding his issues',
        timeAgo: '20 mins ago',
      ),
      DoctorNotification(
        id: '5',
        name: 'Kevin',
        message: 'wants to book an appointment with you regarding his issues',
        timeAgo: '30 mins ago',
      ),
    ];
  }
}

class DoctorNotificationsPage extends StatefulWidget {
  const DoctorNotificationsPage({super.key});

  @override
  State<DoctorNotificationsPage> createState() =>
      _DoctorNotificationsPageState();
}

class _DoctorNotificationsPageState extends State<DoctorNotificationsPage> {
  final DoctorNotificationRepository _repository =
      DummyDoctorNotificationRepository();

  List<DoctorNotification> _notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _repository.fetchNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text("Notifications"),
        titleSpacing: 0,
        backgroundColor: const Color(0xFFF2F7F5), // Soft Mint
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Failed to load notifications",
              style: TextStyle(
                color: Colors.red.shade400,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNotifications,
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }
    if (_notifications.isEmpty) {
      return const Center(
        child: Text(
          "No notifications",
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      );
    }
    return _notificationsSection();
  }

  Widget _notificationsSection() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        final initial =
            notification.name.isNotEmpty ? notification.name[0].toUpperCase() : '?';
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFC4DAD2), // Soft Sage Accent
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC4DAD2).withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFC4DAD2),
                  ),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFC4DAD2).withOpacity(0.6),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6A9C89), // Sage Green
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.name,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.notifications_active_outlined,
                          size: 16,
                          color: const Color(0xFF6A9C89),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          notification.timeAgo,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 12),
    );
  }
}
