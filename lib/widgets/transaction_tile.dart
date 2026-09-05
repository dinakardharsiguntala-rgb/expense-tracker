import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../screens/transaction_detail_screen.dart';

class TransactionTile extends StatelessWidget {
  final ExpenseTransaction transaction;
  final ExpenseCategory? category;
  final String currencySymbol;
  final VoidCallback? onDeleted;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.category,
    this.currencySymbol = '₹',
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final catColor = category?.color ?? Colors.blueGrey;
    final catIcon = category?.iconData ?? Icons.receipt;

    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionDetailScreen(
              transaction: transaction,
              category: category,
              currencySymbol: currencySymbol,
            ),
          ),
        );
        if (result == true && onDeleted != null) {
          onDeleted!();
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            // Category Icon with circular colored container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(catIcon, color: catColor, size: 22),
            ),
            const SizedBox(width: 14),

            // Merchant & Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          transaction.merchant,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextEllipsis.ellipsis,
                        ),
                      ),
                      if (transaction.isAutoParsed) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sms, size: 10, color: Colors.blue),
                              SizedBox(width: 2),
                              Text(
                                'SMS',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${DateFormat('d MMM, h:mm a').format(transaction.date)} • ${transaction.bankName ?? category?.name ?? "General"}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextEllipsis.ellipsis,
                  ),
                ],
              ),
            ),

            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}$currencySymbol${transaction.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isIncome ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
                  ),
                ),
                if (transaction.accountLast4 != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '••${transaction.accountLast4}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
