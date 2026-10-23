import 'package:actiphibian/models/user.dart';
import 'package:flutter/material.dart';

//UserManager manages the SharedData for the User, allowing User to be
//accessible from any page
class UserManager extends ChangeNotifier {
  User _user;

  UserManager({required this._user});

  User get user => _user;

  void updateUser(User user) {
    _user = user;
    notifyListeners();
  }

  void updateProgress({
    required int level,
    required int xp,
    required int balance,
  }) {
    if (_user.level == level && _user.xp == xp && _user.balance == balance) {
      return;
    }
    _user
      ..level = level
      ..xp = xp
      ..balance = balance;
    notifyListeners();
  }
}
