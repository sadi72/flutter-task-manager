class Task {

  String title;

  String date;

  String time;

  bool completed;

  Task({

    required this.title,

    required this.date,

    required this.time,

    this.completed=false,

  });

}