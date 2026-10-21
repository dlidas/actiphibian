enum Rarity {
  common,
  uncommon,
  rare,
  legendary
}

class Amphibian {
  final int id;
  final String name;
  final String description;
  final Rarity rarity;
  final String filePath;

  Amphibian({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    required this.filePath
  });

  factory Amphibian.fromJson(Map<String, Object?> json) {
    return Amphibian(
      id: json['id'] as int, 
      name: json['name'] as String, 
      description: json['description'] as String, 
      rarity: Rarity.values.byName(json['rarity'] as String), 
      filePath: json['file_path'] as String,
    );
  }

  @override
  String toString() {
    return 'Amphibian{id: $id, name: $name, description: $description, rarity: $rarity, filepath: $filePath}';
  }
}