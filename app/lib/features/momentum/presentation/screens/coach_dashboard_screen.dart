import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/coach_dashboard_filters.dart';
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
  CoachDashboardFilters _filters = const CoachDashboardFilters();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Updates the filter state using immutable copyWith pattern
  void _updateFilters(CoachDashboardFilters newFilters) {
    setState(() {
      _filters = newFilters;
    });
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
        children: [
          CoachDashboardOverviewTab(
            selectedTimeRange: _filters.timeRange,
            onTimeRangeChanged: (value) {
              _updateFilters(_filters.copyWith(timeRange: value));
            },
          ),
          CoachDashboardActiveTab(
            selectedPriority: _filters.priority,
            selectedStatus: _filters.status,
            onPriorityChanged: (value) {
              _updateFilters(_filters.copyWith(priority: value));
            },
            onStatusChanged: (value) {
              _updateFilters(_filters.copyWith(status: value));
            },
            onInterventionUpdated: () {
              setState(() {});
            },
          ),
          CoachDashboardScheduledTab(
            onInterventionUpdated: () {
              setState(() {});
            },
          ),
          CoachDashboardAnalyticsTab(
            selectedTimeRange: _filters.timeRange,
            onTimeRangeChanged: (value) {
              _updateFilters(_filters.copyWith(timeRange: value));
            },
          ),
        ],
      ),
    );
  }
}
