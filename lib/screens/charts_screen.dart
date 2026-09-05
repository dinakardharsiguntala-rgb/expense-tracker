import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/local_db_service.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  Map<String, double> _categorySpending = {};
  Map<String, ExpenseCategory> _categoryMap = {};
  double _totalExpense = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSpendingData();
  }

  Future<void> _loadSpendingData() async {
    setState(() => _isLoading = true);
    final now = DateTime.now();

    final categories = await LocalDatabaseService.instance.getCategories();
    final catMap = {for (var c in categories) c.id: c};

    final spending = await LocalDatabaseService.instance.getCategorySpending(now.year, now.month);
    final total = spending.values.fold(0.0, (prev, elem) => prev + elem);

    setState(() {
      _categoryMap = catMap;
      _categorySpending = spending;
      _totalExpense = total;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Sort categories by spending descending
    final sortedEntries = _categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Analytics'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _totalExpense == 0.0
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'No spending data for this month',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('Log some expenses to view category breakdowns', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Total Spend Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text('Total Monthly Spend', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 6),
                          Text(
                            '₹${_totalExpense.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Visual Spending Proportion Bar
                    Container(
                      height: 18,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        color: Colors.grey.shade200,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Row(
                        children: sortedEntries.map((e) {
                          final pct = _totalExpense > 0 ? (e.value / _totalExpense) : 0.0;
                          final cat = _categoryMap[e.key];
                          return Expanded(
                            flex: (pct * 100).toInt().clamp(1, 100),
                            child: Container(
                              color: cat?.color ?? Colors.blueGrey,
                              margin: const EdgeInsets.symmetric(horizontal: 0.5),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Category Breakdown List
                    const Text('Category Breakdown', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...sortedEntries.map((e) {
                      final cat = _categoryMap[e.key];
                      final pct = _totalExpense > 0 ? (e.value / _totalExpense * 100) : 0.0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: (cat?.color ?? Colors.blue).withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(cat?.iconData ?? Icons.category, color: cat?.color ?? Colors.blue, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(cat?.name ?? e.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: pct / 100,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(cat?.color ?? Colors.blue),
                                    minHeight: 4,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('₹${e.value.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text('${pct.toStringAsFixed(1)}%', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
    );
  }
}

