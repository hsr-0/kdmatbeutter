import 'package:flutter/material.dart';
import 'package:untitled4/data/models/models.dart';
import 'package:url_launcher/url_launcher.dart';

class RegionsScreen extends StatelessWidget {
  final Representation representation;

  const RegionsScreen({
    super.key,
    required this.representation,
  });

  // [تمت الإضافة] دالة للاتصال الهاتفي
  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanedNumber.isEmpty) return;

    final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleanedNumber,
    );

    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  // [تمت الإضافة] دالة لفتح الواتساب مع معالجة الرقم
  Future<void> _openWhatsApp(String phoneNumber) async {
    String cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    // [تمت الإضافة] تحويل الرقم الذي يبدأ بـ 0 إلى 964
    if (cleanedNumber.startsWith('0')) {
      cleanedNumber = '964${cleanedNumber.substring(1)}';
    }

    final url = 'https://wa.me/$cleanedNumber';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  // [تمت الإضافة] دالة لبناء صف الأزرار
  Widget _buildContactRow(String phone, String? whatsapp) {
    // [تمت الإضافة] استخدام رقم الهاتف إذا لم يكن رقم الواتساب متوفراً
    final whatsappNumber = whatsapp?.isNotEmpty == true ? whatsapp : phone;

    return Row(
      children: [
        if (phone.isNotEmpty)
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.phone, size: 18),
              label: const Text('اتصال'),
              onPressed: () => _makePhoneCall(phone),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        if (phone.isNotEmpty && whatsappNumber?.isNotEmpty == true)
          const SizedBox(width: 8),
        if (whatsappNumber?.isNotEmpty == true)
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.chat, size: 18),
              label: const Text('واتساب'),
              onPressed: () => _openWhatsApp(whatsappNumber!),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  // [تم التعديل] نقل الدالة داخل الكلاس وإضافة زر الاتصال
  Widget _buildRegionLeaderInfo(RegionLeader? leader) {
    if (leader == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'مدير المحطة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text('الاسم: ${leader.name}'),
        if (leader.title.isNotEmpty) Text('المسمى الوظيفي: ${leader.title}'),
        Text('الهاتف: ${leader.phone}'),
        if (leader.whatsapp?.isNotEmpty == true)
          Text('واتساب: ${leader.whatsapp}'),
        const SizedBox(height: 8),
        // [تمت الإضافة] زر الاتصال والواتساب
        _buildContactRow(leader.phone, leader.whatsapp),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(representation.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      representation.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('الموقع: ${representation.location}'),
                    if (representation.leader != null) ...[
                      const Divider(height: 24),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'المناطق التابعة:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: representation.regions.length,
              itemBuilder: (context, index) {
                final region = representation.regions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          region.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        _buildRegionLeaderInfo(region.leader),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}