class Budget {
  final String id;
  final String categoryId;
  final double monthlyLimit;

  Budget({
    required this.id,
    required this.categoryId,
    required this.monthlyLimit,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'monthly_limit': monthlyLimit,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as String,
      categoryId: map['category_id'] as String,
      monthlyLimit: (map['monthly_limit'] as num).toDouble(),
    );
  }
}
