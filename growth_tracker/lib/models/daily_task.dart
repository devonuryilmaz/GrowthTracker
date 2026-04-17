class DailyTask {
  final int id;
  final String title;
  final String description;
  final String category;
  final int estimatedMinutes;
  bool isSelected;
  bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;

  DailyTask({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.estimatedMinutes,
    this.isSelected = false,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
  });

  factory DailyTask.fromJson(Map<String, dynamic> json) {
    return DailyTask(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String? ?? '',
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 0,
      isSelected: json['isSelected'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }
}

class TaskSuggestion {
  final String title;
  final String description;
  final String category;
  final int estimatedMinutes;

  TaskSuggestion({
    required this.title,
    required this.description,
    required this.category,
    required this.estimatedMinutes,
  });

  factory TaskSuggestion.fromJson(Map<String, dynamic> json) {
    return TaskSuggestion(
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      estimatedMinutes: json['estimatedMinutes'] as int,
    );
  }
}
