class Reminder {

  final int id;
  final String title;
  final String description;
  final DateTime reminderDate;
  bool isCompleted;

  Reminder({
    required this.id,
    required this.title,
    required this.description,
    required this.reminderDate,
    this.isCompleted = false,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      reminderDate: DateTime.parse(json['reminderDate']).toLocal(),
      isCompleted: json['isCompleted'],
    );
  }
}