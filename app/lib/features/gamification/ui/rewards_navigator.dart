import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import 'achievements_screen.dart';

/// Navigation widget for rewards section with Badges and Challenges tabs
class RewardsNavigator extends ConsumerWidget {
  const RewardsNavigator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.getSurfaceSecondary(context),
        appBar: AppBar(
          title: const Text('Rewards'),
          backgroundColor: AppTheme.getSurfacePrimary(context),
          foregroundColor: AppTheme.getTextPrimary(context),
          elevation: 0,
          bottom: TabBar(
            labelColor: AppTheme.getMomentumColor(MomentumState.rising),
            unselectedLabelColor: AppTheme.getTextSecondary(context),
            indicatorColor: AppTheme.getMomentumColor(MomentumState.rising),
            tabs: const [
              Tab(icon: Icon(Icons.emoji_events), text: 'Badges'),
              Tab(icon: Icon(Icons.flag), text: 'Challenges'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [AchievementsScreen(), ChallengesListScreen()],
        ),
      ),
    );
  }
}

/// Placeholder screen for challenges list (to be implemented)
class ChallengesListScreen extends StatelessWidget {
  const ChallengesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getSurfaceSecondary(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                color: AppTheme.getSurfacePrimary(context),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.flag,
                        size: 64,
                        color: AppTheme.getMomentumColor(MomentumState.rising),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Challenges Coming Soon!',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Weekly and daily challenges will be available in the next update.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
