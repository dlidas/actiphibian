import 'package:actiphibian/models/mappable.dart';

class Statistics implements IMappable{
  int id;
  late int tasksCompleted;
  late int tasksincompleted;
  late double? hoursfocused;
  late int timesdistracted;
  late int totalcurrencyearned;
  late int totalcurrencyspent;
  late int totalxpgained;
  late int totalamphibianscollected;
  late int longeststreak;
  late int userid;

  Statistics({
    required this.id, 
    required this.tasksCompleted, 
    required this.tasksincompleted, 
    required this.hoursfocused, 
    required this.timesdistracted,
    required this.totalcurrencyearned,
    required this.totalcurrencyspent,
    required this.totalxpgained,
    required this.totalamphibianscollected,
    required this.longeststreak,
    required this.userid
  });
  
  factory Statistics.fromMap(Map<String, Object?> map) {
    return Statistics(
      id: map['id'] as int,
      tasksCompleted: map['tasks_completed'] as int,
      tasksincompleted: map['tasksincompleted'] as int,
      hoursfocused: map['hoursfocused'] as double,
      timesdistracted: map['timesdistracted'] as int,
      totalcurrencyearned: map['totalcurrencyearned'] as int,
      totalcurrencyspent: map['totalcurrencyspent'] as int,
      totalxpgained: map['totalxpgained'] as int,
      totalamphibianscollected: map['totalamphibianscollected'] as int,
      longeststreak: map['longeststreak'] as int,
      userid: map['userid'] as int
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      'tasks_completed': tasksCompleted, 
      'tasksincompleted': tasksincompleted, 
      'hoursfocused': hoursfocused, 
      'timesdistracted': timesdistracted,
      'totalcurrencyearned': totalcurrencyearned,
      'totalcurrencyspent': totalcurrencyspent,
      'totalxpgained': totalxpgained,
      'totalamphibianscollected': totalamphibianscollected,
      'longeststreak': longeststreak,
      'userid': userid,
    };
  }
}