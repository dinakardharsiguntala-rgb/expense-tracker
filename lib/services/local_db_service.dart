import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/budget.dart';
import '../models/bank_account.dart';

class LocalDatabaseService {
  static final LocalDatabaseService instance = LocalDatabaseService._init();
  static Database? _database;

  LocalDatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expense_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color_hex TEXT NOT NULL,
        is_income INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category_id TEXT NOT NULL,
        merchant TEXT NOT NULL,
        date INTEGER NOT NULL,
        note TEXT,
        raw_sms TEXT,
        bank_name TEXT,
        account_last4 TEXT,
        payment_mode TEXT NOT NULL,
        is_auto_parsed INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        monthly_limit REAL NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE bank_accounts (
        id TEXT PRIMARY KEY,
        bank_name TEXT NOT NULL,
        account_last4 TEXT NOT NULL,
        account_type TEXT NOT NULL,
        current_balance REAL NOT NULL,
        last_updated INTEGER NOT NULL
      )
    ''');

    // Populate initial categories
    final batch = db.batch();
    for (var cat in ExpenseCategory.defaultCategories) {
      batch.insert('categories', cat.toMap());
    }
    await batch.commit();
  }

  // --- Transactions CRUD ---

  Future<int> insertTransaction(ExpenseTransaction tx) async {
    final db = await instance.database;
    return await db.insert(
      'transactions',
      tx.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ExpenseTransaction>> getAllTransactions() async {
    final db = await instance.database;
    final maps = await db.query('transactions', orderBy: 'date DESC');
    return maps.map((m) => ExpenseTransaction.fromMap(m)).toList();
  }

  Future<List<ExpenseTransaction>> getRecentTransactions({int limit = 10}) async {
    final db = await instance.database;
    final maps = await db.query(
      'transactions',
      orderBy: 'date DESC',
      limit: limit,
    );
    return maps.map((m) => ExpenseTransaction.fromMap(m)).toList();
  }

  Future<int> updateTransaction(ExpenseTransaction tx) async {
    final db = await instance.database;
    return await db.update(
      'transactions',
      tx.toMap(),
      where: 'id = ?',
      whereArgs: [tx.id],
    );
  }

  Future<int> deleteTransaction(String id) async {
    final db = await instance.database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Financial Dashboard Aggregations ---

  Future<double> getMonthlyExpenseTotal(int year, int month) async {
    final db = await instance.database;
    final start = DateTime(year, month, 1).millisecondsSinceEpoch;
    final end = DateTime(year, month + 1, 1).millisecondsSinceEpoch;

    final result = await db.rawQuery('''
      SELECT SUM(amount) as total FROM transactions
      WHERE type = 'expense' AND date >= ? AND date < ?
    ''', [start, end]);

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getMonthlyIncomeTotal(int year, int month) async {
    final db = await instance.database;
    final start = DateTime(year, month, 1).millisecondsSinceEpoch;
    final end = DateTime(year, month + 1, 1).millisecondsSinceEpoch;

    final result = await db.rawQuery('''
      SELECT SUM(amount) as total FROM transactions
      WHERE type = 'income' AND date >= ? AND date < ?
    ''', [start, end]);

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, double>> getCategorySpending(int year, int month) async {
    final db = await instance.database;
    final start = DateTime(year, month, 1).millisecondsSinceEpoch;
    final end = DateTime(year, month + 1, 1).millisecondsSinceEpoch;

    final result = await db.rawQuery('''
      SELECT category_id, SUM(amount) as total FROM transactions
      WHERE type = 'expense' AND date >= ? AND date < ?
      GROUP BY category_id
    ''', [start, end]);

    final Map<String, double> map = {};
    for (var row in result) {
      final catId = row['category_id'] as String;
      final total = (row['total'] as num).toDouble();
      map[catId] = total;
    }
    return map;
  }

  // --- Categories CRUD ---

  Future<List<ExpenseCategory>> getCategories() async {
    final db = await instance.database;
    final maps = await db.query('categories');
    return maps.map((m) => ExpenseCategory.fromMap(m)).toList();
  }

  Future<ExpenseCategory?> getCategoryById(String id) async {
    final db = await instance.database;
    final maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return ExpenseCategory.fromMap(maps.first);
    }
    return null;
  }

  // --- Budgets ---

  Future<List<Budget>> getBudgets() async {
    final db = await instance.database;
    final maps = await db.query('budgets');
    return maps.map((m) => Budget.fromMap(m)).toList();
  }

  Future<int> setBudget(Budget budget) async {
    final db = await instance.database;
    return await db.insert(
      'budgets',
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- Backup & Restore (JSON Export/Import) ---

  Future<String> exportToJson() async {
    final db = await instance.database;
    final txList = await db.query('transactions');
    final catList = await db.query('categories');
    final budgetList = await db.query('budgets');

    final backup = {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'categories': catList,
      'transactions': txList,
      'budgets': budgetList,
    };
    return const JsonEncoder.withIndent('  ').convert(backup);
  }

  Future<bool> importFromJson(String jsonString) async {
    try {
      final db = await instance.database;
      final Map<String, dynamic> data = jsonDecode(jsonString);
      final List txList = data['transactions'] as List? ?? [];

      final batch = db.batch();
      for (var item in txList) {
        batch.insert(
          'transactions',
          Map<String, dynamic>.from(item),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

