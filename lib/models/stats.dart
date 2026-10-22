import 'package:actiphibian/models/mappable.dart';

class Statistics implements IMappable{
  int id;
  late int tasks_completed;
  late int tasks_incompleted;
  late double? hours_focused;
  late int times_distracted;
  late int total_currency_earned;
  late int total_currency_spent;
  late int total_xp_gained;
  late int total_amphibians_collected;
  late int longest_streak;
  late int user_id;

  Statistics({
    required this.id, 
    required this.tasks_completed, 
    required this.tasks_incompleted, 
    required this.hours_focused, 
    required this.times_distracted,
    required this.total_currency_earned,
    required this.total_currency_spent,
    required this.total_xp_gained,
    required this.total_amphibians_collected,
    required this.longest_streak,
    required this.user_id
  });

  // Statistics.newStatistic() {
  //   tasks_completed = 0;
  //   tasks_incompleted = 0;
  //   hours_focused = 0;
  //   times_distracted = 0;
  //   total_currency_earned = 0;
  //   total_currency_spent = 0;
  //   total_xp_gained = 0;
  //   total_amphibians_collected = 0;
  //   longest_streak = 0;
  //   user_id = 0;
  // }
  
  factory Statistics.fromMap(Map<String, Object?> map) {
    return Statistics(
      id: map['id'] as int,
      tasks_completed: map['tasks_completed'] as int,
      tasks_incompleted: map['tasks_incompleted'] as int,
      hours_focused: map['hours_focused'] as double,
      times_distracted: map['times_distracted'] as int,
      total_currency_earned: map['total_currency_earned'] as int,
      total_currency_spent: map['total_currency_spent'] as int,
      total_xp_gained: map['total_xp_gained'] as int,
      total_amphibians_collected: map['total_amphibians_collected'] as int,
      longest_streak: map['longest_streak'] as int,
      user_id: map['user_id'] as int
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      'tasks_completed': tasks_completed, 
      'tasks_incompleted': tasks_incompleted, 
      'hours_focused': hours_focused, 
      'times_distracted': times_distracted,
      'total_currency_earned': total_currency_earned,
      'total_currency_spent': total_currency_spent,
      'total_xp_gained': total_xp_gained,
      'total_amphibians_collected': total_amphibians_collected,
      'longest_streak': longest_streak,
      'user_id': user_id,
    };
  }
}