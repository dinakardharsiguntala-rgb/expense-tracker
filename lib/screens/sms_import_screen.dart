import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/bank_sms_parser.dart';
import '../services/sms_service.dart';
import '../services/local_db_service.dart';
import '../models/category.dart';

class SmsImportScreen extends StatefulWidget {
  const SmsImportScreen({super.key});

  @override
  State<SmsImportScreen> createState() => _SmsImportScreenState();
}

class _SmsImportScreenState extends State<SmsImportScreen> {
  final TextEditingController _smsController = TextEditingController();
  ParsedBankSMS? _parsedResult;
  bool _isScanning = false;
  Map<String, ExpenseCategory> _categoryMap = {};

  final List<Map<String, String>> _sampleMessages = [
    {
      'bank': 'HDFC Bank',
      'sms': 'Dear Customer, Rs.450.00 has been debited from A/c **1234 to STARBUCKS on 04-SEP-26 using UPI. Avl Bal: Rs 15,240.50.',
    },
    {
      'bank': 'SBI UPI',
      'sms': 'Your A/C 9876 is debited by INR 1,299.00 on 03-SEP-26 to BLINKIT GROCERY via UPI Ref 629482. SBI.',
    },
    {
      'bank': 'Chase Bank',
      'sms': 'Chase Alert: You made a $42.50 purchase with Card ending in 4321 at UBER TRIP on Sep 2.',
    },
    {
      'bank': 'ICICI Bank (Salary)',
      'sms': 'Salary of INR 75,000.00 credited to your ICICI Bank Account XX8844 on 01-SEP-26 by Infosys Technologies Ltd.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _checkClipboard();
  }

  Future<void> _loadCategories() async {
    final list = await LocalDatabaseService.instance.getCategories();
    setState(() {
      _categoryMap = {for (var c in list) c.id: c};
    });
  }

  Future<void> _checkClipboard() async {
    try {
      final data = await Clipboard.getData('text/plain');
      if (data != null && data.text != null && data.text!.isNotEmpty) {
        final parsed = BankSMSParser.instance.parse(data.text!);
        if (parsed != null && _smsController.text.isEmpty) {
          setState(() {
            _smsController.text = data.text!;
            _parsedResult = parsed;
          });
        }
      }
    } catch (_) {}
  }

  void _onTextChanged(String text) {
    setState(() {
      _parsedResult = BankSMSParser.instance.parse(text);
    });
  }

  Future<void> _saveParsedTransaction() async {
    if (_parsedResult == null) return;

    final tx = _parsedResult!.toExpenseTransaction();
    await LocalDatabaseService.instance.insertTransaction(tx);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved: ₹${_parsedResult!.amount.toStringAsFixed(2)} at ${_parsedResult!.merchant ?? "Bank"}'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _scanAndroidInbox() async {
    setState(() => _isScanning = true);
    try {
      final hasPerm = await SmsService.instance.hasPermissions();
      if (!hasPerm) {
        final granted = await SmsService.instance.requestPermissions();
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('SMS permission denied. Enable SMS access in Android Settings to auto-read bank SMS.')),
            );
          }
          setState(() => _isScanning = false);
          return;
        }
      }

      final count = await SmsService.instance.scanAndImportHistoricalSms();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully scanned inbox and imported $count bank transactions!')),
        );
        if (count > 0) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Inbox scan error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank SMS Reader'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Android Auto-Scan Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.mark_email_read_outlined, color: Colors.blue, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Automatic Background SMS Reading',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '• Android: Real-time background detection automatically logs expenses as bank messages arrive.\n• iPhone: Use Apple Shortcuts automation or paste bank SMS below.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _isScanning ? null : _scanAndroidInbox,
                    icon: _isScanning
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.sync, size: 18),
                    label: Text(_isScanning ? 'Scanning Inbox...' : 'Scan & Import Bank SMS Inbox (Android)'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Paste SMS Text Field
            const Text(
              'Paste Bank Transaction SMS',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _smsController,
              onChanged: _onTextChanged,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Paste any bank SMS here (e.g., "Rs 450 debited from A/c **1234 to Starbucks...")',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste),
                  tooltip: 'Paste from clipboard',
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data?.text != null) {
                      _smsController.text = data!.text!;
                      _onTextChanged(data.text!);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Quick Samples Chips
            const Text('Try Sample Bank SMS:', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _sampleMessages.map((sample) {
                return ActionChip(
                  label: Text(sample['bank']!, style: const TextStyle(fontSize: 12)),
                  onPressed: () {
                    _smsController.text = sample['sms']!;
                    _onTextChanged(sample['sms']!);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Parsed Result Card
            if (_parsedResult != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'SMS Successfully Parsed!',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    _resultRow('Amount', '₹${_parsedResult!.amount.toStringAsFixed(2)}'),
                    _resultRow('Merchant', _parsedResult!.merchant ?? 'Unknown'),
                    _resultRow('Bank', _parsedResult!.bankName ?? 'Detected from SMS'),
                    _resultRow('Account Last 4', _parsedResult!.accountLast4 != null ? '••${_parsedResult!.accountLast4}' : 'N/A'),
                    _resultRow('Category', _categoryMap[_parsedResult!.categoryId]?.name ?? _parsedResult!.categoryId),
                    _resultRow('Type', _parsedResult!.type.name.toUpperCase()),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveParsedTransaction,
                        icon: const Icon(Icons.save),
                        label: const Text('Save to Local Database'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_smsController.text.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Could not extract transaction amount. Please check if this is a valid debit/credit bank message.',
                        style: TextStyle(fontSize: 13, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
