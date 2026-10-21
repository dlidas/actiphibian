import 'package:actiphibian/data/repo.dart';
import 'package:actiphibian/data/userManager.dart';
import 'package:actiphibian/models/user.dart';
import 'package:flutter/material.dart';
// import 'package:path/path.dart';
import 'login.dart';
import 'pages/pages.dart';
import 'package:provider/provider.dart';

void main() async {
  bool isNewUser= true;
  
  WidgetsFlutterBinding.ensureInitialized();

  //FOR DEBUGGING: RESETS DATABASE - BE CAREFUL
  // LocalDb.removeDatabase(); //!

  print('--------------------------------------------');
  print((await LocalDb.getUsers()).toString());

  if (await LocalDb.getUser(1) != null) {
    if ((await LocalDb.getUser(1) as User).id != null) {
      isNewUser = false;
    }    
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => UserManager(user: User.newUser()),
      child: Init(isNewUser: isNewUser),
    )
  );
}

class Init extends StatelessWidget {
  final bool isNewUser;
  const Init({super.key, required this.isNewUser});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme(
          error: Colors.red,
          onError: Colors.white,
          brightness: Brightness.light,
        ),
        iconTheme: IconThemeData(
          color: Color(0xFF1D3B00),
        ),
      ),
      // debugShowCheckedModeBanner: false,
      home: isNewUser ? LoginPage() : MainPage(),
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MainPage();
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

//=======================DO NOT TOUCH=============================
class _MainPageState extends State<MainPage> {
  int currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();    
  }

  Future<void> _loadUser() async {
    //Get users from local db
    List<User> users = await LocalDb.getUsers();

    //Get user from db (with id)
    User userWithId = users.last;

    if (!mounted) return;

    //Update shared user to include id
    // Provider.of<UserManager>(context, listen: false).updateUser(userWithId);
    context.read<UserManager>().updateUser(userWithId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        //CURRENCY
        leading: Center(
          child: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.onSecondary, 
            foregroundColor: Theme.of(context).colorScheme.secondary,
            child: Text('0'),
          ),
        ), //TODO: Link to data
        //LEVEL
        title: Center(
          child: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.secondary, 
            foregroundColor: Theme.of(context).colorScheme.onSecondary,
            child: Text('1'),
          ),
        ), //TODO: Add
        actions: <Widget>[
          //SETTINGS
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              //TODO: Implement
            },
          ),
        ],
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(color: Colors.red);
            }
              return IconThemeData(color: Theme.of(context).iconTheme.color);
          })
        ), 
        child: NavigationBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          onDestinationSelected: (int index) {
            setState(() {
              currentPageIndex = index;
            });
          },
          indicatorColor: Theme.of(context).colorScheme.tertiary,
          selectedIndex: currentPageIndex,
          destinations: const <Widget>[
            //HOME
            NavigationDestination(
              icon: Icon(Icons.home_outlined), 
              selectedIcon: Icon(Icons.home),
              label: 'Home'
            ),
            //TASKS
            NavigationDestination(
              icon: Icon(Icons.check_circle_outlined), 
              selectedIcon: Icon(Icons.check_circle),
              label: 'Tasks'
            ),
            //FOCUS
            NavigationDestination(
              icon: Icon(Icons.timer_outlined), 
              selectedIcon: Icon(Icons.timer),
              label: 'Focus'
            ),
            //COLLECTION
            NavigationDestination(
              icon: Icon(Icons.pie_chart_outline), 
              selectedIcon: Icon(Icons.pie_chart),
              label: 'Collection'
            ),
            //CALENDAR
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined), 
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Calendar'
            ),
            //PROFILE
            NavigationDestination(
              icon: Icon(Icons.person_outline), 
              selectedIcon: Icon(Icons.person),
              label: 'Profile'
            ),
          ],
        ),
      ),
      body: <Widget>[
        //HOME
        HomePage(),
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

