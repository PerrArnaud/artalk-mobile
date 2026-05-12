class ArtType {
  final int id;
  final String name;

  const ArtType({required this.id, required this.name});

  factory ArtType.fromJson(Map<String, dynamic> json) {
    return ArtType(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}
