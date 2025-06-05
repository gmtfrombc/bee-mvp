#!/usr/bin/env dart

/// **Today Feed Cache Service Migration Helper**
///
/// Automated tool to help migrate from legacy Today Feed Cache Service methods
/// to the modern modular architecture.
///
/// Usage:
/// ```bash
/// dart scripts/migration_helper.dart [options]
/// ```
///
/// Options:
/// - --scan: Scan for legacy usage
/// - --report: Generate migration report
/// - --check-file <path>: Check specific file
/// - --verbose: Detailed output
library;

import 'dart:io';
import 'dart:convert';

/// Migration helper for Today Feed Cache Service
class TodayFeedCacheMigrationHelper {
  static const Map<String, String> _legacyMethodMappings = {
    // Testing & Lifecycle
    'resetForTesting': 'TodayFeedCacheService.resetForTesting()',

    // Cache Management
    'clearAllCache': 'TodayFeedCacheService.invalidateCache()',
    'getCacheStats': 'TodayFeedCacheService.getCacheMetadata()',

    // User Interaction
    'queueInteraction': 'TodayFeedCacheSyncService.cachePendingInteraction()',
    'cachePendingInteraction':
        'TodayFeedCacheSyncService.cachePendingInteraction()',
    'getPendingInteractions':
        'TodayFeedCacheSyncService.getPendingInteractions()',
    'clearPendingInteractions':
        'TodayFeedCacheSyncService.clearPendingInteractions()',
    'markContentAsViewed': 'TodayFeedCacheSyncService.markContentAsViewed()',

    // Content Management
    'getContentHistory': 'TodayFeedContentService.getContentHistory()',
    'invalidateContent': 'TodayFeedCacheMaintenanceService.invalidateContent()',

    // Sync & Network
    'syncWhenOnline': 'TodayFeedCacheSyncService.syncWhenOnline()',
    'setBackgroundSyncEnabled':
        'TodayFeedCacheSyncService.setBackgroundSyncEnabled()',
    'isBackgroundSyncEnabled':
        'TodayFeedCacheSyncService.isBackgroundSyncEnabled()',

    // Maintenance
    'selectiveCleanup': 'TodayFeedCacheMaintenanceService.selectiveCleanup()',
    'getCacheInvalidationStats':
        'TodayFeedCacheMaintenanceService.getCacheInvalidationStats()',

    // Health & Monitoring
    'getDiagnosticInfo': 'TodayFeedCacheHealthService.getDiagnosticInfo()',
    'getCacheStatistics':
        'TodayFeedCacheStatisticsService.getCacheStatistics()',
    'getCacheHealthStatus':
        'TodayFeedCacheHealthService.getCacheHealthStatus()',
    'exportMetricsForMonitoring':
        'TodayFeedCacheStatisticsService.exportMetricsForMonitoring()',
    'performCacheIntegrityCheck':
        'TodayFeedCacheHealthService.performCacheIntegrityCheck()',
  };

  static const Map<String, String> _requiredImports = {
    'TodayFeedCacheSyncService':
        "import 'package:your_app/core/services/cache/today_feed_cache_sync_service.dart';",
    'TodayFeedContentService':
        "import 'package:your_app/core/services/cache/today_feed_content_service.dart';",
    'TodayFeedCacheMaintenanceService':
        "import 'package:your_app/core/services/cache/today_feed_cache_maintenance_service.dart';",
    'TodayFeedCacheHealthService':
        "import 'package:your_app/core/services/cache/today_feed_cache_health_service.dart';",
    'TodayFeedCacheStatisticsService':
        "import 'package:your_app/core/services/cache/today_feed_cache_statistics_service.dart';",
  };

  /// Validate a specific file for legacy usage
  static Map<String, dynamic> validateCodeForLegacyUsage(String filePath) {
    final result = <String, dynamic>{
      'file': filePath,
      'legacy_usages': <Map<String, dynamic>>[],
      'required_imports': <String>[],
      'migration_suggestions': <String>[],
    };

    try {
      final content = File(filePath).readAsStringSync();
      final lines = content.split('\n');

      // Check for legacy method usage
      _legacyMethodMappings.forEach((legacyMethod, modernEquivalent) {
        final pattern = RegExp(
          r'TodayFeedCacheService\.' + legacyMethod + r'\s*\(',
          multiLine: true,
        );

        final matches = pattern.allMatches(content);
        for (final match in matches) {
          // Find line number
          final lineNumber = _getLineNumber(content, match.start);
          final lineContent = lines[lineNumber - 1].trim();

          result['legacy_usages'].add({
            'method': legacyMethod,
            'line': lineNumber,
            'content': lineContent,
            'modern_equivalent': modernEquivalent,
            'position': match.start,
          });

          // Check if modern equivalent requires new import
          final serviceClass = _extractServiceClass(modernEquivalent);
          if (serviceClass != null &&
              _requiredImports.containsKey(serviceClass)) {
            final importStatement = _requiredImports[serviceClass]!;
            if (!content.contains(importStatement.split("'")[1])) {
              if (!result['required_imports'].contains(importStatement)) {
                result['required_imports'].add(importStatement);
              }
            }
          }
        }
      });

      // Generate migration suggestions
      if (result['legacy_usages'].isNotEmpty) {
        result['migration_suggestions'].add(
          'Found ${result['legacy_usages'].length} legacy method usage(s)',
        );
        if (result['required_imports'].isNotEmpty) {
          result['migration_suggestions'].add(
            'Add ${result['required_imports'].length} new import(s)',
          );
        }
      }
    } catch (e) {
      result['error'] = e.toString();
    }

    return result;
  }

