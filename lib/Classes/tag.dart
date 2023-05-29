import 'package:flutter/material.dart';

class Tag {
  final int id;
  String name;
  Color color;

  Tag(this.id, this.name,  this.color);

  static List<Tag> getTagsByName(List<Tag> allTags, List<String> names) {
    return [for (var n in names) allTags.firstWhere((t) => t.name == n)];
  }
}

