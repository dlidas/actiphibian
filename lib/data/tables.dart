class Tables {  
  //users table
  static String users() {
    String usersTableQuery = 
      'CREATE TABLE users('
        'id INTEGER PRIMARY KEY, ' 
        'username TEXT UNIQUE, '
        'level INTEGER, ' 
        'xp INTEGER, ' 
        'balance INTEGER'
      ');';
    return usersTableQuery;
  }

  //tasks table
  static String tasks() {
    String tasksTableQuery = 
      'CREATE TABLE tasks('
        'id INTEGER PRIMARY KEY, '
        'parentId INTEGER, '
        'description TEXT, '
        'subtasks TEXT, '
        'durationMinutes INT, '
        'deadline TEXT, ' 
        'recurring BOOLEAN, '
        'difficulty TEXT, '
        'status TEXT, '
        'xpAwarded INT, '
        'completedAt TEXT, '
        'habitId INTEGER, '
        'remoteId INTEGER, '
        'isSynced BOOLEAN, '
        // 'createdAt TEXT DEFAULT (datetime("now")), '
        'createdAt TEXT, '
        'updatedAt TEXT'
      ');'; 
    return tasksTableQuery;
  } 

  //tags table
  static String tags() {
    String tagsQuery =
      'CREATE TABLE tags('
        'id INTEGER PRIMARY KEY, '
        'user_id INTEGER, '
      ');';
    return tagsQuery;
  }

  //collection table
  static String collection() {
    String collectionQuery =
      'CREATE TABLE collection('
        'id INTEGER PRIMARY KEY, '
        'user_id INTEGER, '
        'amphibian_count INTEGER, '
      ');';
    return collectionQuery;
  }

  //amphibian table
  static String amphibians() {
    String amphibiansQuery =
      'CREATE TABLE amphibians('
        'id INTEGER PRIMARY KEY, '
        'name TEXT, '
        'species TEXT, '
        'description TEXT, '
        'rarity TEXT, '
      ');';
    return amphibiansQuery;
  }

  //statistics tables
  static String statistics() {
    String statisticsTableQuery = 
      'CREATE TABLE statistics('
        'id INTEGER PRIMARY KEY, '
        'tasks_completed INTEGER, '
        'tasks_incomlete INTEGER, '
        'hours_focused REAL, '
        'times_distracted INTEGER, '
        'total_currency_earned INTEGER, '
        'total_currency_spent INTEGER, '
        'total_xp_gained INTEGER, '
        'total_amphibians_collected INTEGER, '
        'longest_streak INTEGER, '
        'user_id INTEGER, '
      ');';
    return statisticsTableQuery;
  }
      
  static String monthlyStatistics() {
    String monthlyStatisticsTableQuery = 
      'CREATE TABLE monthly_statistics('
        'id INTEGER PRIMARY KEY, '
        'statistics_id INTEGER, '
        'tasks_completed INTEGER, '
        'tasks_incomlete INTEGER, '
        'hours_focused REAL, '
        'times_distracted INTEGER, '
        'currency_earned INTEGER, '
        'currency_spent INTEGER, '
        'xp_gained INTEGER, '
        'amphibians_collected INTEGER, '
        'streak INTEGER, '
      ');';   
    return monthlyStatisticsTableQuery;
  }
     
  static String weeklyStatistics() {
    String weeklyStatisticsTableQuery = 
      'CREATE TABLE weekly_statistics('
        'id INTEGER PRIMARY KEY, '
        'statistics_id INTEGER, '
        'tasks_completed INTEGER, '
        'tasks_incomlete INTEGER, '
        'hours_focused REAL, '
        'times_distracted INTEGER, '
        'currency_earned INTEGER, '
        'currency_spent INTEGER, '
        'xp_gained INTEGER, '
        'amphibians_collected INTEGER, '
        'streak INTEGER, '
      ');'; 
    return weeklyStatisticsTableQuery;
  }
    
  static String dailyStatistics() {
    String dailyStatisticsTableQuery = 
      'CREATE TABLE daily_statistics('
        'id INTEGER PRIMARY KEY, '
        'statistics_id INTEGER, '
        'tasks_completed INTEGER, '
        'tasks_incomlete INTEGER, '
        'hours_focused REAL, '
        'times_distracted INTEGER, '
        'currency_earned INTEGER, '
        'currency_spent INTEGER, '
        'xp_gained INTEGER, '
        'amphibians_collected INTEGER, '
        'streak INTEGER, '
      ');'; 
    return dailyStatisticsTableQuery;
  }
    
}