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
  final int likesCount;
  final bool likedByCurrentUser;

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
    this.likesCount = 0,
    this.likedByCurrentUser = false,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    // Parse user
    final userJson = json['user'] as Map<String, dynamic>;
    final user = User(
      id: userJson['id'] as int,
      name: userJson['name'] as String,
      email: '', // Not provided in comment response
      role: '', // Not provided in comment response
      avatar: userJson['avatar'] as String?,
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
      likesCount: json['likesCount'] as int? ?? 0,
      likedByCurrentUser: json['likedByCurrentUser'] as bool? ?? false,
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
      'likesCount': likesCount,
      'likedByCurrentUser': likedByCurrentUser,
    };
  }

  Comment copyWith({
    bool? reportedByCurrentUser,
    int? likesCount,
    bool? likedByCurrentUser,
    List<Comment>? replies,
  }) {
    return Comment(
      id: id,
      content: content,
      createdAt: createdAt,
      validated: validated,
      user: user,
      motwSlug: motwSlug,
      parentCommentId: parentCommentId,
      replies: replies ?? this.replies,
      reportedByCurrentUser: reportedByCurrentUser ?? this.reportedByCurrentUser,
      likesCount: likesCount ?? this.likesCount,
      likedByCurrentUser: likedByCurrentUser ?? this.likedByCurrentUser,
    );
  }
}
