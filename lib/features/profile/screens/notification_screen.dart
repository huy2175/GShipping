import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // Giả lập trạng thái thông báo (trong thực tế sẽ lưu vào Firestore/SharedPrefs)
  final Map<String, bool> _notificationSettings = {
    'new_shift': true, // Thông báo ca làm mới
    'shift_reminder': true, // Nhắc nhở ca làm
    'system_alert': true, // Thông báo hệ thống
    'message_alert': false, // Thông báo tin nhắn
  };

  void _toggleNotification(String key) {
    setState(() {
      _notificationSettings[key] = !(_notificationSettings[key] ?? false);
    });
    // Tại đây có thể gọi API cập nhật cài đặt thông báo lên Firebase
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Cài đặt thông báo',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Quản lý cách bạn nhận thông báo từ GShipping',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 32),

          _buildNotificationTile(
            'new_shift',
            'Ca làm mới',
            'Nhận thông báo khi có ca làm việc mới phù hợp.',
          ),
          _buildNotificationTile(
            'shift_reminder',
            'Nhắc nhở ca làm',
            'Nhắc nhở bạn trước khi ca làm bắt đầu 1 giờ.',
          ),
          _buildNotificationTile(
            'system_alert',
            'Thông báo hệ thống',
            'Nhận các tin tức và cập nhật từ GShipping.',
          ),
          _buildNotificationTile(
            'message_alert',
            'Thông báo tin nhắn',
            'Thông báo khi có tin nhắn mới từ điều phối viên.',
          ),

          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF0369A1)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Một số thông báo quan trọng sẽ luôn được gửi đến bạn bất kể cài đặt này.',
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFF0C4A6E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(String key, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xFF0F172A),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        ),
        value: _notificationSettings[key] ?? false,
        onChanged: (bool value) {
          _toggleNotification(key);
        },
        activeThumbColor: const Color(0xFF2563EB),
      ),
    );
  }
}
