import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import 'add_transaction_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<TransactionModel>('transactions');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<TransactionModel> box, _) {
          final transactions = box.values.toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          final totalIncome = transactions
              .where((t) => !t.isExpense)
              .fold(0.0, (sum, t) => sum + t.amount);

          final totalExpense = transactions
              .where((t) => t.isExpense)
              .fold(0.0, (sum, t) => sum + t.amount);

          final balance = totalIncome - totalExpense;

          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(balance, totalIncome, totalExpense),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Recent Transactions',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: transactions.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            return _buildTransactionCard(
                                transactions[index]);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddTransactionScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF2563EB),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(
      double balance, double totalIncome, double totalExpense) {
    final formatter =
        NumberFormat.currency(symbol: '₦', decimalDigits: 2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Church Balance',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatter.format(balance),
            style: GoogleFonts.inter(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  label: 'Income',
                  amount: formatter.format(totalIncome),
                  icon: Icons.arrow_downward_rounded,
                  color: const Color(0xFF34D399),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  label: 'Expenses',
                  amount: formatter.format(totalExpense),
                  icon: Icons.arrow_upward_rounded,
                  color: const Color(0xFFFB7185),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  amount,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction) {
    final formatter =
        NumberFormat.currency(symbol: '₦', decimalDigits: 2);
    final dateFormatter = DateFormat('MMM d, yyyy');

    // Income category metadata
    final incomeMeta = {
      'Offering': {
        'icon': Icons.volunteer_activism_rounded,
        'color': const Color(0xFF34D399),
      },
      'Tithe': {
        'icon': Icons.church_rounded,
        'color': const Color(0xFF2563EB),
      },
      'Sabbath School': {
        'icon': Icons.menu_book_rounded,
        'color': const Color(0xFFFBBF24),
      },
      'Alumni Donation': {
        'icon': Icons.school_rounded,
        'color': const Color(0xFFA78BFA),
      },
      'Others': {
        'icon': Icons.add_circle_outline_rounded,
        'color': const Color(0xFF94A3B8),
      },
    };

    final IconData icon;
    final Color color;

    if (!transaction.isExpense) {
      final meta = incomeMeta[transaction.category];
      icon = (meta?['icon'] as IconData?) ?? Icons.attach_money_rounded;
      color = (meta?['color'] as Color?) ?? const Color(0xFF34D399);
    } else {
      icon = Icons.money_off_rounded;
      color = const Color(0xFFFB7185);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${transaction.category} • ${dateFormatter.format(transaction.date)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF94A3B8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${transaction.isExpense ? '-' : '+'}${formatter.format(transaction.amount)}',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: transaction.isExpense
                  ? const Color(0xFFFB7185)
                  : const Color(0xFF34D399),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.church_rounded,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap + to record your first entry',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}