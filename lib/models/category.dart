import 'package:flutter/material.dart';

class ExpenseCategory {
  final String id;
  final String name;
  final String icon;
  final String colorHex;
  final bool isIncome;

  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorHex,
    this.isIncome = false,
  });

  Color get color {
    final hex = colorHex.replaceAll('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return Colors.blue;
  }

  IconData get iconData {
    switch (icon) {
      case 'fastfood':
      case 'fork.knife':
        return Icons.restaurant;
      case 'shopping_cart':
      case 'cart':
        return Icons.shopping_cart;
      case 'receipt':
      case 'doc.text':
        return Icons.receipt_long;
      case 'movie':
      case 'tv':
        return Icons.movie;
      case 'directions_car':
      case 'car':
        return Icons.directions_car;
      case 'medical_services':
      case 'cross':
        return Icons.medical_services;
      case 'payments':
      case 'banknote':
        return Icons.payments;
      case 'trending_up':
      case 'chart.line.uptrend.xyaxis':
        return Icons.trending_up;
      case 'flight':
      case 'airplane':
        return Icons.flight;
      default:
        return Icons.category;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color_hex': colorHex,
      'is_income': isIncome ? 1 : 0,
    };
  }

  factory ExpenseCategory.fromMap(Map<String, dynamic> map) {
    return ExpenseCategory(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String,
      colorHex: map['color_hex'] as String,
      isIncome: (map['is_income'] as int? ?? 0) == 1,
    );
  }

  static const List<ExpenseCategory> defaultCategories = [
    ExpenseCategory(
      id: 'food',
      name: 'Food & Dining',
      icon: 'fastfood',
      colorHex: '#FF9500',
    ),
    ExpenseCategory(
      id: 'groceries',
      name: 'Groceries',
      icon: 'shopping_cart',
      colorHex: '#34C759',
    ),
    ExpenseCategory(
      id: 'shopping',
      name: 'Shopping',
      icon: 'shopping_cart',
      colorHex: '#AF52DE',
    ),
    ExpenseCategory(
      id: 'bills',
      name: 'Bills & Utilities',
      icon: 'receipt',
      colorHex: '#FF2D55',
    ),
    ExpenseCategory(
      id: 'entertainment',
      name: 'Entertainment',
      icon: 'movie',
      colorHex: '#5856D6',
    ),
    ExpenseCategory(
      id: 'transport',
      name: 'Transport & Fuel',
      icon: 'directions_car',
      colorHex: '#007AFF',
    ),
    ExpenseCategory(
      id: 'health',
      name: 'Health & Medical',
      icon: 'medical_services',
      colorHex: '#FF3B30',
    ),
    ExpenseCategory(
      id: 'travel',
      name: 'Travel & Trips',
      icon: 'flight',
      colorHex: '#30B0C7',
    ),
    ExpenseCategory(
      id: 'salary',
      name: 'Salary / Income',
      icon: 'payments',
      colorHex: '#34C759',
      isIncome: true,
    ),
    ExpenseCategory(
      id: 'investments',
      name: 'Investments',
      icon: 'trending_up',
      colorHex: '#00C7BE',
      isIncome: true,
    ),
    ExpenseCategory(
      id: 'others',
      name: 'Others',
      icon: 'category',
      colorHex: '#8E8E93',
    ),
  ];
}

