import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/coach_intervention_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/coach_dashboard/coach_dashboard_stat_card.dart';
import '../widgets/coach_dashboard/coach_dashboard_time_selector.dart';
import '../widgets/coach_dashboard/coach_dashboard_overview_tab.dart';
import '../widgets/coach_dashboard/coach_dashboard_active_tab.dart';

class CoachDashboardScreen extends ConsumerStatefulWidget {
  const CoachDashboardScreen({super.key});

  @override
  ConsumerState<CoachDashboardScreen> createState() =>
      _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends ConsumerState<CoachDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTimeRange = '7d';
  String _selectedPriority = 'all';
  String _selectedStatus = 'all';

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

  @override
  Widget build(BuildContext context) {
    final interventionService = ref.watch(coachInterventionServiceProvider);

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
            selectedTimeRange: _selectedTimeRange,
            onTimeRangeChanged: (value) {
              setState(() {
                _selectedTimeRange = value;
              });
            },
          ),
          CoachDashboardActiveTab(
            selectedPriority: _selectedPriority,
            selectedStatus: _selectedStatus,
            onPriorityChanged: (value) {
              setState(() {
                _selectedPriority = value;
              });
            },
            onStatusChanged: (value) {
              setState(() {
                _selectedStatus = value;
              });
            },
            onInterventionUpdated: () {
              setState(() {});
            },
          ),
          _buildScheduledInterventionsTab(interventionService),
          _buildAnalyticsTab(interventionService),
        ],
      ),
    );
  }

  Widget _buildScheduledInterventionsTab(CoachInterventionService service) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: service.getScheduledInterventions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final interventions = snapshot.data ?? [];

        return interventions.isEmpty
            ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No scheduled interventions',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
            : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: interventions.length,
              itemBuilder: (context, index) {
                return _buildInterventionCard(interventions[index], service);
              },
            );
      },
    );
  }

  Widget _buildAnalyticsTab(CoachInterventionService service) {
    return FutureBuilder<Map<String, dynamic>>(
      future: service.getInterventionAnalytics(_selectedTimeRange),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final analytics = snapshot.data ?? {};

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CoachDashboardTimeSelector(
                selectedTimeRange: _selectedTimeRange,
                onTimeRangeChanged: (value) {
                  setState(() {
                    _selectedTimeRange = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              _buildAnalyticsCards(analytics),
              const SizedBox(height: 24),
              _buildEffectivenessChart(analytics),
              const SizedBox(height: 24),
              _buildTrendAnalysis(analytics),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsCards(Map<String, dynamic> analytics) {
    final stats = analytics['summary'] as Map<String, dynamic>? ?? {};

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        CoachDashboardStatCard(
          title: 'Success Rate',
          value: '${stats['success_rate'] ?? 0}%',
          icon: Icons.trending_up,
          color: Colors.green,
        ),
        CoachDashboardStatCard(
          title: 'Avg Response Time',
          value: '${stats['avg_response_time'] ?? 0}h',
          icon: Icons.timer,
          color: Colors.blue,
        ),
        CoachDashboardStatCard(
          title: 'Total Interventions',
          value: '${stats['total_interventions'] ?? 0}',
          icon: Icons.psychology,
          color: AppTheme.momentumRising,
        ),
        CoachDashboardStatCard(
          title: 'Patient Satisfaction',
          value: '${stats['satisfaction_score'] ?? 0}/5',
          icon: Icons.star,
          color: Colors.amber,
        ),
      ],
    );
  }

  Widget _buildEffectivenessChart(Map<String, dynamic> analytics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Intervention Effectiveness',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: const Center(
            child: Text(
              'Chart implementation would go here\n(fl_chart integration)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendAnalysis(Map<String, dynamic> analytics) {
    final trends = analytics['trends'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trend Analysis',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child:
              trends.isEmpty
                  ? const Center(
                    child: Text(
                      'No trend data available',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                  : Column(
                    children:
                        trends.map<Widget>((trend) {
                          return _buildTrendItem(trend as Map<String, dynamic>);
                        }).toList(),
                  ),
        ),
      ],
    );
  }

  Widget _buildTrendItem(Map<String, dynamic> trend) {
    final metric = trend['metric'] as String? ?? '';
    final change = trend['change'] as double? ?? 0.0;
    final isPositive = change >= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: isPositive ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              metric,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}${change.toStringAsFixed(1)}%',
            style: TextStyle(
              color: isPositive ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterventionCard(
    Map<String, dynamic> intervention,
    CoachInterventionService service,
  ) {
    final priority = intervention['priority'] as String? ?? 'medium';
    final status = intervention['status'] as String? ?? 'pending';
    final patientName = intervention['patient_name'] as String? ?? 'Unknown';
    final type = intervention['type'] as String? ?? 'general';
    final scheduledAt = DateTime.tryParse(
      intervention['scheduled_at'] as String? ?? '',
    );
    final notes = intervention['notes'] as String? ?? '';

    Color priorityColor;
    switch (priority) {
      case 'high':
        priorityColor = Colors.red;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        break;
      case 'low':
        priorityColor = Colors.green;
        break;
      default:
        priorityColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: priorityColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    priority.toUpperCase(),
                    style: TextStyle(
                      color: priorityColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    switch (value) {
                      case 'complete':
                        await service.completeIntervention(intervention['id']);
                        setState(() {});
                        break;
                      case 'reschedule':
                        _showRescheduleDialog(intervention, service);
                        break;
                      case 'cancel':
                        await service.cancelIntervention(intervention['id']);
                        setState(() {});
                        break;
                    }
                  },
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'complete',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Mark Complete'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'reschedule',
                          child: Row(
                            children: [
                              Icon(Icons.schedule, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('Reschedule'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'cancel',
                          child: Row(
                            children: [
                              Icon(Icons.cancel, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Cancel'),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              patientName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Type: ${type.replaceAll('_', ' ').toUpperCase()}',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            if (scheduledAt != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Scheduled: ${DateFormat('MMM d, h:mm a').format(scheduledAt)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(notes, style: const TextStyle(fontSize: 14)),
            ],
          ],
        ),
      ),
    );
  }

  void _showRescheduleDialog(
    Map<String, dynamic> intervention,
    CoachInterventionService service,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reschedule Intervention'),
            content: const Text(
              'Reschedule functionality would be implemented here',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Implement reschedule logic
                },
                child: const Text('Reschedule'),
              ),
            ],
          ),
    );
  }
}
