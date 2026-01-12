import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../controllers/transaction_controller.dart';
import '../../models/transaction_model.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

/// Add/Edit transaction view with screenshot upload and manual entry
class AddTransactionView extends StatefulWidget {
  final Transaction? editTransaction;

  const AddTransactionView({
    super.key,
    this.editTransaction,
  });

  @override
  State<AddTransactionView> createState() => _AddTransactionViewState();
}

class _AddTransactionViewState extends State<AddTransactionView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  // Form controllers
  late TextEditingController _amountController;
  late TextEditingController _payeeController;
  late TextEditingController _notesController;
  late TextEditingController _upiIdController;
  late TextEditingController _bankController;
  late TextEditingController _sourceAppController;

  // Form state
  String _txnType = 'DEBIT';
  String _category = 'Other';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  // Image state
  File? _selectedImage;
  bool _isProcessingImage = false;
  Transaction? _extractedTransaction;

  bool get isEditing => widget.editTransaction != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize controllers
    _amountController = TextEditingController();
    _payeeController = TextEditingController();
    _notesController = TextEditingController();
    _upiIdController = TextEditingController();
    _bankController = TextEditingController();
    _sourceAppController = TextEditingController();

    // If editing, populate fields
    if (isEditing) {
      final txn = widget.editTransaction!;
      _amountController.text = txn.amount.toString();
      _payeeController.text = txn.payee ?? '';
      _notesController.text = txn.notes ?? '';
      _upiIdController.text = txn.upiTransactionId ?? '';
      _bankController.text = txn.bankAccount ?? '';
      _sourceAppController.text = txn.sourceApp ?? '';
      _txnType = txn.txnType;
      _category = txn.category ?? 'Other';
      if (txn.transactionDate != null) {
        _selectedDate = txn.transactionDate!;
      }
      // Skip to manual entry tab when editing
      _tabController.index = 1;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _payeeController.dispose();
    _notesController.dispose();
    _upiIdController.dispose();
    _bankController.dispose();
    _sourceAppController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.close, color: AppTheme.textPrimary),
        ),
        title: Text(isEditing ? 'Edit Transaction' : 'Add Transaction'),
        bottom: isEditing
            ? null
            : TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primaryColor,
                labelColor: AppTheme.primaryLight,
                unselectedLabelColor: AppTheme.textMuted,
                tabs: const [
                  Tab(text: 'Screenshot'),
                  Tab(text: 'Manual Entry'),
                ],
              ),
      ),
      body: isEditing
          ? _buildManualEntryForm()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildScreenshotTab(),
                _buildManualEntryForm(),
              ],
            ),
    );
  }

  Widget _buildScreenshotTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Image picker area
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.dividerColor,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: _selectedImage != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (_isProcessingImage)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                    color: AppTheme.primaryColor,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Extracting data...',
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                _selectedImage = null;
                                _extractedTransaction = null;
                              });
                            },
                            icon: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_outlined,
                            color: AppTheme.primaryLight,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Tap to upload screenshot',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'We\'ll auto-extract transaction details',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 20),

          // Extracted data preview
          if (_extractedTransaction != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.successColor.withOpacity(0.5),
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
                          color: AppTheme.successColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: AppTheme.successColor,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Transaction Extracted',
                        style: TextStyle(
                          color: AppTheme.successColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildExtractedRow(
                    'Amount',
                    _extractedTransaction!.formattedAmount,
                  ),
                  _buildExtractedRow(
                    'Payee',
                    _extractedTransaction!.payee ?? 'Unknown',
                  ),
                  _buildExtractedRow(
                    'Category',
                    _extractedTransaction!.category ?? 'Other',
                  ),
                  _buildExtractedRow(
                    'Date',
                    _extractedTransaction!.formattedDate,
                  ),
                  if (_extractedTransaction!.sourceApp != null)
                    _buildExtractedRow(
                      'Source',
                      _extractedTransaction!.sourceApp!,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveExtractedTransaction,
                child: const Text('Save Transaction'),
              ),
            ),
          ],

          // Pick image buttons
          if (_selectedImage == null) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(source: ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: const BorderSide(color: AppTheme.dividerColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(source: ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: const BorderSide(color: AppTheme.dividerColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExtractedRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualEntryForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction Type Toggle
            _buildSectionLabel('Transaction Type'),
            Row(
              children: [
                Expanded(
                  child: _buildTypeButton(
                    'DEBIT',
                    'Expense',
                    Icons.arrow_upward,
                    AppTheme.errorColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeButton(
                    'CREDIT',
                    'Income',
                    Icons.arrow_downward,
                    AppTheme.successColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Amount
            _buildSectionLabel('Amount'),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: TextStyle(
                  color: _txnType == 'DEBIT'
                      ? AppTheme.errorColor
                      : AppTheme.successColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                hintText: '0.00',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Payee
            _buildSectionLabel('Payee / Merchant'),
            TextFormField(
              controller: _payeeController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'e.g., Zomato, Amazon',
              ),
            ),
            const SizedBox(height: 24),

            // Category
            _buildSectionLabel('Category'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TransactionCategory.values.map((cat) {
                final isSelected = _category == cat.label;
                return GestureDetector(
                  onTap: () => setState(() => _category = cat.label),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cat.color.withOpacity(0.2)
                          : AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? cat.color : AppTheme.dividerColor,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cat.icon,
                          color: isSelected ? cat.color : AppTheme.textMuted,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          cat.label,
                          style: TextStyle(
                            color: isSelected ? cat.color : AppTheme.textSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Date & Time
            _buildSectionLabel('Date & Time'),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.dividerColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: AppTheme.textMuted,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('MMM dd, yyyy').format(_selectedDate),
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _selectTime,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.dividerColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: AppTheme.textMuted,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _selectedTime.format(context),
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Additional Details (Collapsible)
            ExpansionTile(
              title: const Text(
                'Additional Details',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 16),
              children: [
                TextFormField(
                  controller: _sourceAppController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Source App',
                    hintText: 'e.g., Google Pay, PhonePe',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bankController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Bank Account',
                    hintText: 'e.g., SBI ****1234',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _upiIdController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'UPI Transaction ID',
                    hintText: '12-digit reference number',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Notes
            _buildSectionLabel('Notes (Optional)'),
            TextFormField(
              controller: _notesController,
              style: const TextStyle(color: AppTheme.textPrimary),
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Add any notes about this transaction',
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveManualTransaction,
                child: Text(isEditing ? 'Update Transaction' : 'Save Transaction'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTypeButton(
    String type,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _txnType == type;

    return GestureDetector(
      onTap: () => setState(() => _txnType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppTheme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? color : AppTheme.textMuted, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppTheme.textMuted,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage({ImageSource source = ImageSource.gallery}) async {
    final XFile? image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _isProcessingImage = true;
        _extractedTransaction = null;
      });

      // Upload and process
      try {
        final transaction = await Get.find<TransactionController>()
            .uploadReceipt(_selectedImage!);
        
        setState(() {
          _extractedTransaction = transaction;
          _isProcessingImage = false;
        });
      } catch (e) {
        setState(() {
          _isProcessingImage = false;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              surface: AppTheme.surfaceColor,
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

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              surface: AppTheme.surfaceColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _saveExtractedTransaction() {
    // Transaction already saved via upload-receipt, just go back
    Get.back();
  }

  Future<void> _saveManualTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final timeString =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    final transaction = Transaction(
      id: widget.editTransaction?.id,
      txnType: _txnType,
      amount: double.parse(_amountController.text),
      payee: _payeeController.text.isNotEmpty ? _payeeController.text : null,
      category: _category,
      transactionDate: _selectedDate,
      transactionTime: timeString,
      sourceApp: _sourceAppController.text.isNotEmpty
          ? _sourceAppController.text
          : null,
      upiTransactionId:
          _upiIdController.text.isNotEmpty ? _upiIdController.text : null,
      bankAccount:
          _bankController.text.isNotEmpty ? _bankController.text : null,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    final controller = Get.find<TransactionController>();

    Transaction? result;
    if (isEditing && transaction.id != null) {
      result = await controller.updateTransaction(transaction.id!, transaction);
    } else {
      result = await controller.createTransaction(transaction);
    }

    if (result != null) {
      Get.back();
    }
  }
}
