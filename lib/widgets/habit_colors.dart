import 'package:flutter/material.dart';
import 'package:actiphibian/services/calendar_logic.dart';

class HabitColors {
  static const List<Color> palette = [
    Color(0xFF00897B),
    Color(0xFFEF6C00),
    Color(0xFF7B1FA2),
    Color(0xFF1565C0),
    Color(0xFFC2185B),
    Color(0xFF6D4C41),
    Color(0xFF3949AB),
    Color(0xFF827717),
  ];

  static const Color none = Color(0xFF757575);

  static Color forHabit(int? habitId) {
    final i = CalendarLogic.habitColorIndex(habitId, palette.length);
    return i < 0 ? none : palette[i];
  }
}
