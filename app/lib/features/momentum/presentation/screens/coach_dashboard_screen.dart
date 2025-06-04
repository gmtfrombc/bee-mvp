import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/coach_dashboard_state_provider.dart';
import '../widgets/coach_dashboard/coach_dashboard_overview_tab.dart';
import '../widgets/coach_dashboard/coach_dashboard_active_tab.dart';
import '../widgets/coach_dashboard/coach_dashboard_scheduled_tab.dart';
import '../widgets/coach_dashboard/coach_dashboard_analytics_tab.dart';

class CoachDashboardScreen extends ConsumerStatefulWidget {
  const CoachDashboardScreen({super.key});

  @override
  ConsumerState<CoachDashboardScreen> createState() =>
      _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends ConsumerState<CoachDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Performance: Cache tab widgets to avoid rebuilding them
  late final List<Widget> _tabWidgets;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Performance: Pre-initialize tab widgets with stable instances
    _initializeTabWidgets();
  }

  // Performance: Initialize tab widgets once to avoid recreation on rebuilds
  void _initializeTabWidgets() {
    _tabWidgets = [
      Consumer(
        builder: (context, ref, child) {
          final filters = ref.watch(
            coachDashboardStateProvider.select((state) => state.timeRange),
          );
          final stateActions = ref.read(coachDashboardStateActionsProvider);
          return CoachDashboardOverviewTab(
            selectedTimeRange: filters,
            onTimeRangeChanged: stateActions.updateTimeRange,
          );
        },
      ),
      Consumer(
        builder: (context, ref, child) {
          final priority = ref.watch(
            coachDashboardStateProvider.select((state) => state.priority),
          );
          final status = ref.watch(
            coachDashboardStateProvider.select((state) => state.status),
          );
          final stateActions = ref.read(coachDashboardStateActionsProvider);
          return CoachDashboardActiveTab(
            selectedPriority: priority,
            selectedStatus: status,
            onPriorityChanged: stateActions.updatePriority,
            onStatusChanged: stateActions.updateStatus,
            onInterventionUpdated: () {
              // State will be managed by the provider automatically
              // No need for manual setState calls
            },
          );
        },
      ),
      const CoachDashboardScheduledTab(
        onInterventionUpdated: null, // Static callback for performance
      ),
      Consumer(
        builder: (context, ref, child) {
          final filters = ref.watch(
            coachDashboardStateProvider.select((state) => state.timeRange),
          );
          final stateActions = ref.read(coachDashboardStateActionsProvider);
          return CoachDashboardAnalyticsTab(
            selectedTimeRange: filters,
            onTimeRangeChanged: stateActions.updateTimeRange,
          );
        },
      ),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coach Dashboard'),
        backgroundColor: AppTheme.momentumRising,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Active'),
            Tab(text: 'Scheduled'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabWidgets, // Performance: Use cached tab widgets
      ),
    );
  }
}
