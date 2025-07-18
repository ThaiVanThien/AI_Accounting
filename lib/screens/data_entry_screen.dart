import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/finance_record.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

class Event {
  final String title;
  
  const Event(this.title);
  
  @override
  String toString() => title;
}

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,##0', 'vi_VN');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Nếu text trống, trả về giá trị mới
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Loại bỏ tất cả ký tự không phải số
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    // Nếu không có số nào, trả về text trống
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // Tránh số 0 ở đầu (trừ khi chỉ có 1 số 0)
    if (digitsOnly.length > 1 && digitsOnly.startsWith('0')) {
      digitsOnly = digitsOnly.substring(1);
    }

    // Parse và format lại
    final int value = int.parse(digitsOnly);
    final String formatted = _formatter.format(value);

    // Tính toán vị trí cursor thông minh hơn
    int cursorPosition = formatted.length;
    
    // Nếu user đang xóa, giữ cursor ở vị trí phù hợp
    if (newValue.text.length < oldValue.text.length) {
      final oldDigits = oldValue.text.replaceAll(RegExp(r'[^\d]'), '');
      final newDigits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
      
      if (oldDigits.length > newDigits.length) {
        // Tính toán vị trí cursor dựa trên số ký tự đã xóa
        final deletedChars = oldDigits.length - newDigits.length;
        cursorPosition = (formatted.length - deletedChars).clamp(0, formatted.length);
      }
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}

class DataEntryScreen extends StatefulWidget {
  final Function(FinanceRecord) onAddRecord;

  const DataEntryScreen({super.key, required this.onAddRecord});

  @override
  State<DataEntryScreen> createState() => _DataEntryScreenState();
}

