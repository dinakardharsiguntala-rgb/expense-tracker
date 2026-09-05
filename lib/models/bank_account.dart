class BankAccount {
  final String id;
  final String bankName;
  final String accountLast4;
  final String accountType; // 'Savings', 'Credit Card', 'Checking'
  final double currentBalance;
  final DateTime lastUpdated;

  BankAccount({
    required this.id,
    required this.bankName,
    required this.accountLast4,
    required this.accountType,
    required this.currentBalance,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bank_name': bankName,
      'account_last4': accountLast4,
      'account_type': accountType,
      'current_balance': currentBalance,
      'last_updated': lastUpdated.millisecondsSinceEpoch,
    };
  }

  factory BankAccount.fromMap(Map<String, dynamic> map) {
    return BankAccount(
      id: map['id'] as String,
      bankName: map['bank_name'] as String,
      accountLast4: map['account_last4'] as String,
      accountType: (map['account_type'] as String?) ?? 'Savings',
      currentBalance: (map['current_balance'] as num).toDouble(),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(map['last_updated'] as int),
    );
  }
}

