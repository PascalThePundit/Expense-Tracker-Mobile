import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 0)
class TransactionModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  double amount;

  @HiveField(3)
  String category;

  @HiveField(4)
  bool isExpense; // true = expense, false = income

  @HiveField(5)
  DateTime date;

  @HiveField(6)
  String? note;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.isExpense,
    required this.date,
    this.note,
  });
}