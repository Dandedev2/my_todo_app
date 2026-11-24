class Task {
  String todo;
  DateTime timeStamp;
  bool done;

  Task({
    required this.todo,
    required this.timeStamp,
    required this.done,
  });

  Map<String, dynamic> toMap() {
    return {
      'todo': todo,
      'timeStamp': timeStamp.toIso8601String(),
      'done': done,
    };
  }

  factory Task.fromMap(Map<dynamic, dynamic> task) {
    final rawTimeStamp = task['timeStamp'];
    DateTime parsedTime;
    if (rawTimeStamp is DateTime) {
      parsedTime = rawTimeStamp;
    } else if (rawTimeStamp is String) {
      parsedTime = DateTime.tryParse(rawTimeStamp) ?? DateTime.now();
    } else if (rawTimeStamp is int) {
      parsedTime = DateTime.fromMillisecondsSinceEpoch(rawTimeStamp);
    } else {
      parsedTime = DateTime.now();
    }

    return Task(
      todo: task['todo']?.toString() ?? '',
      timeStamp: parsedTime,
      done: task['done'] == true,
    );
  }
}
