class UserModel {
  final String id;
  final String name;
  final String job;
  final int age;
  final String focusArea;

  UserModel({
    required this.id,
    required this.name,
    required this.job,
    required this.age,
    required this.focusArea,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      job: json['job'] as String,
      age: json['age'] as int,
      focusArea: json['focusArea'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'job': job,
        'age': age,
        'focusArea': focusArea,
      };
}
