import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class FormatUtils {
  // Safe currency formatter
  static String formatCurrency(double value) {
    try {
      return NumberFormat('#,###', 'vi_VN').format(value);
    } catch (e) {
      try {
        return NumberFormat('#,###').format(value);
      } catch (e) {
        // Fallback manual formatting
        return value.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
      }
    }
  }

  // Safe date formatter with day name
  static String formatDate(DateTime date) {
    try {
      return DateFormat('dd/MM/yyyy - EEEE', 'vi_VN').format(date);
    } catch (e) {
      try {
        return DateFormat('dd/MM/yyyy - EEEE').format(date);
      } catch (e) {
        return DateFormat('dd/MM/yyyy').format(date);
      }
    }
  }

  // Safe simple date formatter
  static String formatSimpleDate(DateTime date) {
    try {
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  // Safe time formatter
  static String formatTime(DateTime date) {
    try {
      return DateFormat('HH:mm').format(date);
    } catch (e) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  // Safe date time formatter
  static String formatDateTime(DateTime date) {
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return '${formatSimpleDate(date)} ${formatTime(date)}';
    }
  }

  // Format currency with VND suffix
  static String formatCurrencyVND(double value) {
    return '${formatCurrency(value)} VNĐ';
  }

  // Format percentage
  static String formatPercentage(double value) {
    try {
      return NumberFormat('#,##0.00').format(value);
    } catch (e) {
      return value.toStringAsFixed(2);
    }
  }

  // Parse currency string back to double
  static double parseCurrency(String value) {
    try {
      // Remove all non-digits (including commas, spaces, currency symbols)
      final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
      if (cleanValue.isEmpty) return 0.0;
      return double.parse(cleanValue);
    } catch (e) {
      return 0.0;
    }
  }
}

// Currency Input Formatter for real-time formatting
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Only allow digits
    final newText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (newText.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Parse to double and format
    final number = double.tryParse(newText) ?? 0;
    final formatted = FormatUtils.formatCurrency(number);
    
    // Calculate cursor position
    final oldLength = oldValue.text.length;
    final newLength = formatted.length;
    final selectionOffset = newValue.selection.end + (newLength - oldLength);
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: selectionOffset.clamp(0, formatted.length),
      ),
    );
  }
} 