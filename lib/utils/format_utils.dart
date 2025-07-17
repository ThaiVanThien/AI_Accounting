import 'package:intl/intl.dart';

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
} 