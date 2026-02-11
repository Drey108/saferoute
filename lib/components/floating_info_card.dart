import 'package:flutter/material.dart';
import 'package:saferoute/theme.dart';

class FloatingInfoCard extends StatelessWidget {
  final String distanceText;
  final String etaText;
  final int safetyScore;
  final String? trafficDelayText;
  final bool isLoading;

  const FloatingInfoCard({
    super.key,
    required this.distanceText,
    required this.etaText,
    required this.safetyScore,
    required this.trafficDelayText,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final scoreColor = safetyScore >= 80
        ? scheme.secondary
        : safetyScore >= 60
            ? Colors.orange
            : scheme.error;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: Container(
        key: ValueKey('${distanceText}_${etaText}_${safetyScore}_${trafficDelayText ?? ''}_$isLoading'),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _MetricTile(title: 'Remaining', value: distanceText, icon: Icons.route_rounded),
                const SizedBox(width: AppSpacing.md),
                _MetricTile(title: 'ETA', value: etaText, icon: Icons.timelapse_rounded),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: scoreColor.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, size: 16, color: scoreColor),
                      const SizedBox(width: 6),
                      Text('Safety $safetyScore', style: t.labelSmall?.copyWith(color: scoreColor)),
                    ],
                  ),
                ),
                const Spacer(),
                if (isLoading)
                  SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary.withValues(alpha: 0.9)),
                  ),
              ],
            ),
            if (trafficDelayText != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: scheme.error.withValues(alpha: 0.22)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.traffic_rounded, color: scheme.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Traffic delay: $trafficDelayText',
                        style: t.bodySmall?.copyWith(color: scheme.onSurface.withValues(alpha: 0.85)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MetricTile({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: t.labelSmall?.copyWith(color: scheme.onSurface.withValues(alpha: 0.7)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(value, style: t.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
