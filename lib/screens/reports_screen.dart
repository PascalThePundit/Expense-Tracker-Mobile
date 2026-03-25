import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _touchedIndex = -1;

  final _incomeMeta = {
    'Offering': {
      'color': const Color(0xFF34D399),
      'icon': Icons.volunteer_activism_rounded,
    },
    'Tithe': {
      'color': const Color(0xFF2563EB),
      'icon': Icons.church_rounded,
    },
    'Sabbath School': {
      'color': const Color(0xFFFBBF24),
      'icon': Icons.menu_book_rounded,
    },
    'Alumni Donation': {
      'color': const Color(0xFFA78BFA),
      'icon': Icons.school_rounded,
    },
    'Others': {
      'color': const Color(0xFF94A3B8),
      'icon': Icons.add_circle_outline_rounded,
    },
  };

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<TransactionModel>('transactions');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<TransactionModel> box, _) {
          final transactions = box.values.toList();

          final incomeTransactions =
              transactions.where((t) => !t.isExpense).toList();
          final expenseTransactions =
              transactions.where((t) => t.isExpense).toList();

          final totalIncome = incomeTransactions.fold(
              0.0, (sum, t) => sum + t.amount);
          final totalExpense = expenseTransactions.fold(
              0.0, (sum, t) => sum + t.amount);

          // Group income by category
          final Map<String, double> incomeByCategory = {};
          for (final t in incomeTransactions) {
            incomeByCategory[t.category] =
                (incomeByCategory[t.category] ?? 0) + t.amount;
          }

          // Group expenses by category (free text — group by exact string)
          final Map<String, double> expenseByCategory = {};
          for (final t in expenseTransactions) {
            expenseByCategory[t.category] =
                (expenseByCategory[t.category] ?? 0) + t.amount;
          }

          final sortedExpenses = expenseByCategory.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page title
                  Text(
                    'Reports',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Overview of all church finances',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Summary row
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryTile(
                          label: 'Total Income',
                          amount: totalIncome,
                          color: const Color(0xFF34D399),
                          icon: Icons.arrow_downward_rounded,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildSummaryTile(
                          label: 'Total Expenses',
                          amount: totalExpense,
                          color: const Color(0xFFFB7185),
                          icon: Icons.arrow_upward_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Income pie chart
                  if (incomeByCategory.isNotEmpty) ...[
                    _buildSectionTitle('Income Breakdown'),
                    const SizedBox(height: 16),
                    _buildPieChartCard(incomeByCategory, totalIncome),
                    const SizedBox(height: 12),
                    _buildPieLegend(incomeByCategory, totalIncome),
                  ] else ...[
                    _buildEmptyCard('No income recorded yet'),
                  ],

                  const SizedBox(height: 28),

                  // Expense breakdown list
                  _buildSectionTitle('Expense Breakdown'),
                  const SizedBox(height: 16),

                  if (sortedExpenses.isNotEmpty)
                    ...sortedExpenses.map((entry) => _buildExpenseRow(
                          entry.key,
                          entry.value,
                          totalExpense,
                        ))
                  else
                    _buildEmptyCard('No expenses recorded yet'),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryTile({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    final formatter =
        NumberFormat.currency(symbol: '₦', decimalDigits: 2);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatter.format(amount),
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildPieChartCard(
      Map<String, double> data, double total) {
    final entries = data.entries.toList();

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex = pieTouchResponse
                          .touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sectionsSpace: 3,
                centerSpaceRadius: 48,
                sections: List.generate(entries.length, (i) {
                  final isTouched = i == _touchedIndex;
                  final entry = entries[i];
                  final meta = _incomeMeta[entry.key];
                  final color = (meta?['color'] as Color?) ??
                      const Color(0xFF94A3B8);
                  final percentage = total > 0
                      ? (entry.value / total * 100).toStringAsFixed(1)
                      : '0';

                  return PieChartSectionData(
                    color: color,
                    value: entry.value,
                    title: isTouched ? '$percentage%' : '',
                    radius: isTouched ? 58 : 50,
                    titleStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries.map((entry) {
              final meta = _incomeMeta[entry.key];
              final color = (meta?['color'] as Color?) ??
                  const Color(0xFF94A3B8);
              final percentage = total > 0
                  ? (entry.value / total * 100).toStringAsFixed(1)
                  : '0';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$percentage%',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPieLegend(
      Map<String, double> data, double total) {
    final formatter =
        NumberFormat.currency(symbol: '₦', decimalDigits: 2);
    return Column(
      children: data.entries.map((entry) {
        final meta = _incomeMeta[entry.key];
        final color =
            (meta?['color'] as Color?) ?? const Color(0xFF94A3B8);
        final icon = (meta?['icon'] as IconData?) ??
            Icons.attach_money_rounded;
        final percentage = total > 0
            ? (entry.value / total * 100).toStringAsFixed(1)
            : '0';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: total > 0 ? entry.value / total : 0,
                        backgroundColor:
                            color.withOpacity(0.12),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(color),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatter.format(entry.value),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExpenseRow(
      String label, double amount, double total) {
    final formatter =
        NumberFormat.currency(symbol: '₦', decimalDigits: 2);
    final percentage =
        total > 0 ? (amount / total * 100).toStringAsFixed(1) : '0';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFB7185).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.money_off_rounded,
              color: Color(0xFFFB7185),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total > 0 ? amount / total : 0,
                    backgroundColor:
                        const Color(0xFFFB7185).withOpacity(0.12),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFFB7185)),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatter.format(amount),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Text(
                '$percentage%',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}