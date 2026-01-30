class Bird {
  final int id;
  final String name;
  final bool discovered;
  final String? imagePath;

  const Bird({
    required this.id,
    required this.name,
    this.discovered = false,
    this.imagePath,
  });

  Bird copyWith({
    int? id,
    String? name,
    bool? discovered,
    String? imagePath,
  }) {
    return Bird(
      id: id ?? this.id,
      name: name ?? this.name,
      discovered: discovered ?? this.discovered,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}