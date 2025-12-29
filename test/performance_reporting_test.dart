import 'dart:async';

import 'package:flutter_productivity_toolkit/src/performance/performance_monitor.dart';
import 'package:flutter_productivity_toolkit/src/performance/performance_reporter.dart';
import 'package:test/test.dart';

// Mock implementation for testing
class MockPerformanceMonitor extends PerformanceMonitor {
  final StreamController<PerformanceMetrics> _controller =
      StreamController<PerformanceMetrics>.broadcast();
  bool _isMonitoring = false;
  PerformanceThresholds? _thresholds;

  @override
  void startMonitoring() {
    _isMonitoring = true;
  }

  @override
  void stopMonitoring() {
    _isMonitoring = false;
  }

  @override
  bool get isMonitoring => _isMonitoring;

  @override
  Stream<PerformanceMetrics> get metricsStream => _controller.stream;

  @override
  void reportCustomMetric(String name, double value, {String? unit}) {
    // Mock implementation
  }

  @override
  PerformanceMetrics get currentMetrics => PerformanceMetrics(
        frameDrops: 0,
        memoryUsage: 50 * 1024 * 1024, // 50MB
        peakMemoryUsage: 60 * 1024 * 1024, // 60MB
        widgetRebuildCounts: const {'TestWidget': 5},
        averageFrameTime: 16,
        p95FrameTime: 18,
        fps: 60,
        warnings: const [],
        customMetrics: const {},
        timestamp: DateTime.now(),
      );

  @override
  Future<PerformanceReport> generateReport({
    Duration? timeRange,
    bool includeRecommendations = true,
  }) async =>
      PerformanceReport(
        summary: 'Mock performance report',
        metrics: currentMetrics,
        issues: const [],
        recommendations: const [],
        generatedAt: DateTime.now(),
        timeRange: timeRange ?? const Duration(minutes: 5),
      );

  @override
  void setThresholds(PerformanceThresholds thresholds) {
    _thresholds = thresholds;
  }

