import 'package:flutter/material.dart';

/// Avatar com as iniciais do nome; a cor é estável para cada sala.
class RoomAvatar extends StatelessWidget {
  const RoomAvatar({
    required this.seed,
    required this.name,
    this.size = 40,
    super.key,
  });

  final String seed;
  final String name;
  final double size;

  static const List<MaterialColor> _palette = [
    Colors.teal,
    Colors.indigo,
    Colors.deepOrange,
    Colors.purple,
    Colors.green,
    Colors.blue,
    Colors.pink,
    Colors.brown,
  ];

  String get _initials {
    final words = name
        .replaceAll(RegExp('[#@!]'), '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty);
    return words
        .take(2)
        .map((word) => word.characters.first)
        .join()
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final color = _palette[seed.hashCode.abs() % _palette.length];
    final initials = _initials;
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: color.shade100,
      foregroundColor: color.shade900,
      child: initials.isEmpty
          ? Icon(Icons.tag, size: size / 2)
          : Text(initials, style: TextStyle(fontSize: size * 0.38)),
    );
  }
}
