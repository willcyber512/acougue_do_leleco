import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class LelecoLogo extends StatelessWidget {
  const LelecoLogo({
    super.key,
    this.size = 92,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.07),
      decoration: BoxDecoration(
        color: AppColors.wine900,
        borderRadius: BorderRadius.circular(size * 0.26),
      ),
      child: Image.asset(
        'assets/logo/logo.png',
        fit: BoxFit.contain,
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
    );
  }
}
