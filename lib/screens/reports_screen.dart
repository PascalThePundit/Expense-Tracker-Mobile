import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/transaction_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _touchedIncomeIndex = -1;
  int _touchedExpenseIndex = -1;
  bool _showAllIncome = false;
  bool _showAllExpenses = false;

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

  // Distinct colors for expense slices
  final List<Color> _expenseColors = [
    const Color(0xFFFB7185),
    const Color(0xFFFB923C),
    const Color(0xFFF472B6),
    const Color(0xFFE879F9),
    const Color(0xFFC084FC),
    const Color(0xFF818CF8),
    const Color(0xFF60A5FA),
    const Color(0xFF34D399),
  ];

  Future<void> _exportPdf(
    List<TransactionModel> transactions,
    double totalIncome,
    double totalExpense,
    double balance,
    Map<String, double> incomeByCategory,
    Map<String, double> expenseByCategory,
  ) async {
    final formatter = NumberFormat.currency(symbol: '₦', decimalDigits: 2);
    final dateFormatter = DateFormat('MMM d, yyyy');
    final now = DateFormat('MMMM d, yyyy – hh:mm a').format(DateTime.now());

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#2563EB'),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Church Finance Report',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Generated on $now',
                  style: const pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 24),

          // Summary
          pw.Text(
            'Summary',
            style: pw.TextStyle(
              fontSize: 15,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              _pdfSummaryBox('Total Income', formatter.format(totalIncome),
                  PdfColor.fromHex('#34D399')),
              pw.SizedBox(width: 12),
              _pdfSummaryBox('Total Expenses', formatter.format(totalExpense),
                  PdfColor.fromHex('#FB7185')),
              pw.SizedBox(width: 12),
              _pdfSummaryBox('Balance', formatter.format(balance),
                  PdfColor.fromHex('#2563EB')),
            ],
          ),

          pw.SizedBox(height: 24),

          // Income breakdown
          if (incomeByCategory.isNotEmpty) ...[
            pw.Text(
              'Income Breakdown',
              style: pw.TextStyle(
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColor.fromHex('#E2E8F0'),
                width: 0.5,
              ),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F1F5F9'),
                  ),
                  children: [
                    _pdfTableHeader('Category'),
                    _pdfTableHeader('Amount'),
                    _pdfTableHeader('%'),
                  ],
                ),
                ...incomeByCategory.entries.map(
                  (e) => pw.TableRow(
                    children: [
                      _pdfTableCell(e.key),
                      _pdfTableCell(formatter.format(e.value)),
                      _pdfTableCell(
                        '${totalIncome > 0 ? (e.value / totalIncome * 100).toStringAsFixed(1) : 0}%',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          pw.SizedBox(height: 24),

          // Expense breakdown
          if (expenseByCategory.isNotEmpty) ...[
            pw.Text(
              'Expense Breakdown',
              style: pw.TextStyle(
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColor.fromHex('#E2E8F0'),
                width: 0.5,
              ),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F1F5F9'),
                  ),
                  children: [
                    _pdfTableHeader('Description'),
                    _pdfTableHeader('Amount'),
                    _pdfTableHeader('%'),
                  ],
                ),
                ...expenseByCategory.entries.map(
                  (e) => pw.TableRow(
                    children: [
                      _pdfTableCell(e.key),
                      _pdfTableCell(formatter.format(e.value)),
                      _pdfTableCell(
                        '${totalExpense > 0 ? (e.value / totalExpense * 100).toStringAsFixed(1) : 0}%',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          pw.SizedBox(height: 24),

          // All transactions
          pw.Text(
            'All Transactions',
            style: pw.TextStyle(
              fontSize: 15,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(
              color: PdfColor.fromHex('#E2E8F0'),
              width: 0.5,
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F1F5F9'),
                ),
                children: [
                  _pdfTableHeader('Label'),
                  _pdfTableHeader('Category'),
                  _pdfTableHeader('Amount'),
                  _pdfTableHeader('Date'),
                ],
              ),
              ...transactions.map(
                (t) => pw.TableRow(
                  children: [
                    _pdfTableCell(t.title),
                    _pdfTableCell(t.category),
                    _pdfTableCell(
                      '${t.isExpense ? '-' : '+'}${formatter.format(t.amount)}',
                    ),
                    _pdfTableCell(dateFormatter.format(t.date)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Church_Finance_Report.pdf',
    );
  }

  pw.Widget _pdfSummaryBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 1.5),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _pdfTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey800,
        ),
      ),
    );
  }

  pw.Widget _pdfTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }

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

          final incomeTransactions =
              transactions.where((t) => !t.isExpense).toList();
          final expenseTransactions =
              transactions.where((t) => t.isExpense).toList();

          final totalIncome =
              incomeTransactions.fold(0.0, (sum, t) => sum + t.amount);
          final totalExpense =
              expenseTransactions.fold(0.0, (sum, t) => sum + t.amount);
          final balance = totalIncome - totalExpense;

          final Map<String, double> incomeByCategory = {};
          for (final t in incomeTransactions) {
            incomeByCategory[t.category] =
                (incomeByCategory[t.category] ?? 0) + t.amount;
          }

          final Map<String, double> expenseByCategory = {};
          for (final t in expenseTransactions) {
            expenseByCategory[t.category] =
                (expenseByCategory[t.category] ?? 0) + t.amount;
          }

          final sortedExpenses = expenseByCategory.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          final visibleIncome = _showAllIncome
              ? incomeByCategory.entries.toList()
              : incomeByCategory.entries.take(4).toList();

          final visibleExpenses = _showAllExpenses
              ? sortedExpenses
              : sortedExpenses.take(4).toList();

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row + export button
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reports',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'Church finance overview',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (transactions.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: () => _exportPdf(
                            transactions,
                            totalIncome,
                            totalExpense,
                            balance,
                            incomeByCategory,
                            expenseByCategory,
                          ),
                          icon: const Icon(Icons.picture_as_pdf_rounded,
                              size: 16),
                          label: Text(
                            'Export',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Summary tiles
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
                  _buildSectionTitle('Income Breakdown'),
                  const SizedBox(height: 16),
                  if (incomeByCategory.isNotEmpty) ...[
                    _buildPieChartCard(
                      data: incomeByCategory,
                      total: totalIncome,
                      isIncome: true,
                    ),
                    const SizedBox(height: 12),
                    ...visibleIncome.map((entry) => _buildLegendRow(
                          label: entry.key,
                          amount: entry.value,
                          total: totalIncome,
                          color: (_incomeMeta[entry.key]?['color'] as Color?) ??
                              const Color(0xFF94A3B8),
                          icon: (_incomeMeta[entry.key]?['icon'] as IconData?) ??
                              Icons.attach_money_rounded,
                        )),
                    if (incomeByCategory.length > 4)
                      _buildShowMoreButton(
                        isExpanded: _showAllIncome,
                        total: incomeByCategory.length,
                        onTap: () =>
                            setState(() => _showAllIncome = !_showAllIncome),
                      ),
                  ] else
                    _buildEmptyCard('No income recorded yet'),

                  const SizedBox(height: 28),

                  // Expense pie chart
                  _buildSectionTitle('Expense Breakdown'),
                  const SizedBox(height: 16),
                  if (expenseByCategory.isNotEmpty) ...[
                    _buildPieChartCard(
                      data: expenseByCategory,
                      total: totalExpense,
                      isIncome: false,
                    ),
                    const SizedBox(height: 12),
                    ...visibleExpenses.map((entry) => _buildLegendRow(
                          label: entry.key,
                          amount: entry.value,
                          total: totalExpense,
                          color: _expenseColors[
                              sortedExpenses.indexOf(entry) %
                                  _expenseColors.length],
                          icon: Icons.money_off_rounded,
                          isExpense: true,
                        )),
                    if (sortedExpenses.length > 4)
                      _buildShowMoreButton(
                        isExpanded: _showAllExpenses,
                        total: sortedExpenses.length,
                        onTap: () => setState(
                            () => _showAllExpenses = !_showAllExpenses),
                      ),
                  ] else
                    _buildEmptyCard('No expenses recorded yet'),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          );
        },
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

  Widget _buildPieChartCard({
    required Map<String, double> data,
    required double total,
    required bool isIncome,
  }) {
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
                        if (isIncome) {
                          _touchedIncomeIndex = -1;
                        } else {
                          _touchedExpenseIndex = -1;
                        }
                        return;
                      }
                      final idx = pieTouchResponse
                          .touchedSection!.touchedSectionIndex;
                      if (isIncome) {
                        _touchedIncomeIndex = idx;
                      } else {
                        _touchedExpenseIndex = idx;
                      }
                    });
                  },
                ),
                sectionsSpace: 3,
                centerSpaceRadius: 48,
                sections: List.generate(entries.length, (i) {
                  final touchedIndex =
                      isIncome ? _touchedIncomeIndex : _touchedExpenseIndex;
                  final isTouched = i == touchedIndex;
                  final entry = entries[i];

                  final Color color;
                  if (isIncome) {
                    color = (_incomeMeta[entry.key]?['color'] as Color?) ??
                        const Color(0xFF94A3B8);
                  } else {
                    color = _expenseColors[i % _expenseColors.length];
                  }

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
            children: entries.take(5).map((entry) {
              final int idx = entries.indexOf(entry);
              final Color color;
              if (isIncome) {
                color = (_incomeMeta[entry.key]?['color'] as Color?) ??
                    const Color(0xFF94A3B8);
              } else {
                color = _expenseColors[idx % _expenseColors.length];
              }
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
                    SizedBox(
                      width: 90,
                      child: Text(
                        '${entry.key} ($percentage%)',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1E293B),
                        ),
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildLegendRow({
    required String label,
    required double amount,
    required double total,
    required Color color,
    required IconData icon,
    bool isExpense = false,
  }) {
    final formatter =
        NumberFormat.currency(symbol: '₦', decimalDigits: 2);
    final percentage =
        total > 0 ? (amount / total * 100).toStringAsFixed(1) : '0';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    backgroundColor: color.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
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

  Widget _buildShowMoreButton({
    required bool isExpanded,
    required int total,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF2563EB).withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isExpanded
                    ? 'Show less'
                    : 'Show all $total items',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: const Color(0xFF2563EB),
                size: 18,
              ),
            ],
          ),
        ),
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