class _DataEntryScreenState extends State<DataEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _doanhThuController = TextEditingController();
  final _chiPhiController = TextEditingController();
  final _ghiChuController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _doanhThuController.dispose();
    _chiPhiController.dispose();
    _ghiChuController.dispose();
    super.dispose();
  }

  Future<void> _showCalendarDialog() async {
    DateTime? selectedDate = _selectedDate;
    
    final result = await showDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.radiusL),
          ),
          child: Container(
            padding: const EdgeInsets.all(AppStyles.spacingL),
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              borderRadius: BorderRadius.circular(AppStyles.radiusL),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowMedium,
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: AppColors.primaryBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppStyles.spacingM),
                    const Expanded(
                      child: Text(
                        'Chọn ngày giao dịch',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: AppStyles.spacingL),
                
                // Calendar
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(AppStyles.radiusM),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: TableCalendar<Event>(
                    firstDay: DateTime(2020, 1, 1),
                    lastDay: DateTime.now(),
                    focusedDay: selectedDate ?? DateTime.now(),
                    selectedDayPredicate: (day) {
                      return isSameDay(selectedDate, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        selectedDate = selectedDay;
                      });
                    },
                    calendarFormat: CalendarFormat.month,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: AppColors.primaryBlue,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekdayStyle: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      weekendStyle: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      weekendTextStyle: const TextStyle(
                        color: AppColors.error,
                      ),
                      holidayTextStyle: const TextStyle(
                        color: AppColors.error,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      selectedTextStyle: const TextStyle(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      todayDecoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                      defaultDecoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      defaultTextStyle: const TextStyle(
                        color: AppColors.textPrimary,
                      ),
                      disabledTextStyle: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                      markerDecoration: BoxDecoration(
                        color: AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppStyles.spacingL),
                
                // Selected date display
                Container(
                  padding: const EdgeInsets.all(AppStyles.spacingM),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(AppStyles.radiusM),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.event,
                        color: AppColors.primaryBlue,
                        size: 20,
                      ),
                      const SizedBox(width: AppStyles.spacingS),
                      const Text(
                        'Ngày đã chọn:',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: AppStyles.spacingS),
                      Text(
                        DateFormat('dd/MM/yyyy').format(selectedDate ?? DateTime.now()),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppStyles.spacingL),
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppStyles.spacingL,
                          vertical: AppStyles.spacingS,
                        ),
                      ),
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: AppStyles.spacingS),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, selectedDate),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: AppColors.textOnPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppStyles.spacingL,
                          vertical: AppStyles.spacingS,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppStyles.radiusM),
                        ),
                      ),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Chọn'),
                    ),
                  ],
                ),
              ],
            ),
          ),
                   ),
      ),
    );
    
    if (result != null) {
      setState(() {
        _selectedDate = result;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Parse giá trị từ text đã được format
      final doanhThuText = _doanhThuController.text.replaceAll(RegExp(r'[^\d]'), '');
      final chiPhiText = _chiPhiController.text.replaceAll(RegExp(r'[^\d]'), '');
      
      final record = FinanceRecord(
        id: 0,
        doanhThu: double.parse(doanhThuText.isEmpty ? '0' : doanhThuText),
        chiPhi: double.parse(chiPhiText.isEmpty ? '0' : chiPhiText),
        ghiChu: _ghiChuController.text,
        ngayTao: _selectedDate,
      );

      widget.onAddRecord(record);

      // Reset form
      _doanhThuController.clear();
      _chiPhiController.clear();
      _ghiChuController.clear();
      setState(() {
        _selectedDate = DateTime.now();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.textOnPrimary),
              SizedBox(width: AppStyles.spacingS),
              Text('Đã thêm dữ liệu thành công!'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.radiusM),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhập Dữ Liệu Tài Chính'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundLight,
              AppColors.backgroundWhite,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppStyles.spacingM),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card
                Container(
                  decoration: AppStyles.cardDecoration,
                  padding: const EdgeInsets.all(AppStyles.spacingM),
                  margin: const EdgeInsets.only(bottom: AppStyles.spacingL),
                  child: Column(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        size: 48,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(height: AppStyles.spacingS),
                      Text(
                        'Nhập Thông Tin Tài Chính',
                        style: AppStyles.headingMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppStyles.spacingXS),
                      Text(
                        'Vui lòng nhập thông tin doanh thu và chi phí của bạn',
                        style: AppStyles.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Form Card
                Container(
                  decoration: AppStyles.elevatedCardDecoration,
                  padding: const EdgeInsets.all(AppStyles.spacingL),
                  child: Column(
                    children: [
                      // Doanh Thu Field
                      TextFormField(
                        controller: _doanhThuController,
                        decoration: AppStyles.inputDecoration.copyWith(
                          labelText: 'Doanh Thu (VNĐ)',
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(AppStyles.spacingS),
                            padding: const EdgeInsets.all(AppStyles.spacingM),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppStyles.radiusS),
                            ),
                            child: const Icon(
                              Icons.trending_up,
                              color: AppColors.success,
                              size: 20,
                            ),
                          ),
                          hintText: 'Ví dụ: 1,000,000',
                          suffixText: 'VNĐ',
                          suffixStyle: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        style: AppStyles.bodyLarge,
                        inputFormatters: [
                          CurrencyInputFormatter(),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập doanh thu';
                          }
                          final numericValue = value.replaceAll(RegExp(r'[^\d]'), '');
                          if (numericValue.isEmpty || double.tryParse(numericValue) == null) {
                            return 'Vui lòng nhập số hợp lệ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppStyles.spacingL),

                      // Chi Phí Field
                      TextFormField(
                        controller: _chiPhiController,
                        decoration: AppStyles.inputDecoration.copyWith(
                          labelText: 'Chi Phí (VNĐ)',
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(AppStyles.spacingS),
                            padding: const EdgeInsets.all(AppStyles.spacingM),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppStyles.radiusS),
                            ),
                            child: const Icon(
                              Icons.trending_down,
                              color: AppColors.error,
                              size: 20,
                            ),
                          ),
                          hintText: 'Ví dụ: 500,000',
                          suffixText: 'VNĐ',
                          suffixStyle:
                            AppStyles.bodyLarge,
                        ),
                        keyboardType: TextInputType.number,
                        style: AppStyles.bodyLarge,
                        inputFormatters: [
                          CurrencyInputFormatter(),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập chi phí';
                          }
                          final numericValue = value.replaceAll(RegExp(r'[^\d]'), '');
                          if (numericValue.isEmpty || double.tryParse(numericValue) == null) {
                            return 'Vui lòng nhập số hợp lệ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppStyles.spacingL),

                      // Ghi Chú Field
                      TextFormField(
                        controller: _ghiChuController,
                        decoration: AppStyles.inputDecoration.copyWith(
                          labelText: 'Ghi Chú',
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(AppStyles.spacingS),
                            padding: const EdgeInsets.all(AppStyles.spacingS),
                            decoration: BoxDecoration(
                              color: AppColors.info.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppStyles.radiusS),
                            ),
                            child: const Icon(
                              Icons.note_alt,
                              color: AppColors.info,
                              size: 20,
                            ),
                          ),
                          hintText: 'Nhập ghi chú (tùy chọn)',
                        ),
                        maxLines: 3,
                        style: AppStyles.bodyLarge,
                      ),
                      const SizedBox(height: AppStyles.spacingL),

                      // Date Picker
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(AppStyles.radiusM),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        padding: const EdgeInsets.all(AppStyles.spacingM),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppStyles.spacingS),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppStyles.radiusS),
                              ),
                              child: const Icon(
                                Icons.calendar_today,
                                color: AppColors.warning,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: AppStyles.spacingM),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ngày giao dịch',
                                    style: AppStyles.bodyMedium,
                                  ),
                                  const SizedBox(height: AppStyles.spacingXS),
                                  Text(
                                    DateFormat('dd/MM/yyyy').format(_selectedDate),
                                    style: AppStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _showCalendarDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: AppColors.textOnPrimary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppStyles.spacingXS,
                                  vertical: AppStyles.spacingXS,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppStyles.radiusM),
                                ),
                              ),
                              icon: const Icon(Icons.calendar_month, size: 18),
                              label: Text('Chọn ngày',style: TextStyle(fontSize: 12),),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppStyles.spacingXL),

                // Submit Button
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppStyles.radiusM),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowMedium,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppStyles.radiusM),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_circle,
                          color: AppColors.textOnPrimary,
                          size: 24,
                        ),
                        const SizedBox(width: AppStyles.spacingS),
                        Text(
                          'Thêm Dữ Liệu',
                          style: AppStyles.buttonText.copyWith(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 