import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class LelecoLogo extends StatelessWidget {
  const LelecoLogo({
    super.key,
    this.size = 86,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.wine900,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.2),
        child: Image.asset(
          'assets/logo/logo.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Text(
                'AL',
                style: TextStyle(
                  color: AppColors.beige100,
                  fontSize: size * 0.32,
                  fontWeight: FontWeight.w900,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
