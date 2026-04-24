class TaskSelection {
  final int id;
  final String userId;
  final int dailyTaskId;
  final DateTime selectedAt;
  final DateTime? completedAt;
  final String status;

  TaskSelection({
    required this.id,
    required this.userId,
    required this.dailyTaskId,
    required this.selectedAt,
    this.completedAt,
    required this.status,
  });

  factory TaskSelection.fromJson(Map<String, dynamic> json) {
    return TaskSelection(
      id: json['id'] as int,
      userId: json['userId'] as String,
      dailyTaskId: json['dailyTaskId'] as int,
      selectedAt: DateTime.parse(json['selectedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      status: json['status'] as String,
    );
  }
}
