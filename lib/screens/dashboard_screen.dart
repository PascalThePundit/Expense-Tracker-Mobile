import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../theme/app_theme.dart';
import 'add_transaction_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // null means "All" months
  DateTime? _selectedMonth;

  List<DateTime> _buildMonthList(List<TransactionModel> transactions) {
    final months = transactions
        .map((t) => DateTime(t.date.year, t.date.month))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    return months;
  }

  bool _isSelectedMonth(DateTime month) {
    return _selectedMonth != null &&
        _selectedMonth!.year == month.year &&
        _selectedMonth!.month == month.month;
  }

  List<TransactionModel> _filterTransactions(
      List<TransactionModel> all) {
    if (_selectedMonth == null) return all;
    return all
        .where((t) =>
            t.date.year == _selectedMonth!.year &&
            t.date.month == _selectedMonth!.month)
        .toList();
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w500),
        ),
        backgroundColor:
            isError ? const Color(0xFFFB7185) : const Color(0xFF2563EB),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<TransactionModel>('transactions');
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<TransactionModel> box, _) {
          final allTransactions = box.values.toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          final months = _buildMonthList(allTransactions);
          final filtered = _filterTransactions(allTransactions);

          final totalIncome = filtered
              .where((t) => !t.isExpense)
              .fold(0.0, (sum, t) => sum + t.amount);
          final totalExpense = filtered
              .where((t) => t.isExpense)
              .fold(0.0, (sum, t) => sum + t.amount);
          final balance = totalIncome - totalExpense;

          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(balance, totalIncome, totalExpense),

                // Month filter chips
                if (months.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: months.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildMonthChip(
                            label: 'All',
                            isSelected: _selectedMonth == null,
                            colors: colors,
                            onTap: () =>
                                setState(() => _selectedMonth = null),
                          );
                        }
                        final month = months[index - 1];
                        return _buildMonthChip(
                          label: DateFormat('MMM yyyy').format(month),
                          isSelected: _isSelectedMonth(month),
                          colors: colors,
                          onTap: () =>
                              setState(() => _selectedMonth = month),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        'Transactions',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (filtered.isNotEmpty)
                        Text(
                          '${filtered.length} record${filtered.length == 1 ? '' : 's'}',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: colors.textMuted),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Swipe left to delete • Tap to edit',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: colors.shimmer),
                  ),
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmptyState(colors)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            return _buildTransactionCard(
                                context, filtered[index], colors);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<String>(
            context,
            MaterialPageRoute(
                builder: (_) => const AddTransactionScreen()),
          );
          if (result != null) _showSnackbar(result);
        },
        backgroundColor: const Color(0xFF2563EB),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMonthChip({
    required String label,
    required bool isSelected,
    required AppColors colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB)
              : colors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : colors.border,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : colors.textSecondary,
          ),
        ),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.church_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Church Finance',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _selectedMonth == null
                ? 'Total Balance'
                : DateFormat('MMMM yyyy').format(_selectedMonth!),
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formatter.format(balance),
            style: GoogleFonts.inter(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
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
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: Colors.white70)),
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

  Widget _buildTransactionCard(BuildContext context,
      TransactionModel transaction, AppColors colors) {
    final formatter =
        NumberFormat.currency(symbol: '₦', decimalDigits: 2);
    final dateFormatter = DateFormat('MMM d, yyyy');

    final incomeMeta = {
      'Offering': {
        'icon': Icons.volunteer_activism_rounded,
        'color': const Color(0xFF34D399)
      },
      'Tithe': {
        'icon': Icons.church_rounded,
        'color': const Color(0xFF2563EB)
      },
      'Sabbath School': {
        'icon': Icons.menu_book_rounded,
        'color': const Color(0xFFFBBF24)
      },
      'Alumni Donation': {
        'icon': Icons.school_rounded,
        'color': const Color(0xFFA78BFA)
      },
      'Others': {
        'icon': Icons.add_circle_outline_rounded,
        'color': const Color(0xFF94A3B8)
      },
    };

    final IconData icon;
    final Color color;

    if (!transaction.isExpense) {
      final meta = incomeMeta[transaction.category];
      icon = (meta?['icon'] as IconData?) ?? Icons.attach_money_rounded;
      color =
          (meta?['color'] as Color?) ?? const Color(0xFF34D399);
    } else {
      icon = Icons.money_off_rounded;
      color = const Color(0xFFFB7185);
    }

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: colors.card,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Delete Transaction?',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: colors.textPrimary,
              ),
            ),
            content: Text(
              'This will permanently remove "${transaction.title}".',
              style: GoogleFonts.inter(
                  fontSize: 13, color: colors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel',
                    style: GoogleFonts.inter(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Delete',
                    style: GoogleFonts.inter(
                        color: const Color(0xFFFB7185),
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        transaction.delete();
        _showSnackbar('Transaction deleted');
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFB7185),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded,
            color: Colors.white, size: 26),
      ),
      child: GestureDetector(
        onTap: () async {
          final result = await Navigator.push<String>(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AddTransactionScreen(existing: transaction),
            ),
          );
          if (result != null) _showSnackbar(result);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
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
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${transaction.category} • ${dateFormatter.format(transaction.date)}',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: colors.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (transaction.note != null &&
                        transaction.note!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.notes_rounded,
                              size: 11, color: colors.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              transaction.note!,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: colors.textMuted,
                                fontStyle: FontStyle.italic,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
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
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.church_rounded, size: 64, color: colors.shimmer),
          const SizedBox(height: 16),
          Text(
            _selectedMonth == null
                ? 'No transactions yet'
                : 'No transactions for ${DateFormat('MMMM yyyy').format(_selectedMonth!)}',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            _selectedMonth == null
                ? 'Tap + to record your first entry'
                : 'Try selecting a different month',
            style: GoogleFonts.inter(
                fontSize: 13, color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}