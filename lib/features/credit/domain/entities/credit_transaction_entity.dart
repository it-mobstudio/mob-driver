class CreditTransactionEntity {
  const CreditTransactionEntity({
    required this.id,
    required this.amount,
    required this.remarks,
    required this.currentBalance,
    required this.transactionType,
    required this.createdAt,
    required this.orderNumber,
  });

  final int id;
  final double amount;
  final String remarks;
  final double currentBalance;
  final String transactionType;
  final DateTime? createdAt;
  final String orderNumber;

  bool get isDebit => transactionType.toUpperCase() == 'DEBIT' || amount < 0;

  factory CreditTransactionEntity.fromMap(Map<String, dynamic> map) {
    final order = map['order'] is Map
        ? Map<String, dynamic>.from(map['order'] as Map)
        : <String, dynamic>{};
    return CreditTransactionEntity(
      id: int.tryParse((map['id'] ?? '0').toString()) ?? 0,
      amount: double.tryParse((map['amount'] ?? '0').toString()) ?? 0,
      remarks: (map['remarks'] ?? '').toString(),
      currentBalance:
          double.tryParse((map['current_balance'] ?? '0').toString()) ?? 0,
      transactionType: (map['transaction_type'] ?? '').toString(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()),
      orderNumber: (order['order_id'] ?? '').toString(),
    );
  }
}
