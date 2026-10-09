import 'package:flutter/material.dart';
import 'package:actiphibian/models/task.dart';
import 'package:actiphibian/utils/task_parsers.dart';
import 'package:actiphibian/utils/task_creation_logger.dart';

class NewTasks extends StatefulWidget {
  @override
  _NewTasksState createState() => _NewTasksState();
}

class _NewTasksState extends State<NewTasks> {
  final List<Task> _tasks = [];
  int _nextId = 1; // stand-in identity until SQLite assigns real ids

  String _toStorageDifficulty(String display) => display.toLowerCase();
  String _toDisplayDifficulty(String stored) {
    switch (stored) {
      case 'medium':
        return 'Medium';
      case 'hard':
        return 'Hard';
      default:
        return 'Easy';
    }
  }

  //using dialog methods for CRUD functionality

  // for creating a task
  void _showAddTaskDialog() {
    final descriptionController = TextEditingController();
    final subtaskController = TextEditingController();
    final durationController = TextEditingController();
    final deadlineController = TextEditingController();
    bool recurring = false;
    String difficulty = "Easy";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Add New Task"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(labelText: "Description"),
                    ),
                    TextField(
                      controller: subtaskController,
                      decoration: InputDecoration(
                        labelText: "Subtasks",
                        hintText: "wash dishes, buy milk",
                      ),
                    ),
                    TextField(
                      controller: durationController,
                      decoration: InputDecoration(labelText: "Duration"),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: deadlineController,
                      decoration: InputDecoration(
                        labelText: "Deadline (YYYY-MM-DD)",
                      ),
                    ),
                    SwitchListTile(
                      title: Text("Recurring"),
                      value: recurring,
                      onChanged: (val) {
                        setDialogState(() {
                          recurring = val;
                        });
                      },
                    ),
                    DropdownButton<String>(
                      value: difficulty,
                      items: ["Easy", "Medium", "Hard"]
                          .map(
                            (level) => DropdownMenuItem(value: level, child: Text(level)),
                          )
                          .toList(),
                      onChanged: (val) => setDialogState(() => difficulty = val!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final newTask = Task(
                      id: _nextId++,
                      description: descriptionController.text,
                      subtasks: TaskParsers.parseSubtasks(subtaskController.text),
                      durationMinutes: TaskParsers.parseDuration(durationController.text),
                      deadline: TaskParsers.parseDeadline(deadlineController.text),
                      recurring: recurring,
                      difficulty: _toStorageDifficulty(difficulty),
                    );

                    setState(() {
                      //Create
                      _tasks.add(newTask);
                    });

                    await TaskCreationLogger.logTaskCreated(
                      title: newTask.description,
                      subtasksRaw: subtaskController.text,
                      durationRaw: durationController.text,
                      deadlineRaw: deadlineController.text,
                      isRecurring: recurring,
                      difficulty: difficulty,
                    );
                    print(await TaskCreationLogger.readLog());

                    Navigator.pop(context);
                  },
                  child: Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  //for updating/editing a task
  void _showEditTaskDialog(int index) {
    final task = _tasks[index];
    final descriptionController = TextEditingController(text: task.description);
    final subtaskController = TextEditingController(text: task.subtasks.join(', '));
    final durationController = TextEditingController(
      text: task.durationMinutes?.toString() ?? '',
    );
    final deadlineController = TextEditingController(
      text: TaskParsers.formatDeadline(task.deadline) == 'No deadline'
          ? ''
          : TaskParsers.formatDeadline(task.deadline),
    );
    bool recurring = task.recurring;
    String difficulty = _toDisplayDifficulty(task.difficulty);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Edit Task"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(labelText: "Description"),
                    ),
                    TextField(
                      controller: subtaskController,
                      decoration: InputDecoration(labelText: "Subtasks"),
                    ),
                    TextField(
                      controller: durationController,
                      decoration: InputDecoration(
                        labelText: "Duration (hours)",
                      ),
                    ),
                    TextField(
                      controller: deadlineController,
                      decoration: InputDecoration(
                        labelText: "Deadline (YYYY-MM-DD)",
                      ),
                    ),
                    SwitchListTile(
                      title: Text("Recurring"),
                      value: recurring,
                      onChanged: (val) => setDialogState(() => recurring = val),
                    ),
                    DropdownButton<String>(
                      value: difficulty,
                      items: ["Easy", "Medium", "Hard"]
                          .map(
                            (level) => DropdownMenuItem(
                              value: level,
                              child: Text(level),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setDialogState(() => difficulty = val!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _tasks[index] = task.copyWith(
                        description: descriptionController.text,
                        subtasks: TaskParsers.parseSubtasks(subtaskController.text),
                        durationMinutes: TaskParsers.parseDuration(durationController.text),
                        deadline: TaskParsers.parseDeadline(deadlineController.text),
                        recurring: recurring,
                        difficulty: _toStorageDifficulty(difficulty),
                      );
                    });
                    Navigator.pop(context);
                  },
                  child: Text("Save changes"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    final dueTodayCount = _tasks.where((t) => t.isDueToday).length;

    return Scaffold(
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.all(15),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 30, 92, 33),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.today, color: Colors.white, size: 30),
                SizedBox(width: 10),
                Text(
                  "Today's Tasks ($dueTodayCount)",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return ExpansionTile(
                  title: Text(task.description),
                  subtitle: Text(
                    "Deadline: ${TaskParsers.formatDeadline(task.deadline)}  "
                    "Difficulty: ${_toDisplayDifficulty(task.difficulty)}",
                  ),
                  children: [
                    ListTile(
                      title: Text("Subtasks"),
                      subtitle: Text(
                        task.subtasks.isEmpty ? 'None' : task.subtasks.join(', '),
                      ),
                    ),
                    ListTile(
                      title: Text("Duration"),
                      subtitle: Text(
                        task.durationMinutes != null ? "${task.durationMinutes} min" : 'Not set',
                      ),
                    ),
                    ListTile(
                      title: Text("Recurring"),
                      subtitle: Text(task.recurring ? "Yes" : "No"),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            _showEditTaskDialog(index);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _tasks.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
