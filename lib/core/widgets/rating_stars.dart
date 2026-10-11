import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

// 5 stars me se rating ke hisaab se bhare hue dikhao.
class RatingStars extends StatelessWidget {
  final double rating;
  final double size;

  const RatingStars({super.key, required this.rating, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating.round() ? Icons.star : Icons.star_border,
          size: size,
          color: AppColors.gold,
        );
      }),
    );
  }
}