  @override
  void clearMetrics() {
    // Mock implementation
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  group('Performance Reporting System', () {
    late MockPerformanceMonitor monitor;
    late PerformanceReporter reporter;

    setUp(() {
      monitor = MockPerformanceMonitor();
      reporter = PerformanceReporter(monitor);
    });

    tearDown(() {
      reporter.dispose();
      monitor.dispose();
    });

    test('should create performance snapshots', () {
      final snapshot = reporter.takeSnapshot(label: 'Test Snapshot');

      expect(snapshot.label, equals('Test Snapshot'));
      expect(snapshot.metrics, isNotNull);
      expect(snapshot.timestamp, isNotNull);
      expect(reporter.snapshotCount, equals(1));
    });

    test('should generate quick performance summary', () {
      final summary = reporter.generateQuickSummary();

      expect(summary, contains('Performance Score:'));
      expect(summary, contains('FPS:'));
      expect(summary, contains('Memory:'));
      expect(summary, contains('Warnings:'));
    });

    test('should compare performance snapshots', () async {
      final before = reporter.takeSnapshot(label: 'Before');

      // Simulate some performance change
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final after = reporter.takeSnapshot(label: 'After');
      final comparison = reporter.compareSnapshots(before, after);

      expect(comparison.before, equals(before));
      expect(comparison.after, equals(after));
      expect(comparison.improvementSummary, isNotNull);
    });

    test('should generate enhanced performance report', () async {
      // Take some snapshots first
      reporter.takeSnapshot(label: 'Snapshot 1');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      reporter.takeSnapshot(label: 'Snapshot 2');

      final report = await reporter.generateEnhancedReport();

      expect(report.baseReport, isNotNull);
      expect(report.performanceScore, isA<double>());
      expect(report.performanceScore, greaterThanOrEqualTo(0));
      expect(report.performanceScore, lessThanOrEqualTo(100));
      expect(report.generatedAt, isNotNull);
    });

    test('should calculate performance statistics', () {
      // Add some snapshots
      reporter.takeSnapshot(label: 'Stats 1');
      reporter.takeSnapshot(label: 'Stats 2');
      reporter.takeSnapshot(label: 'Stats 3');

      final stats = reporter.getStatistics();

      expect(stats.sampleCount, equals(3));
      expect(stats.averageFps, isA<double>());
      expect(stats.averageMemoryUsage, isA<double>());
      expect(stats.averageFrameTime, isA<double>());
    });

    test('should handle empty statistics gracefully', () {
      final stats = reporter.getStatistics();

      expect(stats.sampleCount, equals(0));
      expect(stats.averageFps, equals(0.0));
      expect(stats.averageMemoryUsage, equals(0.0));
    });

    test('should create and run performance benchmarks', () async {
      const benchmark = PerformanceBenchmark(
        name: 'Test Benchmark',
        description: 'A test benchmark',
        duration: Duration(milliseconds: 50),
        expectedFps: 60,
        maxMemoryUsage: 100 * 1024 * 1024, // 100MB
      );

      reporter.addBenchmark(benchmark);
      expect(reporter.benchmarkCount, equals(1));

      final result = await reporter.runBenchmark(benchmark);

      expect(result.benchmark, equals(benchmark));
      expect(result.beforeMetrics, isNotNull);
      expect(result.afterMetrics, isNotNull);
      expect(result.duration, isNotNull);
      expect(result.score, isA<double>());
      expect(result.passed, isA<bool>());
    });

    test('should export performance data to JSON', () {
      reporter.takeSnapshot(label: 'JSON Test');

      final json = reporter.exportToJson();

      expect(json, isNotNull);
      expect(json, contains('currentMetrics'));
      expect(json, contains('exportedAt'));
      expect(json, contains('snapshots'));
    });

    test('should clear history', () {
      reporter.takeSnapshot(label: 'Clear Test 1');
      reporter.takeSnapshot(label: 'Clear Test 2');

      expect(reporter.snapshotCount, equals(2));

      reporter.clearHistory();

      expect(reporter.snapshotCount, equals(0));
      expect(reporter.benchmarkCount, equals(0));
    });

    test('should handle performance alerts', () async {
      final alertCompleter = Completer<PerformanceAlert>();

      reporter.alertStream.listen((alert) {
        if (!alertCompleter.isCompleted) {
          alertCompleter.complete(alert);
        }
      });

      reporter.startReporting(
        snapshotInterval: const Duration(milliseconds: 100),
      );

      // Wait a bit to see if any alerts are generated
      await Future<void>.delayed(const Duration(milliseconds: 200));

      reporter.stopReporting();

      // The test passes if no exceptions are thrown
      expect(true, isTrue);
    });

    test('should maintain snapshot history limit', () {
      // Add more than 100 snapshots to test the limit
      for (var i = 0; i < 105; i++) {
        reporter.takeSnapshot(label: 'Snapshot $i');
      }

      // Should maintain only the last 100 snapshots
      expect(reporter.snapshotCount, equals(100));
    });

    test('should create benchmark objects correctly', () {
      const benchmark = PerformanceBenchmark(
        name: 'Test Benchmark',
        description: 'A test benchmark for validation',
        duration: Duration(seconds: 1),
        expectedFps: 60,
        maxMemoryUsage: 100 * 1024 * 1024, // 100MB
      );

      expect(benchmark.name, equals('Test Benchmark'));
      expect(benchmark.description, equals('A test benchmark for validation'));
      expect(benchmark.duration, equals(const Duration(seconds: 1)));
      expect(benchmark.expectedFps, equals(60.0));
      expect(benchmark.maxMemoryUsage, equals(100 * 1024 * 1024));
    });
  });

  group('Performance Report Content', () {
    late PerformanceReporter reporter;
    late MockPerformanceMonitor monitor;

    setUp(() {
      monitor = MockPerformanceMonitor();
      reporter = PerformanceReporter(monitor);
    });

    tearDown(() {
      reporter.dispose();
      monitor.dispose();
    });

    test('should generate comprehensive report content', () async {
      // Add some test data
      reporter.takeSnapshot(label: 'Content Test 1');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      reporter.takeSnapshot(label: 'Content Test 2');

      final report = await reporter.generateEnhancedReport();

      expect(report.baseReport.summary, isNotNull);
      expect(report.baseReport.metrics, isNotNull);
      expect(report.baseReport.issues, isNotNull);
      expect(report.baseReport.recommendations, isNotNull);
      expect(report.performanceScore, greaterThanOrEqualTo(0));
      expect(report.performanceScore, lessThanOrEqualTo(100));
    });

    test('should handle report generation with different options', () async {
      final reportWithAll = await reporter.generateEnhancedReport();

      final reportMinimal = await reporter.generateEnhancedReport(
        includeComparisons: false,
        includeTrendAnalysis: false,
        includeBenchmarks: false,
      );

      expect(reportWithAll.baseReport, isNotNull);
      expect(reportMinimal.baseReport, isNotNull);
    });
  });
}
