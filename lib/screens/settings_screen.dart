import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/local_db_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Privacy'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Privacy Guarantee Badge
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withOpacity(0.25)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: Colors.green, size: 36),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '100% On-Device & Offline',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Your financial data and bank SMS messages are stored strictly inside this phone\'s local SQLite sandbox. Zero server, zero tracking, zero cloud.',
                        style: TextStyle(fontSize: 12, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Backup & Data Export
          const Text('Data Management', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_download_outlined, color: Colors.blue),
                  title: const Text('Export Local Backup (JSON)'),
                  subtitle: const Text('Save a complete offline backup of all transactions'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final jsonString = await LocalDatabaseService.instance.exportToJson();
                    await Clipboard.setData(ClipboardData(text: jsonString));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Backup JSON copied to clipboard! Save it in your notes or files.')),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.file_upload_outlined, color: Colors.purple),
                  title: const Text('Restore from JSON Backup'),
                  subtitle: const Text('Paste backup text to restore transactions'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final controller = TextEditingController();
                    final success = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Restore Backup'),
                        content: TextField(
                          controller: controller,
                          maxLines: 6,
                          decoration: const InputDecoration(
                            hintText: 'Paste backup JSON here...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          ElevatedButton(
                            onPressed: () async {
                              final ok = await LocalDatabaseService.instance.importFromJson(controller.text);
                              if (ctx.mounted) Navigator.pop(ctx, ok);
                            },
                            child: const Text('Restore'),
                          ),
                        ],
                      ),
                    );

                    if (success == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Transactions restored successfully!'), backgroundColor: Colors.green),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About Section
          const Text('About', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.smartphone),
                  title: Text('Supported Platforms'),
                  subtitle: Text('iPhone (iOS 17+) & Android (Android 8.0+)'),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.mark_email_read),
                  title: Text('Bank SMS Reader Engine'),
                  subtitle: Text('Supports UPI, HDFC, SBI, ICICI, Axis, Chase, Amex & International Banks'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.storage),
                  title: const Text('Local Engine'),
                  subtitle: const Text('SQLite on device sandbox (Zero network calls)'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
