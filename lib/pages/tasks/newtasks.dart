import 'package:flutter/material.dart';
import 'package:actiphibian/models/task.dart';

class NewTasks extends StatefulWidget {
  @override
  _NewTasksState createState() => _NewTasksState();
}

class _NewTasksState extends State<NewTasks> {
  final List<Task> _tasks = [];

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
                  decoration: InputDecoration(labelText: "Subtasks"),
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
                    setState(() {
                      recurring = val;
                    });
                  },
                ),
                DropdownButton<String>(
                  value: difficulty,
                  items: ["Easy", "Medium", "Hard"]
                      .map(
                        (level) =>
                            DropdownMenuItem(value: level, child: Text(level)),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => difficulty = val!),
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
                  //Create
                  _tasks.add(
                    Task(
                      description: descriptionController.text,
                      subtasks: subtaskController.text,
                      duration: durationController.text,
                      deadline: deadlineController.text,
                      recurring: recurring,
                      difficulty: difficulty,
                    ),
                  );
                });
                Navigator.pop(context);
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  //for updating/editing a task
  void _showEditTaskDialog(int index) {
    final task = _tasks[index];
    final descriptionController = TextEditingController(text: task.description);
    final subtaskController = TextEditingController(text: task.subtasks);
    final durationController = TextEditingController(text: task.duration);
    final deadlineController = TextEditingController(text: task.deadline);
    bool recurring = task.recurring;
    String difficulty = task.difficulty;

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
                      onChanged: (val) =>
                          setDialogState(() => difficulty = val!),
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
                      _tasks[index] = Task(
                        description: descriptionController.text,
                        subtasks: subtaskController.text,
                        duration: durationController.text,
                        deadline: deadlineController.text,
                        recurring: recurring,
                        difficulty: difficulty,
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
                  "Today's Tasks (${_tasks.length})",
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
                    "Deadline: ${task.deadline}  Difficulty: ${task.difficulty}",
                  ),
                  children: [
                    ListTile(
                      title: Text("Subtasks"),
                      subtitle: Text(task.subtasks),
                    ),
                    ListTile(
                      title: Text("Duration"),
                      subtitle: Text("${task.duration} hours"),
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
