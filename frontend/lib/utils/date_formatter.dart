import 'package:intl/intl.dart';

/// DateFormatter provides formatted date strings.
class DateFormatter {
  /// Returns date as 'yyyy-MM-dd'
  static String yMd(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  /// Returns date as 'yyyy.MM.dd EEEE'
  static String long(DateTime date) => DateFormat('yyyy.MM.dd EEEE').format(date);
}