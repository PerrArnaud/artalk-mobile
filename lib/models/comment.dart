import 'user.dart';

class Comment {
  final int id;
  final String content;
  final DateTime createdAt;
  final bool validated;
  final User user;
  final String? motwSlug;
  final int? parentCommentId;
  final List<Comment> replies;
  final bool reportedByCurrentUser;

  Comment({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.validated,
    required this.user,
    this.motwSlug,
    this.parentCommentId,
    this.replies = const [],
    this.reportedByCurrentUser = false,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    // Parse user
    final userJson = json['user'] as Map<String, dynamic>;
    final user = User(
      id: userJson['id'] as int,
      name: userJson['name'] as String,
      email: '', // Not provided in comment response
      role: '', // Not provided in comment response
    );

    // Parse replies if present
    List<Comment> replies = [];
    if (json['replies'] != null) {
      replies = (json['replies'] as List)
          .map((reply) => Comment.fromJson(reply as Map<String, dynamic>))
          .toList();
    }

    return Comment(
      id: json['id'] as int,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      validated: json['validated'] as bool? ?? true,
      user: user,
      motwSlug: json['motwSlug'] as String?,
      parentCommentId: json['parentCommentId'] as int?,
      replies: replies,
      reportedByCurrentUser: json['reportedByCurrentUser'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'validated': validated,
      'user': user.toJson(),
      'motwSlug': motwSlug,
      'parentCommentId': parentCommentId,
      'replies': replies.map((r) => r.toJson()).toList(),
      'reportedByCurrentUser': reportedByCurrentUser,
    };
  }

  Comment copyWith({bool? reportedByCurrentUser}) {
    return Comment(
      id: id,
      content: content,
      createdAt: createdAt,
      validated: validated,
      user: user,
      motwSlug: motwSlug,
      parentCommentId: parentCommentId,
      replies: replies,
      reportedByCurrentUser: reportedByCurrentUser ?? this.reportedByCurrentUser,
    );
  }
}
