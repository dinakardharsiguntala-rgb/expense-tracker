enum TransactionType { expense, income, transfer }

enum PaymentMode { upi, creditCard, debitCard, netBanking, cash, other }

class ExpenseTransaction {
  final String id;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String merchant;
  final DateTime date;
  final String note;
  final String? rawSMS;
  final String? bankName;
  final String? accountLast4;
  final PaymentMode paymentMode;
  final bool isAutoParsed;

  ExpenseTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.merchant,
    required this.date,
    this.note = '',
    this.rawSMS,
    this.bankName,
    this.accountLast4,
    this.paymentMode = PaymentMode.upi,
    this.isAutoParsed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'type': type.name,
      'category_id': categoryId,
      'merchant': merchant,
      'date': date.millisecondsSinceEpoch,
      'note': note,
      'raw_sms': rawSMS,
      'bank_name': bankName,
      'account_last4': accountLast4,
      'payment_mode': paymentMode.name,
      'is_auto_parsed': isAutoParsed ? 1 : 0,
    };
  }

  factory ExpenseTransaction.fromMap(Map<String, dynamic> map) {
    return ExpenseTransaction(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      categoryId: map['category_id'] as String,
      merchant: (map['merchant'] as String?) ?? 'Unknown',
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      note: (map['note'] as String?) ?? '',
      rawSMS: map['raw_sms'] as String?,
      bankName: map['bank_name'] as String?,
      accountLast4: map['account_last4'] as String?,
      paymentMode: PaymentMode.values.firstWhere(
        (e) => e.name == map['payment_mode'],
        orElse: () => PaymentMode.other,
      ),
      isAutoParsed: (map['is_auto_parsed'] as int? ?? 0) == 1,
    );
  }

  ExpenseTransaction copyWith({
    String? id,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? merchant,
    DateTime? date,
    String? note,
    String? rawSMS,
    String? bankName,
    String? accountLast4,
    PaymentMode? paymentMode,
    bool? isAutoParsed,
  }) {
    return ExpenseTransaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      merchant: merchant ?? this.merchant,
      date: date ?? this.date,
      note: note ?? this.note,
      rawSMS: rawSMS ?? this.rawSMS,
      bankName: bankName ?? this.bankName,
      accountLast4: accountLast4 ?? this.accountLast4,
      paymentMode: paymentMode ?? this.paymentMode,
      isAutoParsed: isAutoParsed ?? this.isAutoParsed,
    );
  }
}

