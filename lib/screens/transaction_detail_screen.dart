import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../services/local_db_service.dart';

class TransactionDetailScreen extends StatelessWidget {
  final ExpenseTransaction transaction;
  final ExpenseCategory? category;
  final String currencySymbol;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
    this.category,
    this.currencySymbol = '₹',
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Transaction?'),
                  content: const Text('This will permanently delete this transaction from your local database.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await LocalDatabaseService.instance.deleteTransaction(transaction.id);
                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Amount Card
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    '${isIncome ? '+' : '-'}$currencySymbol${transaction.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: isIncome ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    transaction.merchant,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  if (transaction.isAutoParsed)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, size: 14, color: Colors.blue),
                          SizedBox(width: 4),
                          Text(
                            'Auto-Parsed from Bank SMS',
                            style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Metadata List
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildMetaTile('Date & Time', DateFormat('dd MMM yyyy, hh:mm a').format(transaction.date), Icons.calendar_today),
                  const Divider(height: 1),
                  _buildMetaTile('Category', category?.name ?? 'Uncategorized', Icons.category),
                  const Divider(height: 1),
                  _buildMetaTile('Bank', transaction.bankName ?? 'Not specified', Icons.account_balance),
                  const Divider(height: 1),
                  _buildMetaTile('Account / Card', transaction.accountLast4 != null ? 'Ending in ••${transaction.accountLast4}' : 'N/A', Icons.credit_card),
                  const Divider(height: 1),
                  _buildMetaTile('Payment Method', transaction.paymentMode.name.toUpperCase(), Icons.payments_outlined),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Original Bank SMS Box
            if (transaction.rawSMS != null && transaction.rawSMS!.isNotEmpty) ...[
              const Text(
                'Original Bank SMS Message',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      transaction.rawSMS!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: transaction.rawSMS!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('SMS copied to clipboard')),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copy SMS'),
                        ),
                      ],
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

  Widget _buildMetaTile(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 14),
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
