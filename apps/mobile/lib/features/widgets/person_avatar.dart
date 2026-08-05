import 'package:flutter/material.dart';

import '../mock_data.dart';

/// Circular avatar with the person's initials on their colour.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar(
    this.person, {
    super.key,
    this.size = 36,
    this.fontSize,
  });

  final Person person;
  final double size;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: person.color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        person.initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize ?? size * 0.31,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
