import 'package:flutter/material.dart';

class Company {
  const Company({required this.id, required this.name, required this.color});

  final String id;
  final String name;
  final String color;

  Color get colorValue {
    final raw = color.replaceFirst('#', '');
    return Color(int.parse('FF$raw', radix: 16));
  }

  factory Company.fromMap(String id, Map<String, dynamic> data) => Company(
    id: id,
    name: (data['name'] ?? '').toString(),
    color: (data['color'] ?? '#286C71').toString(),
  );

  Map<String, dynamic> toMap() => {'name': name, 'color': color};
}
