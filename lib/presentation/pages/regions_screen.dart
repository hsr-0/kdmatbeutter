import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/models.dart';

class RegionsScreen extends StatelessWidget {
  final Representation representation;

  const RegionsScreen({
    super.key,
    required this.representation,
  });

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanedNumber.isEmpty) return;
    final Uri launchUri = Uri(scheme: 'tel', path: cleanedNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    String cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanedNumber.startsWith('0')) {
      cleanedNumber = '964${cleanedNumber.substring(1)}';
    }
    final url = 'https://wa.me/$cleanedNumber';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  // [تم التصحيح] تعديل هذا السطر لإصلاح أخطاء null
  Widget _buildContactRow(String phone, String? whatsapp) {
    final String whatsappNumber = (whatsapp != null && whatsapp.isNotEmpty) ? whatsapp : phone;

    return Row(
      children: [
        if (phone.isNotEmpty)
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.phone, size: 18),
              label: const Text('اتصال'),
              onPressed: () => _makePhoneCall(phone),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        if (phone.isNotEmpty && whatsappNumber.isNotEmpty) const SizedBox(width: 8),
        if (whatsappNumber.isNotEmpty)
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.chat, size: 18),
              label: const Text('واتساب'),
              onPressed: () => _openWhatsApp(whatsappNumber),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
      ],
    );
  }

  void _showStationManagersSheet(BuildContext context, List<StationManager> managers) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مسؤولو المحطات',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: managers.length,
                  itemBuilder: (listCtx, index) {
                    final manager = managers[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              manager.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            _buildContactRow(manager.phone, manager.phone),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'المناطق التابعة:',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          region.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 24),
                        // [تم التصحيح] تم إزالة الشرط الغير ضروري if (region.leader != null)
                        Text('مسؤول المنطقة: ${region.leader.name}'),
                        const SizedBox(height: 8),
                        _buildContactRow(region.leader.phone, region.leader.whatsapp),

                        if (region.stationManagers.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.groups_outlined),
                              label: Text('عرض مسؤولي المحطات (${region.stationManagers.length})'),
                              onPressed: () {
                                _showStationManagersSheet(context, region.stationManagers);
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Theme.of(context).primaryColor),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ]
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