  /// Generate comprehensive migration report for multiple files
  static Map<String, dynamic> generateMigrationReport(List<String> filePaths) {
    final report = <String, dynamic>{
      'scan_date': DateTime.now().toIso8601String(),
      'files_scanned': filePaths.length,
      'files_with_legacy_usage': 0,
      'total_legacy_usages': 0,
      'legacy_method_breakdown': <String, int>{},
      'files': <Map<String, dynamic>>[],
      'migration_priority': <String>[],
      'required_imports': <String, int>{},
    };

    for (final filePath in filePaths) {
      final fileResult = validateCodeForLegacyUsage(filePath);

      if (fileResult['legacy_usages'].isNotEmpty) {
        report['files_with_legacy_usage']++;
        report['files'].add(fileResult);

        // Count legacy method usage
        for (final usage in fileResult['legacy_usages']) {
          final method = usage['method'] as String;
          report['legacy_method_breakdown'][method] =
              (report['legacy_method_breakdown'][method] ?? 0) + 1;
          report['total_legacy_usages']++;
        }

        // Count required imports
        for (final import in fileResult['required_imports']) {
          report['required_imports'][import] =
              (report['required_imports'][import] ?? 0) + 1;
        }
      }
    }

    // Generate migration priority based on usage frequency
    final sortedMethods = report['legacy_method_breakdown'].entries.toList()
      ..sort(
        (MapEntry<String, int> a, MapEntry<String, int> b) =>
            b.value.compareTo(a.value),
      );

    report['migration_priority'] = sortedMethods
        .map((entry) => '${entry.key} (${entry.value} usages)')
        .toList();

    return report;
  }

  /// Scan project directory for Dart files
  static List<String> scanProjectForDartFiles(String projectPath) {
    final dartFiles = <String>[];
    final directory = Directory(projectPath);

    if (directory.existsSync()) {
      directory
          .listSync(recursive: true)
          .where((entity) => entity is File && entity.path.endsWith('.dart'))
          .where((file) => !file.path.contains('/.dart_tool/'))
          .where((file) => !file.path.contains('/build/'))
          .where((file) => !file.path.contains('.g.dart'))
          .where((file) => !file.path.contains('.freezed.dart'))
          .forEach((file) => dartFiles.add(file.path));
    }

    return dartFiles;
  }

  /// Extract service class name from modern equivalent
  static String? _extractServiceClass(String modernEquivalent) {
    final pattern = RegExp(r'(\w+Service)\.', multiLine: true);
    final match = pattern.firstMatch(modernEquivalent);
    return match?.group(1);
  }

  /// Get line number for a character position in content
  static int _getLineNumber(String content, int position) {
    return content.substring(0, position).split('\n').length;
  }

  /// Print colorized output (if supported)
  static void _printColored(String text, String color) {
    final colorCodes = {
      'red': '\x1B[31m',
      'green': '\x1B[32m',
      'yellow': '\x1B[33m',
      'blue': '\x1B[34m',
      'magenta': '\x1B[35m',
      'cyan': '\x1B[36m',
      'white': '\x1B[37m',
      'reset': '\x1B[0m',
    };

    if (stdout.hasTerminal) {
      print('${colorCodes[color] ?? ''}$text${colorCodes['reset']}');
    } else {
      print(text);
    }
  }

