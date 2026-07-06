import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final taskController = TextEditingController();
  final searchController = TextEditingController();
  
  String selectedDateText = "No Date";
  String selectedTimeText = "No Time";
  DateTime? _pickedDate;
  TimeOfDay? _pickedTime;
  
  String search = "";
  List<Map<String, dynamic>> tasks = [];

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList("saved", tasks.map((e) => jsonEncode(e)).toList());
  }

  Future loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? data = prefs.getStringList("saved");
    if (data != null) {
      setState(() {
        tasks = data.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
      });
    }
  }

  Future pickDate() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() {
        _pickedDate = date;
        selectedDateText = "${date.day}/${date.month}/${date.year}";
      });
    }
  }

  Future pickTime() async {
    TimeOfDay? time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time != null) {
      setState(() {
        _pickedTime = time;
        selectedTimeText = time.format(context);
      });
    }
  }

  void addTask() {
    if (taskController.text.trim().isNotEmpty) {
      final taskTitle = taskController.text;
      final int id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      bool hasAlarm = false;
      if (_pickedDate != null && _pickedTime != null) {
        final scheduledDateTime = DateTime(
          _pickedDate!.year,
          _pickedDate!.month,
          _pickedDate!.day,
          _pickedTime!.hour,
          _pickedTime!.minute,
        );

        if (scheduledDateTime.isAfter(DateTime.now())) {
          NotificationService.scheduleNotification(id, taskTitle, scheduledDateTime);
          hasAlarm = true;
        }
      }

      setState(() {
        tasks.add({
          "id": id,
          "title": taskTitle,
          "date": selectedDateText,
          "time": selectedTimeText,
          "done": false,
          "hasAlarm": hasAlarm,
        });
      });

      if (hasAlarm) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Alarm set for this task!")),
        );
      } else {
        NotificationService.show(taskTitle);
      }

      saveTasks();
      taskController.clear();
      setState(() {
        selectedDateText = "No Date";
        selectedTimeText = "No Time";
        _pickedDate = null;
        _pickedTime = null;
      });
      FocusScope.of(context).unfocus();
    }
  }

  void deleteTask(int index) {
    final task = tasks[index];
    if (task['id'] != null) {
      NotificationService.cancelNotification(task['id']);
    }
    setState(() {
      tasks.removeAt(index);
    });
    saveTasks();
  }

  void logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = tasks.where((t) => t["title"].toLowerCase().contains(search.toLowerCase())).toList();
    double progress = tasks.isEmpty ? 0 : tasks.where((e) => e["done"]).length / tasks.length;

    return Scaffold(
      backgroundColor: const Color(0xffFFF6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xffFF69B4),
        foregroundColor: Colors.white,
        title: const Text("Smart Task Manager"),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage())),
            icon: const Icon(Icons.person),
          ),
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Dashboard
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xffFF8CC8), Color(0xffFF69B4)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.3), blurRadius: 15)],
            ),
            child: Column(
              children: [
                const Text("Dashboard", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _stat("Total", tasks.length),
                    _stat("Done", tasks.where((e) => e["done"]).length),
                    _stat("Pending", tasks.where((e) => !e["done"]).length),
                  ],
                ),
                const SizedBox(height: 15),
                LinearProgressIndicator(value: progress, backgroundColor: Colors.white30, color: Colors.white),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Search
          TextField(
            controller: searchController,
            onChanged: (v) => setState(() => search = v),
            decoration: InputDecoration(
              hintText: "Search Tasks...",
              prefixIcon: const Icon(Icons.search, color: Color(0xffFF69B4)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 15),
          // Input Section
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
            child: Column(
              children: [
                TextField(
                  controller: taskController,
                  decoration: const InputDecoration(hintText: "Task Name", border: InputBorder.none),
                ),
                const Divider(),
                Row(
                  children: [
                    Expanded(child: TextButton.icon(onPressed: pickDate, icon: const Icon(Icons.event), label: Text(selectedDateText, overflow: TextOverflow.ellipsis))),
                    Expanded(child: TextButton.icon(onPressed: pickTime, icon: const Icon(Icons.timer), label: Text(selectedTimeText, overflow: TextOverflow.ellipsis))),
                  ],
                ),
                ElevatedButton(
                  onPressed: addTask,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffFF69B4), foregroundColor: Colors.white),
                  child: const Text("ADD TASK"),
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Task List
          ...filtered.map((task) {
            int originalIdx = tasks.indexOf(task);
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Checkbox(
                  value: task["done"],
                  onChanged: (v) {
                    setState(() => task["done"] = v);
                    saveTasks();
                  },
                ),
                title: Text(task["title"], style: TextStyle(decoration: task["done"] ? TextDecoration.lineThrough : null)),
                subtitle: Row(
                  children: [
                    Text("${task["date"]} | ${task["time"]}"),
                    if (task["hasAlarm"] == true) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.alarm, size: 14, color: Color(0xffFF69B4)),
                    ]
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => deleteTask(originalIdx),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _stat(String label, int val) => Column(children: [
    Text("$val", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
    Text(label, style: const TextStyle(color: Colors.white70)),
  ]);
}
