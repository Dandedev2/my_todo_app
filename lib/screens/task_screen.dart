import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  late Future<Box> _openBoxFuture;

  @override
  void initState() {
    super.initState();
    _openBoxFuture = Hive.isBoxOpen('tasks')
        ? Future.value(Hive.box('tasks'))
        : Hive.openBox('tasks');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Planner"),
        centerTitle: true,
      ),
      body: _tasksWidget(),
      floatingActionButton: FloatingActionButton(
        onPressed: _displayTaskPopup,
        tooltip: "Add Task",
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _tasksWidget() {
    return FutureBuilder<Box>(
      future: _openBoxFuture,
      builder: (BuildContext context, AsyncSnapshot<Box> snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          final box = snapshot.data!;
          return ValueListenableBuilder<Box>(
            valueListenable: box.listenable(),
            builder: (context, Box currentBox, _) {
              return _todoList(currentBox);
            },
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text("Error loading tasks: ${snapshot.error}"),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _todoList(Box box) {
    final List tasks = box.values.toList();

    if (tasks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checklist_rtl_rounded,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              "No tasks yet!",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Tap the + button to add a new task",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: tasks.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final task = Task.fromMap(tasks[index]);
        final formattedDate =
            "${task.timeStamp.year}-${task.timeStamp.month.toString().padLeft(2, '0')}-${task.timeStamp.day.toString().padLeft(2, '0')} "
            "${task.timeStamp.hour.toString().padLeft(2, '0')}:${task.timeStamp.minute.toString().padLeft(2, '0')}";

        return Dismissible(
          key: ValueKey("${task.timeStamp.millisecondsSinceEpoch}_$index"),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) {
            box.deleteAt(index);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Task "${task.todo}" deleted'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: ListTile(
            leading: IconButton(
              icon: Icon(
                task.done ? Icons.check_circle : Icons.radio_button_unchecked,
                color: task.done ? Colors.green : Colors.grey,
              ),
              onPressed: () {
                task.done = !task.done;
                box.putAt(index, task.toMap());
              },
            ),
            title: Text(
              task.todo,
              style: TextStyle(
                decoration: task.done ? TextDecoration.lineThrough : null,
                color: task.done ? Colors.grey : null,
              ),
            ),
            subtitle: Text(formattedDate),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () {
                _confirmDelete(context, box, index, task.todo);
              },
            ),
            onTap: () {
              task.done = !task.done;
              box.putAt(index, task.toMap());
            },
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, Box box, int index, String taskTitle) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Delete Task"),
          content: Text('Are you sure you want to delete "$taskTitle"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                box.deleteAt(index);
                Navigator.pop(dialogContext);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _displayTaskPopup() {
    final TextEditingController textController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Add a ToDo"),
          content: TextField(
            controller: textController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: "Enter task name...",
            ),
            onSubmitted: (value) {
              _addTask(dialogContext, textController.text);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () {
                _addTask(dialogContext, textController.text);
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void _addTask(BuildContext dialogContext, String rawText) {
    final text = rawText.trim();
    if (text.isEmpty) return;

    final box = Hive.box('tasks');
    final task = Task(
      todo: text,
      timeStamp: DateTime.now(),
      done: false,
    );
    box.add(task.toMap());
    Navigator.pop(dialogContext);
  }
}