  /// Print migration report in readable format
  static void printMigrationReport(Map<String, dynamic> report) {
    _printColored('\n🔍 Today Feed Cache Service Migration Report', 'cyan');
    _printColored('=' * 60, 'cyan');

    print('\n📊 Summary:');
    print('  • Files scanned: ${report['files_scanned']}');
    print('  • Files with legacy usage: ${report['files_with_legacy_usage']}');
    print('  • Total legacy method calls: ${report['total_legacy_usages']}');

    if (report['files_with_legacy_usage'] == 0) {
      _printColored('\n✅ Great! No legacy method usage found.', 'green');
      return;
    }

    print('\n🎯 Migration Priority (most used methods first):');
    for (final method in report['migration_priority']) {
      _printColored('  • $method', 'yellow');
    }

    print('\n📦 Required Imports:');
    final imports = report['required_imports'] as Map<String, int>;
    if (imports.isEmpty) {
      print('  • No new imports required');
    } else {
      imports.forEach((import, count) {
        print('  • $import (needed in $count file${count > 1 ? 's' : ''})');
      });
    }

    print('\n📁 Files requiring migration:');
    for (final fileResult in report['files']) {
      final filePath = fileResult['file'] as String;
      final usages = fileResult['legacy_usages'] as List;

      _printColored('\n  📄 $filePath', 'magenta');
      for (final usage in usages) {
        print('    Line ${usage['line']}: ${usage['method']}()');
        print('      ❌ Current: ${usage['content']}');
        print('      ✅ Replace with: ${usage['modern_equivalent']}');
      }
    }

    _printColored('\n📋 Next Steps:', 'blue');
    print(
      '  1. Review the migration guide: docs/refactor/today_feed_cache_migration_guide.md',
    );
    print('  2. Add required imports to files');
    print('  3. Replace legacy method calls with modern equivalents');
    print('  4. Test each migrated file thoroughly');
    print('  5. Run this scan again to verify completion');
  }
}

/// Main entry point for the migration helper script
void main(List<String> arguments) async {
  bool verbose = false;
  bool scan = false;
  bool report = false;
  String? checkFile;
  String projectPath = '.';

  // Parse command line arguments
  for (int i = 0; i < arguments.length; i++) {
    switch (arguments[i]) {
      case '--verbose':
        verbose = true;
        break;
      case '--scan':
        scan = true;
        break;
      case '--report':
        report = true;
        break;
      case '--check-file':
        if (i + 1 < arguments.length) {
          checkFile = arguments[i + 1];
          i++; // Skip next argument as it's the file path
        }
        break;
      case '--help':
        _printHelp();
        return;
    }
  }

  // Default to scan and report if no specific action specified
  if (!scan && !report && checkFile == null) {
    scan = true;
    report = true;
  }

  try {
    if (checkFile != null) {
      // Check specific file
      print('🔍 Checking file: $checkFile');
      final result = TodayFeedCacheMigrationHelper.validateCodeForLegacyUsage(
        checkFile,
      );

      if (result['error'] != null) {
        print('❌ Error: ${result['error']}');
        return;
      }

      if (result['legacy_usages'].isEmpty) {
        print('✅ No legacy usage found in $checkFile');
      } else {
        print('📋 Found ${result['legacy_usages'].length} legacy usage(s):');
        for (final usage in result['legacy_usages']) {
          print(
            '  Line ${usage['line']}: ${usage['method']}() -> ${usage['modern_equivalent']}',
          );
        }
      }
    } else if (scan || report) {
      // Scan entire project
      print('🔍 Scanning project for Today Feed Cache Service legacy usage...');

      final dartFiles = TodayFeedCacheMigrationHelper.scanProjectForDartFiles(
        projectPath,
      );

      if (verbose) {
        print('📁 Found ${dartFiles.length} Dart files to scan');
      }

      final migrationReport =
          TodayFeedCacheMigrationHelper.generateMigrationReport(dartFiles);

      if (report) {
        TodayFeedCacheMigrationHelper.printMigrationReport(migrationReport);
      }

      // Save report to file
      final reportFile = File('migration_report.json');
      await reportFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(migrationReport),
      );
      print('\n💾 Detailed report saved to: migration_report.json');
    }
  } catch (e) {
    print('❌ Migration helper failed: $e');
    exit(1);
  }
}

/// Print help information
void _printHelp() {
  print('''
Today Feed Cache Service Migration Helper

Usage: dart scripts/migration_helper.dart [options]

Options:
  --scan              Scan project for legacy usage (default)
  --report            Generate migration report (default)
  --check-file <path> Check specific file for legacy usage
  --verbose           Show detailed output
  --help              Show this help message

Examples:
  dart scripts/migration_helper.dart
  dart scripts/migration_helper.dart --check-file lib/features/today_feed/presentation/today_feed_page.dart
  dart scripts/migration_helper.dart --scan --verbose

The migration helper will:
1. Scan Dart files for legacy Today Feed Cache Service method usage
2. Identify required imports for modern API
3. Generate migration suggestions
4. Create a detailed report in JSON format

For more information, see: docs/refactor/today_feed_cache_migration_guide.md
''');
}
