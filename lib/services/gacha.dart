import 'dart:convert';
import 'dart:math';
import 'package:actiphibian/models/amphibian.dart';
import 'package:flutter/services.dart';

class GachaRoller {   
  static Rarity rollRarity() {
    Random random = Random();
    int roll = random.nextInt(100) + 1;
    if (roll <= 50) {
      return Rarity.common;
    }
    else if (roll <= 80) {
      return Rarity.uncommon;
    }
    else if (roll <= 99) {
      return Rarity.rare;
    }
    else {
      return Rarity.legendary;
    }
  }
  
  static Future<List<Amphibian>> getAmphibians() async {
    final jsonString = await rootBundle.loadString('assets/data/amphibians.json');

    final List<dynamic> list = jsonDecode(jsonString);

    List<Amphibian> amphibians = list.map((item) => Amphibian.fromJson(item as Map<String, Object?>)).toList();

    return amphibians;
  }

  static Future<Amphibian> roll() async {
    var amphibians = await getAmphibians();
    var rarity = rollRarity();
    List<Amphibian> selection = amphibians.where((a) => a.rarity == rarity).toList();
    if (selection.length == 1) {
      return selection.first;
    }
    else {
      Random random = Random();
      int index = random.nextInt(selection.length);
      
      return selection[index];
    }
  }
}