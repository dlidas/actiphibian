import 'package:actiphibian/models/mappable.dart';

enum Rarity {
  common,
  uncommon,
  rare,
  legendary
}

class Amphibian implements IMappable {
  int? id;
  final String name;
  final String species;
  final String description;
  final Rarity rarity;
  final String filePath;

  Amphibian({
    this.id,
    required this.name,
    required this.species,
    required this.description,
    required this.rarity,
    required this.filePath
  });

  factory Amphibian.fromJson(Map<String, Object?> json) {
    return Amphibian( 
      name: json['name'] as String, 
      species: json['species'] as String, 
      description: json['description'] as String, 
      rarity: Rarity.values.byName(json['rarity'] as String), 
      filePath: json['file_path'] as String,
    );
  }

  factory Amphibian.fromMap(Map<String, Object?> map) {
    return Amphibian(
      id: map['id'] as int,
      name: map['name'] as String,
      species: map['species'] as String,
      description: map['description'] as String,
      rarity: Rarity.values.byName(map['rarity']as String),
      filePath: map['file_path'] as String,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return { 
      'name': name, 
      'species': species,
      'description': '\'$description\'', 
      'rarity': rarity.name,
      'file_path': filePath
    };
  }

  @override
  String toString() {
    return 'Amphibian{id: $id, name: $name, description: $description, rarity: $rarity, filepath: $filePath}';
  }
}