import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/momentum/domain/models/coach_intervention.dart';

void main() {
  group('CoachIntervention Model Tests', () {
    late CoachIntervention sampleIntervention;
    late DateTime testDate;
    late DateTime scheduledDate;
    late DateTime completedDate;

    setUp(() {
      testDate = DateTime(2024, 1, 15, 10, 30);
      scheduledDate = DateTime(2024, 1, 16, 14, 0);
      completedDate = DateTime(2024, 1, 16, 14, 45);

      sampleIntervention = CoachIntervention(
        id: 'test-intervention-123',
        patientName: 'Jane Smith',
        type: InterventionType.wellnessCheck,
        priority: InterventionPriority.high,
        status: InterventionStatus.pending,
        scheduledAt: scheduledDate,
        createdAt: testDate,
        notes: 'Weekly wellness check for ongoing monitoring',
        reason: 'Scheduled routine assessment',
        momentumData: {'recent_score': 85.5, 'trend': 'improving'},
      );
    });

    group('CoachIntervention Construction', () {
      test('should create valid intervention instance with all fields', () {
        expect(sampleIntervention.id, equals('test-intervention-123'));
        expect(sampleIntervention.patientName, equals('Jane Smith'));
        expect(sampleIntervention.type, equals(InterventionType.wellnessCheck));
        expect(sampleIntervention.priority, equals(InterventionPriority.high));
        expect(sampleIntervention.status, equals(InterventionStatus.pending));
        expect(sampleIntervention.scheduledAt, equals(scheduledDate));
        expect(sampleIntervention.createdAt, equals(testDate));
        expect(
          sampleIntervention.notes,
          equals('Weekly wellness check for ongoing monitoring'),
        );
        expect(
          sampleIntervention.reason,
          equals('Scheduled routine assessment'),
        );
        expect(sampleIntervention.momentumData, isNotNull);
        expect(sampleIntervention.momentumData!['recent_score'], equals(85.5));
      });

      test(
        'should create valid intervention instance with minimal required fields',
        () {
          const minimal = CoachIntervention(
            id: 'minimal-123',
            patientName: 'John Doe',
            type: InterventionType.checkIn,
            priority: InterventionPriority.medium,
            status: InterventionStatus.pending,
          );

          expect(minimal.id, equals('minimal-123'));
          expect(minimal.patientName, equals('John Doe'));
          expect(minimal.type, equals(InterventionType.checkIn));
          expect(minimal.priority, equals(InterventionPriority.medium));
          expect(minimal.status, equals(InterventionStatus.pending));
          expect(minimal.scheduledAt, isNull);
          expect(minimal.createdAt, isNull);
          expect(minimal.completedAt, isNull);
          expect(minimal.notes, isNull);
          expect(minimal.reason, isNull);
          expect(minimal.momentumData, isNull);
        },
      );

      test('should create sample intervention with default values', () {
        final sample = CoachIntervention.sample();

        expect(sample.id, equals('sample-intervention-001'));
        expect(sample.patientName, equals('John Doe'));
        expect(sample.type, equals(InterventionType.checkIn));
        expect(sample.priority, equals(InterventionPriority.medium));
        expect(sample.status, equals(InterventionStatus.pending));
        expect(sample.scheduledAt, isNotNull);
        expect(sample.createdAt, isNotNull);
        expect(sample.notes, equals('Weekly wellness check-in call'));
        expect(sample.reason, equals('Scheduled routine wellness assessment'));
      });

      test('should create sample intervention with custom values', () {
        final sample = CoachIntervention.sample(
          id: 'custom-sample-456',
          patientName: 'Alice Johnson',
          type: InterventionType.crisisIntervention,
          priority: InterventionPriority.urgent,
          status: InterventionStatus.inProgress,
        );

        expect(sample.id, equals('custom-sample-456'));
        expect(sample.patientName, equals('Alice Johnson'));
        expect(sample.type, equals(InterventionType.crisisIntervention));
        expect(sample.priority, equals(InterventionPriority.urgent));
        expect(sample.status, equals(InterventionStatus.inProgress));
      });
    });

    group('CopyWith Method', () {
      test('should copy with single field changes', () {
        final copied = sampleIntervention.copyWith(
          status: InterventionStatus.completed,
        );

        expect(copied.status, equals(InterventionStatus.completed));
        expect(copied.id, equals(sampleIntervention.id));
        expect(copied.patientName, equals(sampleIntervention.patientName));
        expect(copied.type, equals(sampleIntervention.type));
        expect(copied.priority, equals(sampleIntervention.priority));
        expect(copied.scheduledAt, equals(sampleIntervention.scheduledAt));
      });

      test('should copy with multiple field changes', () {
        final copied = sampleIntervention.copyWith(
          status: InterventionStatus.completed,
          completedAt: completedDate,
          notes: 'Updated notes after completion',
        );

        expect(copied.status, equals(InterventionStatus.completed));
        expect(copied.completedAt, equals(completedDate));
        expect(copied.notes, equals('Updated notes after completion'));
        expect(copied.id, equals(sampleIntervention.id));
        expect(copied.patientName, equals(sampleIntervention.patientName));
      });

      test('should copy with no changes when no parameters provided', () {
        final copied = sampleIntervention.copyWith();

        expect(copied.id, equals(sampleIntervention.id));
        expect(copied.patientName, equals(sampleIntervention.patientName));
        expect(copied.type, equals(sampleIntervention.type));
        expect(copied.priority, equals(sampleIntervention.priority));
        expect(copied.status, equals(sampleIntervention.status));
        expect(copied.scheduledAt, equals(sampleIntervention.scheduledAt));
        expect(copied.createdAt, equals(sampleIntervention.createdAt));
        expect(copied.notes, equals(sampleIntervention.notes));
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly with all fields', () {
        final json = sampleIntervention.toJson();

        expect(json['id'], equals('test-intervention-123'));
        expect(json['patient_name'], equals('Jane Smith'));
        expect(json['type'], equals('wellnessCheck'));
        expect(json['priority'], equals('high'));
        expect(json['status'], equals('pending'));
        expect(json['scheduled_at'], equals(scheduledDate.toIso8601String()));
        expect(json['created_at'], equals(testDate.toIso8601String()));
        expect(
          json['notes'],
          equals('Weekly wellness check for ongoing monitoring'),
        );
        expect(json['reason'], equals('Scheduled routine assessment'));
        expect(json['momentum_data'], isA<Map<String, dynamic>>());
      });

      test('should serialize to JSON correctly with minimal fields', () {
        const minimal = CoachIntervention(
          id: 'minimal-123',
          patientName: 'John Doe',
          type: InterventionType.checkIn,
          priority: InterventionPriority.medium,
          status: InterventionStatus.pending,
        );

        final json = minimal.toJson();

        expect(json['id'], equals('minimal-123'));
        expect(json['patient_name'], equals('John Doe'));
        expect(json['type'], equals('checkIn'));
        expect(json['priority'], equals('medium'));
        expect(json['status'], equals('pending'));
        expect(json.containsKey('scheduled_at'), isFalse);
        expect(json.containsKey('created_at'), isFalse);
        expect(json.containsKey('completed_at'), isFalse);
        expect(json.containsKey('notes'), isFalse);
        expect(json.containsKey('reason'), isFalse);
        expect(json.containsKey('momentum_data'), isFalse);
      });

      test('should maintain toMap backward compatibility', () {
        final map = sampleIntervention.toMap();
        final json = sampleIntervention.toJson();

        expect(map, equals(json));
      });
    });

    group('JSON Deserialization', () {
      test('should deserialize from JSON correctly with all fields', () {
        final json = sampleIntervention.toJson();
        final deserialized = CoachIntervention.fromJson(json);

        expect(deserialized.id, equals(sampleIntervention.id));
        expect(
          deserialized.patientName,
          equals(sampleIntervention.patientName),
        );
        expect(deserialized.type, equals(sampleIntervention.type));
        expect(deserialized.priority, equals(sampleIntervention.priority));
        expect(deserialized.status, equals(sampleIntervention.status));
        expect(
          deserialized.scheduledAt,
          equals(sampleIntervention.scheduledAt),
        );
        expect(deserialized.createdAt, equals(sampleIntervention.createdAt));
        expect(deserialized.notes, equals(sampleIntervention.notes));
        expect(deserialized.reason, equals(sampleIntervention.reason));
        expect(
          deserialized.momentumData,
          equals(sampleIntervention.momentumData),
        );
      });

      test(
        'should deserialize from JSON with null/missing fields gracefully',
        () {
          final json = {
            'id': 'test-123',
            'patient_name': 'Test Patient',
            'type': 'checkIn',
            'priority': 'medium',
            'status': 'pending',
          };

          final deserialized = CoachIntervention.fromJson(json);

          expect(deserialized.id, equals('test-123'));
          expect(deserialized.patientName, equals('Test Patient'));
          expect(deserialized.type, equals(InterventionType.checkIn));
          expect(deserialized.priority, equals(InterventionPriority.medium));
          expect(deserialized.status, equals(InterventionStatus.pending));
          expect(deserialized.scheduledAt, isNull);
          expect(deserialized.createdAt, isNull);
          expect(deserialized.completedAt, isNull);
          expect(deserialized.notes, isNull);
          expect(deserialized.reason, isNull);
          expect(deserialized.momentumData, isNull);
        },
      );

      test('should maintain fromMap backward compatibility', () {
        final map = sampleIntervention.toMap();
        final fromMap = CoachIntervention.fromMap(map);
        final fromJson = CoachIntervention.fromJson(map);

        expect(fromMap.id, equals(fromJson.id));
        expect(fromMap.patientName, equals(fromJson.patientName));
        expect(fromMap.type, equals(fromJson.type));
        expect(fromMap.priority, equals(fromJson.priority));
        expect(fromMap.status, equals(fromJson.status));
      });

      test('should round-trip serialize/deserialize correctly', () {
        final json = sampleIntervention.toJson();
        final deserialized = CoachIntervention.fromJson(json);
        final jsonAgain = deserialized.toJson();

        expect(jsonAgain, equals(json));
      });
    });

    group('Display Methods', () {
      test('should return correct type display names', () {
        expect(
          CoachIntervention.sample(
            type: InterventionType.checkIn,
          ).typeDisplayName,
          equals('Check-in Call'),
        );
        expect(
          CoachIntervention.sample(
            type: InterventionType.momentumSupport,
          ).typeDisplayName,
          equals('Momentum Support'),
        );
        expect(
          CoachIntervention.sample(
            type: InterventionType.medicationReminder,
          ).typeDisplayName,
          equals('Medication Reminder'),
        );
        expect(
          CoachIntervention.sample(
            type: InterventionType.wellnessCheck,
          ).typeDisplayName,
          equals('Wellness Check'),
        );
        expect(
          CoachIntervention.sample(
            type: InterventionType.crisisIntervention,
          ).typeDisplayName,
          equals('Crisis Intervention'),
        );
        expect(
          CoachIntervention.sample(
            type: InterventionType.followUp,
          ).typeDisplayName,
          equals('Follow-up Call'),
        );
      });

      test('should return correct priority display names', () {
        expect(
          CoachIntervention.sample(
            priority: InterventionPriority.low,
          ).priorityDisplayName,
          equals('Low'),
        );
        expect(
          CoachIntervention.sample(
            priority: InterventionPriority.medium,
          ).priorityDisplayName,
          equals('Medium'),
        );
        expect(
          CoachIntervention.sample(
            priority: InterventionPriority.high,
          ).priorityDisplayName,
          equals('High'),
        );
        expect(
          CoachIntervention.sample(
            priority: InterventionPriority.urgent,
          ).priorityDisplayName,
          equals('Urgent'),
        );
      });

      test('should return correct status display names', () {
        expect(
          CoachIntervention.sample(
            status: InterventionStatus.pending,
          ).statusDisplayName,
          equals('Pending'),
        );
        expect(
          CoachIntervention.sample(
            status: InterventionStatus.inProgress,
          ).statusDisplayName,
          equals('In Progress'),
        );
        expect(
          CoachIntervention.sample(
            status: InterventionStatus.completed,
          ).statusDisplayName,
          equals('Completed'),
        );
        expect(
          CoachIntervention.sample(
            status: InterventionStatus.cancelled,
          ).statusDisplayName,
          equals('Cancelled'),
        );
        expect(
          CoachIntervention.sample(
            status: InterventionStatus.noResponse,
          ).statusDisplayName,
          equals('No Response'),
        );
      });
    });

    group('Utility Methods', () {
      test('should correctly identify active interventions', () {
        expect(
          CoachIntervention.sample(status: InterventionStatus.pending).isActive,
          isTrue,
        );
        expect(
          CoachIntervention.sample(
            status: InterventionStatus.inProgress,
          ).isActive,
          isTrue,
        );
        expect(
          CoachIntervention.sample(
            status: InterventionStatus.completed,
          ).isActive,
          isFalse,
        );
        expect(
          CoachIntervention.sample(
            status: InterventionStatus.cancelled,
          ).isActive,
          isFalse,
        );
        expect(
          CoachIntervention.sample(
            status: InterventionStatus.noResponse,
          ).isActive,
          isFalse,
        );
      });

      test('should correctly identify interventions scheduled for today', () {
        final today = DateTime.now();
        final tomorrow = today.add(const Duration(days: 1));
        final yesterday = today.subtract(const Duration(days: 1));

        final todayIntervention = sampleIntervention.copyWith(
          scheduledAt: today,
        );
        final tomorrowIntervention = sampleIntervention.copyWith(
          scheduledAt: tomorrow,
        );
        final yesterdayIntervention = sampleIntervention.copyWith(
          scheduledAt: yesterday,
        );
        final nullScheduledIntervention = sampleIntervention.copyWith(
          scheduledAt: null,
        );

        expect(todayIntervention.isScheduledToday, isTrue);
        expect(tomorrowIntervention.isScheduledToday, isFalse);
        expect(yesterdayIntervention.isScheduledToday, isFalse);
        expect(nullScheduledIntervention.isScheduledToday, isFalse);
      });

      test('should format scheduled time correctly', () {
        final morning = DateTime(2024, 1, 15, 9, 30);
        final afternoon = DateTime(2024, 1, 15, 14, 5);
        final evening = DateTime(2024, 1, 15, 21, 45);

        expect(
          sampleIntervention
              .copyWith(scheduledAt: morning)
              .formattedScheduledTime,
          equals('09:30'),
        );
        expect(
          sampleIntervention
              .copyWith(scheduledAt: afternoon)
              .formattedScheduledTime,
          equals('14:05'),
        );
        expect(
          sampleIntervention
              .copyWith(scheduledAt: evening)
              .formattedScheduledTime,
          equals('21:45'),
        );

        // Create intervention with explicit null scheduledAt
        const interventionWithoutSchedule = CoachIntervention(
          id: 'test-id',
          patientName: 'Test Patient',
          type: InterventionType.checkIn,
          priority: InterventionPriority.medium,
          status: InterventionStatus.pending,
        );
        expect(interventionWithoutSchedule.formattedScheduledTime, isNull);
      });

      test('should generate time ago strings correctly', () {
        final now = DateTime.now();
        final justNow = now.subtract(const Duration(seconds: 30));
        final minutesAgo = now.subtract(const Duration(minutes: 15));
        final hoursAgo = now.subtract(const Duration(hours: 3));
        final daysAgo = now.subtract(const Duration(days: 2));

        expect(
          sampleIntervention.copyWith(createdAt: justNow).timeAgoString,
          equals('Just now'),
        );
        expect(
          sampleIntervention.copyWith(createdAt: minutesAgo).timeAgoString,
          equals('15 minutes ago'),
        );
        expect(
          sampleIntervention.copyWith(createdAt: hoursAgo).timeAgoString,
          equals('3 hours ago'),
        );
        expect(
          sampleIntervention.copyWith(createdAt: daysAgo).timeAgoString,
          equals('2 days ago'),
        );

        // Create intervention with explicit null createdAt
        const interventionWithoutCreated = CoachIntervention(
          id: 'test-id',
          patientName: 'Test Patient',
          type: InterventionType.checkIn,
          priority: InterventionPriority.medium,
          status: InterventionStatus.pending,
        );
        expect(interventionWithoutCreated.timeAgoString, isNull);
      });
    });
  });
}
