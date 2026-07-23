import 'package:flutter/material.dart';

class EasyHelpStep {
  const EasyHelpStep({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}

class EasyHelpCard extends StatelessWidget {
  const EasyHelpCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.steps,
    this.footer,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<EasyHelpStep> steps;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: isDark
          ? scheme.primaryContainer.withOpacity(0.18)
          : scheme.primaryContainer.withOpacity(0.34),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.primary.withOpacity(0.14)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 4,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            leading: CircleAvatar(
              radius: 21,
              backgroundColor: scheme.primary,
              child: Icon(icon, color: scheme.onPrimary, size: 21),
            ),
            title: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: scheme.surface.withOpacity(0.72),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.help_outline_rounded,
                    size: 16,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Ver passos',
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final tileWidth = width >= 880
                      ? (width - 30) / 4
                      : width >= 600
                      ? (width - 10) / 2
                      : width;

                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: steps.asMap().entries.map((entry) {
                      return SizedBox(
                        width: tileWidth,
                        child: _EasyHelpStepTile(
                          number: entry.key + 1,
                          step: entry.value,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              if (footer != null && footer!.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.surface.withOpacity(0.72),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: scheme.primary,
                        size: 19,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          footer!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EasyHelpStepTile extends StatelessWidget {
  const _EasyHelpStepTile({required this.number, required this.step});

  final int number;
  final EasyHelpStep step;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: 76,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(0.84),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: scheme.secondaryContainer,
                child: Icon(
                  step.icon,
                  color: scheme.onSecondaryContainer,
                  size: 19,
                ),
              ),
              Positioned(
                right: -4,
                top: -5,
                child: Container(
                  width: 19,
                  height: 19,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$number',
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  step.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
