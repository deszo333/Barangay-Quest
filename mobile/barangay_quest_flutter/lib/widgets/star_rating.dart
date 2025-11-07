import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final int value; // 0..max
  final int max;
  final ValueChanged<int>? onChanged;
  final double size;
  final bool readOnly;
  const StarRating(
      {super.key,
      required this.value,
      this.onChanged,
      this.max = 5,
      this.size = 28,
      this.readOnly = false});

  @override
  Widget build(BuildContext context) {
    final stars = List.generate(max, (i) {
      final filled = i < value;
      final icon = Icon(
        filled ? Icons.star_rounded : Icons.star_border_rounded,
        color: filled ? const Color(0xFFFFD166) : Colors.grey,
        size: size,
      );
      if (readOnly || onChanged == null) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: icon,
        );
      }
      return IconButton(
        onPressed: () => onChanged!(i + 1),
        padding: const EdgeInsets.all(0),
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        icon: icon,
      );
    });
    return Row(mainAxisSize: MainAxisSize.min, children: stars);
  }
}
