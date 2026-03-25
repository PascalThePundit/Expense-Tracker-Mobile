import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? existing;

  const AddTransactionScreen({super.key, this.existing});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _expenseDescController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isExpense = false;
  String _selectedIncomeCategory = 'Offering';
  DateTime _selectedDate = DateTime.now();

  final List<Map<String, dynamic>> _incomeCategories = [
    {
      'name': 'Offering',
      'icon': Icons.volunteer_activism_rounded,
      'color': const Color(0xFF34D399),
    },
    {
      'name': 'Tithe',
      'icon': Icons.church_rounded,
      'color': const Color(0xFF2563EB),
    },
    {
      'name': 'Sabbath School',
      'icon': Icons.menu_book_rounded,
      'color': const Color(0xFFFBBF24),
    },
    {
      'name': 'Alumni Donation',
      'icon': Icons.school_rounded,
      'color': const Color(0xFFA78BFA),
    },
    {
      'name': 'Others',
      'icon': Icons.add_circle_outline_rounded,
      'color': const Color(0xFF94A3B8),
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final t = widget.existing!;
      _titleController.text = t.title;
      _amountController.text = t.amount.toString();
      _noteController.text = t.note ?? '';
      _isExpense = t.isExpense;
      if (t.isExpense) {
        _expenseDescController.text = t.category;
      } else {
        _selectedIncomeCategory = t.category;
      }
      _selectedDate = t.date;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _expenseDescController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveTransaction() {
    if (!_formKey.currentState!.validate()) return;

    final box = Hive.box<TransactionModel>('transactions');

    final transaction = TransactionModel(
      id: widget.existing?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      category: _isExpense
          ? _expenseDescController.text.trim()
          : _selectedIncomeCategory,
      isExpense: _isExpense,
      date: _selectedDate,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    if (widget.existing != null) {
      widget.existing!
        ..title = transaction.title
        ..amount = transaction.amount
        ..category = transaction.category
        ..isExpense = transaction.isExpense
        ..date = transaction.date
        ..note = transaction.note;
      widget.existing!.save();
    } else {
      box.put(transaction.id, transaction);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.existing != null ? 'Edit Transaction' : 'Add Transaction',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Type toggle
            Container(
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
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  _buildToggleButton('Income', false),
                  _buildToggleButton('Expense', true),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Title / reference
            _buildLabel('Reference / Label'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _titleController,
              hint: _isExpense
                  ? 'e.g. Generator fuel payment'
                  : 'e.g. Sunday morning offering',
              validator: (val) => val == null || val.trim().isEmpty
                  ? 'Please enter a label'
                  : null,
            ),

            const SizedBox(height: 20),

            // Amount
            _buildLabel('Amount (₦)'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _amountController,
              hint: '0.00',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter an amount';
                }
                if (double.tryParse(val) == null) {
                  return 'Enter a valid number';
                }
                if (double.parse(val) <= 0) {
                  return 'Amount must be greater than 0';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Income: category picker | Expense: description field
            if (!_isExpense) ...[
              _buildLabel('Income Type'),
              const SizedBox(height: 12),
              _buildIncomeCategoryList(),
            ] else ...[
              _buildLabel('What was this expense for?'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _expenseDescController,
                hint: 'e.g. PA system repair, stationery...',
                maxLines: 2,
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Please describe the expense'
                    : null,
              ),
            ],

            const SizedBox(height: 20),

            // Date
            _buildLabel('Date'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
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
                    const Icon(Icons.calendar_today_rounded,
                        color: Color(0xFF2563EB), size: 20),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('MMMM d, yyyy').format(_selectedDate),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF1E293B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded,
                        color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Note
            _buildLabel('Note (optional)'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _noteController,
              hint: 'Any extra details...',
              maxLines: 3,
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  widget.existing != null
                      ? 'Save Changes'
                      : 'Add Transaction',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isExpense) {
    final isSelected = _isExpense == isExpense;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isExpense = isExpense),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isExpense
                    ? const Color(0xFFFB7185)
                    : const Color(0xFF34D399))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color:
                    isSelected ? Colors.white : const Color(0xFF94A3B8),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIncomeCategoryList() {
    return Column(
      children: _incomeCategories.map((cat) {
        final isSelected = _selectedIncomeCategory == cat['name'];
        return GestureDetector(
          onTap: () =>
              setState(() => _selectedIncomeCategory = cat['name']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? (cat['color'] as Color).withOpacity(0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? cat['color'] as Color
                    : Colors.transparent,
                width: 2,
              ),
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
                    color:
                        (cat['color'] as Color).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    cat['icon'] as IconData,
                    color: cat['color'] as Color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  cat['name'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? cat['color'] as Color
                        : const Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: cat['color'] as Color,
                    size: 20,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF64748B),
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
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
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        maxLines: maxLines,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFFCBD5E1),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
                color: Color(0xFF2563EB), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
                color: Color(0xFFFB7185), width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
                color: Color(0xFFFB7185), width: 1.5),
          ),
          errorStyle: GoogleFonts.inter(
              fontSize: 12, color: const Color(0xFFFB7185)),
        ),
      ),
    );
  }
}