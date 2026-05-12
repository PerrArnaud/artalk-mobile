import 'art_type.dart';

class MOTW {
  final int id;
  final String name;
  final String artist;
  final DateTime date;
  final DateTime datePost;
  final String slug;
  final String? visual;
  final int commentCount;
  final ArtType? artType;

  MOTW({
    required this.id,
    required this.name,
    required this.artist,
    required this.date,
    required this.datePost,
    required this.slug,
    this.visual,
    required this.commentCount,
    this.artType,
  });

  factory MOTW.fromJson(Map<String, dynamic> json) {
    return MOTW(
      id: json['id'] as int,
      name: json['name'] as String,
      artist: json['artist'] as String,
      date: DateTime.parse(json['date'] as String),
      datePost: DateTime.parse(json['datePost'] as String),
      slug: json['slug'] as String,
      visual: json['visual'] as String?,
      commentCount: json['commentCount'] as int? ?? 0,
      artType: json['artType'] != null
          ? ArtType.fromJson(json['artType'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'artist': artist,
      'date': date.toIso8601String(),
      'datePost': datePost.toIso8601String(),
      'slug': slug,
      'visual': visual,
      'commentCount': commentCount,
      'artType': artType != null ? {'id': artType!.id, 'name': artType!.name} : null,
    };
  }
}
