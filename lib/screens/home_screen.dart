import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:saferoute/components/mode_option_button.dart';
import 'package:saferoute/models/route_model.dart';
import 'package:saferoute/nav.dart';
import 'package:saferoute/theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primary.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.16 : 0.10),
              Theme.of(context).scaffoldBackgroundColor,
              scheme.secondary.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.10 : 0.08),
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: AppSpacing.page,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.lg),
                Text('SafeRoute', style: t.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Discover safer routes for running and cycling in Indian cities. Tap a mode to begin.',
                  style: t.bodyMedium?.copyWith(color: scheme.onSurface.withValues(alpha: 0.78)),
                ),
                const SizedBox(height: AppSpacing.xl),
                ModeOptionButton(
                  label: 'Run',
                  subtitle: 'Uses walking directions (avoid highways)',
                  icon: Icons.directions_run_rounded,
                  onTap: () => context.push(AppRoutes.map, extra: TravelMode.run),
                ),
                const SizedBox(height: AppSpacing.md),
                ModeOptionButton(
                  label: 'Cycle',
                  subtitle: 'Uses bicycling directions (avoid highways)',
                  icon: Icons.directions_bike_rounded,
                  onTap: () => context.push(AppRoutes.map, extra: TravelMode.cycle),
                ),
                const Spacer(),
                Text(
                  'Tip: Ensure GPS is enabled for real-time tracking.',
                  style: t.bodySmall?.copyWith(color: scheme.onSurface.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
