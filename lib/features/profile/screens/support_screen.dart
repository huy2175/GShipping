import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // fallback if url_launcher fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trung tâm hỗ trợ'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner hỗ trợ
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chúng tôi có thể giúp gì cho bạn?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Đội ngũ GShipping luôn sẵn sàng hỗ trợ bạn 24/7.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            const Text(
              'Câu hỏi thường gặp (FAQ)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildFAQItem(
              context,
              'Làm sao để đăng ký ca làm?',
              'Bạn vào mục "Ca làm việc" và nhấn nút "Đăng ký ca mới" để chọn thời gian và địa điểm.',
            ),
            _buildFAQItem(
              context,
              'Tôi cần thay đổi thông tin cá nhân?',
              'Bạn vào "Thông tin cá nhân" -> "Chỉnh sửa thông tin" để cập nhật họ tên và số điện thoại.',
            ),

            _buildFAQItem(
              context,
              'Làm thế nào để xem vị trí khách hàng?',
              'Trong chi tiết ca làm hoặc mục khách hàng, chọn khách hàng cần xem và nhấn "Xem trên bản đồ".',
            ),

            const SizedBox(height: 32),
            const Text(
              'Liên hệ trực tiếp',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildContactItem(
              context,
              Icons.email,
              'Email hỗ trợ',
              'support@gshipping.com',
              () => _launchURL('mailto:support@gshipping.com'),
            ),
            const SizedBox(height: 12),
            _buildContactItem(
              context,
              Icons.phone,
              'Hotline',
              '1900 1234',
              () => _launchURL('tel:19001234'),
            ),
            const SizedBox(height: 12),
            _buildContactItem(
              context,
              Icons.message,
              'Zalo/Chat',
              'Chat trực tuyến',
              () => _launchURL('https://zalo.me/gshipping'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(answer, style: TextStyle(color: Colors.grey[600])),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context,
    IconData icon,
    String title,
    String value,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
