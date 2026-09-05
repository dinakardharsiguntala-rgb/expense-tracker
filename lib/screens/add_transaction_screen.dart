import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../services/local_db_service.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _noteController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  String _selectedCategoryId = 'food';
  PaymentMode _selectedPaymentMode = PaymentMode.upi;
  List<ExpenseCategory> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final list = await LocalDatabaseService.instance.getCategories();
    setState(() {
      _categories = list;
      _isLoading = false;
    });
  }

  Future<void> _saveTransaction() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid positive amount')),
      );
      return;
    }

    final merchant = _merchantController.text.trim().isEmpty ? 'General' : _merchantController.text.trim();

    final tx = ExpenseTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      type: _selectedType,
      categoryId: _selectedCategoryId,
      merchant: merchant,
      date: DateTime.now(),
      note: _noteController.text.trim(),
      paymentMode: _selectedPaymentMode,
      isAutoParsed: false,
    );

    await LocalDatabaseService.instance.insertTransaction(tx);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Type Selector (Expense vs Income)
                  SegmentedButton<TransactionType>(
                    segments: const [
                      ButtonSegment(value: TransactionType.expense, label: Text('Expense'), icon: Icon(Icons.arrow_upward)),
                      ButtonSegment(value: TransactionType.income, label: Text('Income'), icon: Icon(Icons.arrow_downward)),
                    ],
                    selected: {_selectedType},
                    onSelectionChanged: (set) {
                      setState(() {
                        _selectedType = set.first;
                        if (_selectedType == TransactionType.income) {
                          _selectedCategoryId = 'salary';
                        } else {
                          _selectedCategoryId = 'food';
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Amount
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      labelText: 'Amount',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Merchant / Payee
                  TextField(
                    controller: _merchantController,
                    decoration: InputDecoration(
                      labelText: _selectedType == TransactionType.expense ? 'Merchant / Store' : 'Source / Payer',
                      hintText: 'e.g. Starbucks, Amazon, Salary',
                      prefixIcon: const Icon(Icons.storefront),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      prefixIcon: const Icon(Icons.category),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    items: _categories.map((c) {
                      return DropdownMenuItem(
                        value: c.id,
                        child: Row(
                          children: [
                            Icon(c.iconData, color: c.color, size: 20),
                            const SizedBox(width: 10),
                            Text(c.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategoryId = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Payment Mode Dropdown
                  DropdownButtonFormField<PaymentMode>(
                    value: _selectedPaymentMode,
                    decoration: InputDecoration(
                      labelText: 'Payment Mode',
                      prefixIcon: const Icon(Icons.payments_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    items: PaymentMode.values.map((m) {
                      return DropdownMenuItem(
                        value: m,
                        child: Text(m.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedPaymentMode = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  TextField(
                    controller: _noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Note (Optional)',
                      hintText: 'Add remarks...',
                      prefixIcon: const Icon(Icons.note_alt_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  ElevatedButton(
                    onPressed: _saveTransaction,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Save Transaction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
    );
  }
}
