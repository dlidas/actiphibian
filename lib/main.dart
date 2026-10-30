import 'package:actiphibian/data/repo.dart';
import 'package:actiphibian/data/user_manager.dart';
import 'package:actiphibian/models/user.dart';
import 'package:flutter/material.dart';
import 'login.dart';
import 'pages/pages.dart';
import 'package:provider/provider.dart';
import 'services/focus_session_controller.dart';
import 'services/user_progress.dart';
import 'widgets/user_stats_app_bar.dart';

void main() async {
  bool isNewUser = true;

  WidgetsFlutterBinding.ensureInitialized();

  if (await LocalDb.getUser(1) != null) {
    if ((await LocalDb.getUser(1) as User).id != null) {
      isNewUser = false;
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => UserManager(user: User.newUser()),
        ),
        //Keeps a running focus session alive while the user switches tabs
        ChangeNotifierProvider(create: (context) => FocusSessionController()),
      ],
      child: Init(isNewUser: isNewUser),
    ),
  );
}

class Init extends StatelessWidget {
  final bool isNewUser;

  const Init({super.key, required this.isNewUser});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Actiphibian',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFABE472),
          onPrimary: Color(0xFF1D3B00),
          secondary: Color(0xFFE1F9B9),
          onSecondary: Color(0xFF1D3B00),
          tertiary: Color(0xFFEA9814),
          onTertiary: Color(0xFF1D3B00),
          surface: Color(0xFFE6FFFA),
          onSurface: Color(0xFF1D2B16),
          error: Color(0xFFBA1A1A),
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFE6FFFA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFABE472),
          foregroundColor: Color(0xFF1D3B00),
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFFFFFFF),
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE4EBD9)),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1D3B00)),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1D3B00),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
        ),
      ),
      home: isNewUser ? LoginPage() : MainPage(pageIndex: 0),
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MainPage(pageIndex: 0);
  }
}

class MainPage extends StatefulWidget {
  final int pageIndex;

  const MainPage({super.key, required this.pageIndex});

  @override
  State<MainPage> createState() => _MainPageState();
}

//=======================DO NOT TOUCH=============================
class _MainPageState extends State<MainPage> {
  static const _pageTitles = [
    'Home',
    'Tasks',
    'Focus Pond',
    'Collection',
    'Calendar',
    'Profile',
  ];

  int currentPageIndex = 0;

  @override
  void initState() {
    currentPageIndex = widget.pageIndex.clamp(0, _pageTitles.length - 1);
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    //Get users from local db
    final users = await LocalDb.getUsers();
    final tasks = await LocalDb.getTasks();

    //Get user from db (with id)
    User userWithId = users.last;
    final focusSessions = await LocalDb.getFocusSessions();
    final progress = UserProgress.fromTasks(
      tasks,
      now: DateTime.now(),
      coinsSpent: userWithId.coinsSpent,
      focusSessions: focusSessions,
    );
    userWithId
      ..level = progress.level
      ..xp = progress.totalXp
      ..balance = progress.coins
      ..streak = progress.streak;

    if (!mounted) return;

    //Update shared user to include id
    context.read<UserManager>().updateUser(userWithId);
  }

  @override
  Widget build(BuildContext context) {
    // Keep tab chrome here so page widgets only provide their content.
    return Scaffold(
      appBar: UserStatsAppBar(title: _pageTitles[currentPageIndex]),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Color(0xFF1D3B00));
            }
            return IconThemeData(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            return TextStyle(
              color: states.contains(WidgetState.selected)
                  ? const Color(0xFF1D3B00)
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
            );
          }),
        ),
        child: NavigationBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          onDestinationSelected: (int index) {
            setState(() {
              currentPageIndex = index;
            });
          },
          indicatorColor: Theme.of(context).colorScheme.secondary,
          selectedIndex: currentPageIndex,
          destinations: const <Widget>[
            //HOME
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            //TASKS
            NavigationDestination(
              icon: Icon(Icons.check_circle_outlined),
              selectedIcon: Icon(Icons.check_circle),
              label: 'Tasks',
            ),
            //FOCUS
            NavigationDestination(
              icon: Icon(Icons.timer_outlined),
              selectedIcon: Icon(Icons.timer),
              label: 'Focus',
            ),
            //COLLECTION
            NavigationDestination(
              icon: Icon(Icons.pie_chart_outline),
              selectedIcon: Icon(Icons.pie_chart),
              label: 'Collection',
            ),
            //CALENDAR
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Calendar',
            ),
            //PROFILE
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
      body: <Widget>[
        //HOME
        HomePage(
          onOpenTasks: () => setState(() => currentPageIndex = 1),
          onOpenFocus: () => setState(() => currentPageIndex = 2),
        ),
        //TASKS
        TaskPage(),
        //FOCUS
        FocusPage(),
        //COLLECTION
        CollectionPage(),
        //CALENDAR
        CalendarPage(),
        //PROFILE
        ProfilePage(),
      ][currentPageIndex],
    );
  }
}
