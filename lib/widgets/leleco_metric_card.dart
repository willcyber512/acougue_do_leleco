import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class LelecoMetricCard extends StatelessWidget {
  const LelecoMetricCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.footer,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        height: 142,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.wine700, size: 29),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (footer != null) ...[
              const SizedBox(height: 2),
              Text(
                footer!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
