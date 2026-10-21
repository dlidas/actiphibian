import 'package:actiphibian/models/user.dart';
import 'package:flutter/material.dart';

class UserManager extends ChangeNotifier {
  User _user;

  UserManager({required this._user});

  User get user => _user;

  void updateUser(User user) {
    _user = user;
    notifyListeners();
  }
}