import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../services/local_db_service.dart';
import '../widgets/transaction_tile.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  List<ExpenseTransaction> _allTransactions = [];
  List<ExpenseTransaction> _filteredTransactions = [];
  Map<String, ExpenseCategory> _categoryMap = {};
  String _searchQuery = '';
  String? _selectedCategoryFilter;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final categories = await LocalDatabaseService.instance.getCategories();
    final transactions = await LocalDatabaseService.instance.getAllTransactions();

    setState(() {
      _categoryMap = {for (var c in categories) c.id: c};
      _allTransactions = transactions;
      _applyFilter();
      _isLoading = false;
    });
  }

  void _applyFilter() {
    setState(() {
      _filteredTransactions = _allTransactions.where((tx) {
        final matchesSearch = _searchQuery.isEmpty ||
            tx.merchant.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (tx.bankName ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (tx.rawSMS ?? '').toLowerCase().contains(_searchQuery.toLowerCase());

        final matchesCat = _selectedCategoryFilter == null || tx.categoryId == _selectedCategoryFilter;

        return matchesSearch && matchesCat;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions'),
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search merchant, bank, or SMS keyword...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              onChanged: (val) {
                _searchQuery = val;
                _applyFilter();
              },
            ),
          ),

          // Categories Filter Scroll
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedCategoryFilter == null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategoryFilter = null;
                      _applyFilter();
                    });
                  },
                ),
                const SizedBox(width: 8),
                ..._categoryMap.values.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      avatar: Icon(cat.iconData, size: 16, color: cat.color),
                      label: Text(cat.name),
                      selected: _selectedCategoryFilter == cat.id,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategoryFilter = selected ? cat.id : null;
                          _applyFilter();
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Transaction Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredTransactions.length} Transactions',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTransactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inbox, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            const Text('No matching transactions found', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _filteredTransactions.length,
                        itemBuilder: (ctx, i) {
                          final tx = _filteredTransactions[i];
                          return TransactionTile(
                            transaction: tx,
                            category: _categoryMap[tx.categoryId],
                            onDeleted: _loadData,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
