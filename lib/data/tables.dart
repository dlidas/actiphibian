class Tables {
  static String users() =>
      'CREATE TABLE users('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'username TEXT UNIQUE, '
      'level INTEGER, '
      'xp INTEGER, '
      'balance INTEGER'
      ');';

  // Habits are stored independently so tasks can refer to a habit by ID.
  static String habits() =>
      'CREATE TABLE IF NOT EXISTS habits('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'name TEXT NOT NULL, '
      'totalXp INTEGER NOT NULL DEFAULT 0, '
      'currentStreak INTEGER NOT NULL DEFAULT 0, '
      'createdAt TEXT NOT NULL'
      ');';

  // Keep these column names in sync with Task.toMap()/Task.fromMap().
  static String tasks() =>
      'CREATE TABLE tasks('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'description TEXT NOT NULL, '
      'subtasks TEXT NOT NULL DEFAULT \'[]\', '
      'durationMinutes INTEGER, '
      'deadline TEXT, '
      'recurring INTEGER NOT NULL DEFAULT 0, '
      'recurrenceFrequency TEXT, '
      'difficulty TEXT NOT NULL, '
      'perceivedDifficulty TEXT, '
      'status TEXT NOT NULL DEFAULT \'active\', '
      'xpAwarded INTEGER NOT NULL DEFAULT 0, '
      'completedAt TEXT, '
      'habitId INTEGER, '
      'recurringSeriesId TEXT, '
      'remoteId TEXT, '
      'isSynced INTEGER NOT NULL DEFAULT 0, '
      'createdAt TEXT NOT NULL, '
      'updatedAt TEXT NOT NULL'
      ');';

  static String focusSessions() =>
      'CREATE TABLE IF NOT EXISTS focus_sessions('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'methodId TEXT NOT NULL, '
      'startedAt TEXT NOT NULL, '
      'focusedMinutes INTEGER NOT NULL, '
      'xpAwarded INTEGER NOT NULL DEFAULT 0'
      ');';

  // Fix the trailing comma in the previous tags schema so a new DB can open.
  static String tags() =>
      'CREATE TABLE tags('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'user_id INTEGER'
      ');';

  static String collection() =>
      'CREATE TABLE collection('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'user_id INTEGER, '
      'amphibian_count INTEGER'
      ');';

  static String amphibians() =>
      'CREATE TABLE amphibians('
        'id INTEGER PRIMARY KEY, '
        'name TEXT, '
        'species TEXT, '
        'description TEXT, '
        'rarity TEXT, '
        'file_path TEXT'
      ');';

  static String statistics() =>
      'CREATE TABLE statistics('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'tasks_completed INTEGER, '
      'tasks_incomlete INTEGER, '
      'hours_focused REAL, '
      'times_distracted INTEGER, '
      'total_currency_earned INTEGER, '
      'total_currency_spent INTEGER, '
      'total_xp_gained INTEGER, '
      'total_amphibians_collected INTEGER, '
      'longest_streak INTEGER, '
      'user_id INTEGER'
      ');';

  static String monthlyStatistics() =>
      'CREATE TABLE monthly_statistics('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'statistics_id INTEGER, '
      'tasks_completed INTEGER, '
      'tasks_incomlete INTEGER, '
      'hours_focused REAL, '
      'times_distracted INTEGER, '
      'currency_earned INTEGER, '
      'currency_spent INTEGER, '
      'xp_gained INTEGER, '
      'amphibians_collected INTEGER, '
      'streak INTEGER'
      ');';

  static String weeklyStatistics() =>
      'CREATE TABLE weekly_statistics('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'statistics_id INTEGER, '
      'tasks_completed INTEGER, '
      'tasks_incomlete INTEGER, '
      'hours_focused REAL, '
      'times_distracted INTEGER, '
      'currency_earned INTEGER, '
      'currency_spent INTEGER, '
      'xp_gained INTEGER, '
      'amphibians_collected INTEGER, '
      'streak INTEGER'
      ');';

  static String dailyStatistics() =>
      'CREATE TABLE daily_statistics('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'statistics_id INTEGER, '
      'tasks_completed INTEGER, '
      'tasks_incomlete INTEGER, '
      'hours_focused REAL, '
      'times_distracted INTEGER, '
      'currency_earned INTEGER, '
      'currency_spent INTEGER, '
      'xp_gained INTEGER, '
      'amphibians_collected INTEGER, '
      'streak INTEGER'
      ');';
}
