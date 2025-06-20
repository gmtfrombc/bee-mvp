// wipe
class CoachConversation {
  final String id;
  final String title;
  final DateTime createdAt;

  CoachConversation({
    required this.id,
    required this.title,
    required this.createdAt,
  });

  factory CoachConversation.fromJson(Map<String, dynamic> json) {
    return CoachConversation(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
