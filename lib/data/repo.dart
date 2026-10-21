//DEPENDENCY FOR SQLITE
//flutter pub add sqflite path

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user.dart';
import '../models/task.dart';
import 'tables.dart';

class LocalDb {
  static Database? _database;

  //Safe getter ensures database is reachable, i.e creates it if it doesn't exist
  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initialiseDb();
    return _database!;
  }

  static Future<Database> _initialiseDb() async {    
    return await openDatabase(
      join(await getDatabasesPath(), 'actiphibian.db'),
      onCreate: (db, version) async {//Uncomment tables as implemented
        await db.execute(Tables.users());
        await db.execute(Tables.tasks());
        // await db.execute(Tables.tags());
        // await db.execute(Tables.collection());
        // await db.execute(Tables.amphibians());
        // await db.execute(Tables.statistics());
        // await db.execute(Tables.dailyStatistics());
        // await db.execute(Tables.weeklyStatistics());
        // await db.execute(Tables.monthlyStatistics());
      },
      version: 1,
    );
  }

  static Future<void> removeDatabase() async {
    await deleteDatabase(join(await getDatabasesPath(), 'actiphibian.db'));
  }

  static Future<void> addUser(User user) async {
    final db = await database;

    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.fail,      
    );
  }

  static Future<User?> getUser(String username) async {
    final db = await database;

    final users = await db.rawQuery('SELECT * FROM users WHERE username = ?', [username]);

    if (users.isEmpty) return null;

    return User.fromMap(users.first);
  }

  static Future<List<User>> getUsers() async {
    final db = await database;

    final List<Map<String, Object?>> userMaps = await db.query('users');

    return userMaps.map(User.fromMap).toList();
  }

  static Future<void> updateUser(User user) async {
    final db = await database;

    await db.update(
      'users', 
      user.toMap(), 
      where: 'id = ?', 
      whereArgs: [user.id],
    );
  }

  static Future<void> deleteUser(int id) async {
    final db = await database;

    await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> addTask(Task task) async {
    final db = await database;

    await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.fail,      
    );
  }

  static Future<Task?> getTask(int id) async {
    final db = await database;

    final records = await db.rawQuery('SELECT * FROM tasks WHERE id = ?', [id]);

    if (records.isEmpty) return null;

    return Task.fromMap(records.first);
  }

  static Future<List<Task>> getTasks() async {
    final db = await database;

    final List<Map<String, Object?>> recordsMaps = await db.query('tasks');

    return recordsMaps.map(Task.fromMap).toList();
  }

  static Future<void> updateTask(Task task) async {
    final db = await database;

    await db.update(
      'tasks', 
      task.toMap(), 
      where: 'id = ?', 
      whereArgs: [task.id],
    );
  }

  static Future<void> deleteTask(int id) async {
    final db = await database;

    await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}