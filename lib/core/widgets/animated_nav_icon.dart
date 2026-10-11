import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';

// Bottom nav ka icon: active hone par pop animation ke saath
class AnimatedNavIcon extends StatelessWidget {
  final bool active;
  final IconData icon;
  final IconData activeIcon;
  const AnimatedNavIcon({
    super.key,
    required this.active,
    required this.icon,
    required this.activeIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      active ? activeIcon : icon,
      color: active ? Colors.white : AppColors.textMuted,
      size: 22,
    ).animate(key: ValueKey(active)).scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1, 1),
          duration: 300.ms,
          curve: Curves.easeOutBack,
        );
  }
}
