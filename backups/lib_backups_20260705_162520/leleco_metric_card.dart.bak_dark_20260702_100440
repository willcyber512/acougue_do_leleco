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
        height: 150,
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: AppColors.wine700,
              size: 26,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (footer != null) ...[
              const SizedBox(height: 4),
              Text(
                footer!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
