import 'package:actiphibian/models/user.dart';
import 'package:flutter/material.dart';
import 'package:actiphibian/services/gacha_economy.dart';

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
    required int streak,
  }) {
    // Balance = lifetime coins - coins spent
    final balance = GachaEconomy.balance(
      totalXp: xp,
      coinsSpent: _user.coinsSpent,
    );
    if (_user.level == level &&
        _user.xp == xp &&
        _user.balance == balance &&
        _user.streak == streak) {
      return;
    }
    _user
      ..level = level
      ..xp = xp
      ..balance = balance
      ..streak = streak;
    notifyListeners();
  }

  /// Return false if user can't affort
  bool spendCoins(int cost) {
    if (_user.balance < cost) return false;
    _user
      ..coinsSpent += cost
      ..balance -= cost;
    notifyListeners();
    return true;
  }
}
