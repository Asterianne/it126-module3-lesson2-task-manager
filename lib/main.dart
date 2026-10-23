import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'activity_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

// DATABASE AND REPOSITORY

class TaskRepository {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;

    final dbPath = await getDatabasesPath();
    final fullPath = p.join(dbPath, 'tasks.db');

    _db = await openDatabase(
      fullPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            is_completed INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );

    return _db!;
  }

  Future<int> create(String title) async {
    final db = await database;
    return db.insert('tasks', {'title': title});
  }

  Future<List<Map<String, Object?>>> getAll() async {
    final db = await database;
    return db.query('tasks', orderBy: 'id DESC');
  }

  Future<int> markCompleted(int id, bool completed) async {
    final db = await database;
    return db.update(
      'tasks',
      {'is_completed': completed ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(int id) async {
    final db = await database;
    return db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

// APPLICATION

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IT 126 Task Manager',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xff3d4d97),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IT 126 - Module 3 Lesson 2'),
        backgroundColor: const Color(0xff3d4d97),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.task_alt, size: 70),
            const SizedBox(height: 16),
            const Text(
              'Local Task Manager',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Choose an activity to open.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ActivityScreen(),
                    ),
                  );
                },
                child: const Text('Open In-Memory Activity'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TaskManagerScreen(),
                    ),
                  );
                },
                child: const Text('Open SQLite Task Manager'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// SQLITE TASK MANAGER SCREEN

class TaskManagerScreen extends StatefulWidget {
  const TaskManagerScreen({super.key});

  @override
  State<TaskManagerScreen> createState() => _TaskManagerScreenState();
}

class _TaskManagerScreenState extends State<TaskManagerScreen> {
  final TaskRepository repository = TaskRepository();
  final TextEditingController controller = TextEditingController();

  List<Map<String, Object?>> tasks = [];
  bool loading = true;
  bool busy = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> loadTasks() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final result = await repository.getAll();

      if (!mounted) return;

      setState(() {
        tasks = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = 'Could not load tasks: $e';
      });
    }
  }

  Future<void> addTask() async {
    final title = controller.text.trim();

    if (title.isEmpty) {
      showMessage('Please enter a task title.');
      return;
    }

    if (busy) return;

    setState(() => busy = true);

    try {
      await repository.create(title);

      if (!mounted) return;

      controller.clear();
      await loadTasks();
      showMessage('Task saved successfully.');
    } catch (e) {
      showMessage('Could not save the task: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> toggleTask(
    int id,
    bool completed,
  ) async {
    try {
      await repository.markCompleted(id, completed);
      await loadTasks();
      showMessage(
        completed ? 'Task marked as completed.' : 'Task marked as pending.',
      );
    } catch (e) {
      showMessage('Could not update the task: $e');
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      await repository.delete(id);
      await loadTasks();
      showMessage('Task deleted successfully.');
    } catch (e) {
      showMessage('Could not delete the task: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SQLite Task Manager'),
        backgroundColor: const Color(0xff3d4d97),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'My Tasks',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Enter a task title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit_note),
              ),
              onSubmitted: (_) => addTask(),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: busy ? null : addTask,
                icon: const Icon(Icons.add),
                label: const Text('Add Task'),
              ),
            ),
            const SizedBox(height: 16),
            if (loading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (errorMessage != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(errorMessage!),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: loadTasks,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              )
            else if (tasks.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No saved tasks yet.'),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final id = task['id'] as int;
                    final title = task['title'] as String;
                    final completed = (task['is_completed'] as int) == 1;

                    return Card(
                      child: ListTile(
                        leading: Checkbox(
                          value: completed,
                          onChanged: (value) {
                            toggleTask(id, value ?? false);
                          },
                        ),
                        title: Text(
                          title,
                          style: TextStyle(
                            decoration: completed
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        subtitle: Text(
                          completed ? 'Completed' : 'Pending',
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => deleteTask(id),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
