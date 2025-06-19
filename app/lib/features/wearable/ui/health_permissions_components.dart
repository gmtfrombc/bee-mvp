/// Health Permissions UI Components
///
/// This file contains reusable UI components for the health permissions modal,
/// including permission items, error messages, and common UI elements.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../../../core/services/wearable_data_models.dart';
import '../../../core/services/responsive_service.dart';

/// Data class for permission item information
class PermissionItem {
  final IconData icon;
  final String title;
  final String description;
  final List<WearableDataType> dataTypes;

  const PermissionItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.dataTypes,
  });
}

/// Widget for displaying a single permission item
class HealthPermissionItemWidget extends StatelessWidget {
  final PermissionItem permission;

  const HealthPermissionItemWidget({super.key, required this.permission});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        bottom: ResponsiveService.getSmallSpacing(context),
      ),
      padding: ResponsiveService.getMediumPadding(context),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(
          ResponsiveService.getBorderRadius(context),
        ),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              permission.icon,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
          ),
          SizedBox(width: ResponsiveService.getMediumSpacing(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  permission.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  permission.description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const Icon(
            CupertinoIcons.checkmark_circle_fill,
            color: Colors.green,
            size: 20,
          ),
        ],
      ),
    );
  }
}

/// Widget for displaying a list of permissions
class HealthPermissionsListWidget extends StatelessWidget {
  const HealthPermissionsListWidget({super.key});

  static final List<PermissionItem> _permissions = [
    const PermissionItem(
      icon: CupertinoIcons.rays,
      title: 'Steps & Activity',
      description: 'Track daily movement and activity patterns',
      dataTypes: [WearableDataType.steps, WearableDataType.activeEnergyBurned],
    ),
    const PermissionItem(
      icon: CupertinoIcons.heart,
      title: 'Heart Rate',
      description: 'Monitor cardiovascular health and stress levels',
      dataTypes: [
        WearableDataType.heartRate,
        WearableDataType.restingHeartRate,
      ],
    ),
    const PermissionItem(
      icon: CupertinoIcons.moon_zzz,
      title: 'Sleep Patterns',
      description: 'Understand sleep quality for better recovery',
      dataTypes: [WearableDataType.sleepDuration, WearableDataType.sleepInBed],
    ),
    const PermissionItem(
      icon: CupertinoIcons.person,
      title: 'Body Weight',
      description: 'Track weight changes over time',
      dataTypes: [WearableDataType.weight],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health Data We\'ll Access',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: ResponsiveService.getMediumSpacing(context)),
        ..._permissions.map(
          (permission) => HealthPermissionItemWidget(permission: permission),
        ),
      ],
    );
  }
}

/// Widget for displaying error messages
class HealthPermissionsErrorWidget extends StatelessWidget {
  final String message;

  const HealthPermissionsErrorWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveService.getMediumPadding(context),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(
          ResponsiveService.getBorderRadius(context),
        ),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.red[800]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget for modal header with platform-specific content
class HealthPermissionsHeaderWidget extends StatelessWidget {
  const HealthPermissionsHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              CupertinoIcons.heart_fill,
              color: Colors.red,
              size: ResponsiveService.getIconSize(context),
            ),
            SizedBox(width: ResponsiveService.getSmallSpacing(context)),
            Expanded(
              child: Text(
                Platform.isIOS
                    ? 'Connect Your Health Data'
                    : 'Connect Health Data via Health Connect',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveService.getSmallSpacing(context)),
        Text(
          Platform.isIOS
              ? 'BEE Momentum Coach uses your health data to provide personalized coaching and track your wellness progress. Your data is secure and only used to help you achieve your goals.'
              : 'BEE Momentum Coach uses Health Connect to access your health data for personalized coaching. Health Connect centralizes your health data while keeping it secure and private.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

/// Widget for Android-specific information
class AndroidHealthConnectInfoWidget extends StatelessWidget {
  const AndroidHealthConnectInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveService.getMediumPadding(context),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(
          ResponsiveService.getBorderRadius(context),
        ),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Health Connect Requirements',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Requires Android 9+ with Health Connect app or Android 14+\n'
            '• Screen lock must be enabled for security\n'
            '• Historical data limited to 30 days by default\n'
            '• Connect Garmin, Fitbit, and other health apps through Health Connect',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.blue[800],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
