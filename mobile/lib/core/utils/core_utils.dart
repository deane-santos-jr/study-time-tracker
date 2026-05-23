import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:study_time_tracker/core/api/api_error_response.dart';
import 'package:study_time_tracker/core/configs/themes.dart';

class CoreUtils {
  static String? validateEmail(String? value) {
    final pattern = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (value == null || value.isEmpty) return 'Email is required';
    if (!pattern.hasMatch(value)) return 'Enter a valid email address';
    return null;
  }

  static String? validateRequired(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String getErrorMessage(Object e) {
    if (e is APIErrorResponse) return e.message;
    return e.toString();
  }

  static int getErrorCode(Object e) {
    if (e is APIErrorResponse) return e.statusCode ?? 500;
    return 500;
  }

  static DateTime? dateTimeFromJson(String? date) =>
      date != null ? DateTime.parse(date).toLocal() : null;

  static String? dateTimeToJson(DateTime? date) => date?.toUtc().toIso8601String();

  static String formatDate(DateTime date) =>
      DateFormat('MMMM d, yyyy').format(date);

  static String formatTime(DateTime date) =>
      DateFormat('h:mm a').format(date);

  static String formatDateAndTime(DateTime date) =>
      '${formatDate(date)} ${formatTime(date)}';

  static String formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }

  /// "Xh YYm" style for totals shown on the home tile / subjects list.
  /// `dashOnZero` returns `—` when the total is zero, which is the right
  /// affordance for stat cells; pass `false` for inline rows where `0m` is
  /// preferable.
  static String formatHm(int seconds, {bool dashOnZero = false}) {
    if (seconds <= 0) return dashOnZero ? '—' : '0m';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  static void showNotification({
    required String message,
    required bool success,
    required BuildContext context,
  }) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    FocusScope.of(context).unfocus();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = success
        ? (isDark ? kMatchaStainNight : kMatchaStain)
        : theme.colorScheme.error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 4000),
        backgroundColor: bg,
        content: Text(
          message,
          style: TextStyle(
            color: kPulp,
            fontFamily: kFontGeist,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
