class GoalEntity {
  const GoalEntity({
    required this.id,
    required this.title,
    required this.active,
  });

  final String id;
  final String title;
  final bool active;

  factory GoalEntity.fromJson(Map<String, dynamic> json) {
    return GoalEntity(
      id: json['id'] as String,
      title: json['title'] as String,
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'active': active,
      };
}
