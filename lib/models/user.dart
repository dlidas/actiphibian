import 'package:actiphibian/models/mappable.dart';

class User implements IMappable {
  int? id;
  late String? username;
  late int level;
  late int xp;
  late int balance;
  late List tasks;
  int coinsSpent = 0;
  int streak = 0;

  User({
    required this.id,
    required this.username,
    required this.level,
    required this.xp,
    required this.balance,
    this.coinsSpent = 0,
  }) {
    tasks = [];
  }

  User.newUser() {
    username = '';
    level = 1;
    xp = 0;
    balance = 0;
    tasks = [];
  }

  factory User.fromMap(Map<String, Object?> map) => User(
    id: map['id'] as int?,
    username: map['username'] as String,
    level: map['level'] as int,
    xp: map['xp'] as int,
    balance: map['balance'] as int,
    coinsSpent: map['coinsSpent'] as int? ?? 0,
  );

  @override
  Map<String, Object?> toMap() {
    return {'username': username, 'level': level, 'xp': xp, 'balance': balance};
  }

  @override
  String toString() {
    int taskCount = tasks.length;
    return 'User{id: $id, username: $username, level: $level, xp: $xp, balance: $balance, tasks: $taskCount}';
  }
}
