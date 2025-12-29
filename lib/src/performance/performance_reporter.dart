import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'performance_monitor.dart';

/// Advanced performance reporting system with trend analysis and alerting.
///
/// Provides comprehensive performance report generation, before/after comparisons,
/// trend analysis, and performance benchmark utilities.
class PerformanceReporter {
  /// Creates a new performance reporter.
  PerformanceReporter(this._monitor);
  final PerformanceMonitor _monitor;
  final List<PerformanceSnapshot> _snapshots = [];
  final List<PerformanceBenchmark> _benchmarks = [];

  StreamSubscription<PerformanceMetrics>? _metricsSubscription;
  final StreamController<PerformanceAlert> _alertController =
      StreamController<PerformanceAlert>.broadcast();

  /// Stream of performance alerts when thresholds are exceeded.
  Stream<PerformanceAlert> get alertStream => _alertController.stream;

  /// Starts automatic performance reporting and alerting.
  void startReporting({
    Duration snapshotInterval = const Duration(minutes: 1),
    bool enableAlerting = true,
  }) {
    // Subscribe to metrics for alerting
    if (enableAlerting) {
      _metricsSubscription = _monitor.metricsStream.listen(_checkForAlerts);
    }

    // Take periodic snapshots for trend analysis
    Timer.periodic(snapshotInterval, (_) {
      _takeSnapshot();
    });
  }

  /// Stops automatic reporting and alerting.
  void stopReporting() {
    _metricsSubscription?.cancel();
    _metricsSubscription = null;
  }

  /// Generates a comprehensive performance report.
  Future<EnhancedPerformanceReport> generateEnhancedReport({
    Duration? timeRange,
    bool includeComparisons = true,
    bool includeTrendAnalysis = true,
    bool includeBenchmarks = true,
  }) async {
    final baseReport = await _monitor.generateReport(
      timeRange: timeRange,
    );

    final comparisons = includeComparisons ? _generateComparisons() : null;
    final trendAnalysis =
        includeTrendAnalysis ? _generateTrendAnalysis() : null;
    final benchmarkResults =
        includeBenchmarks ? _generateBenchmarkResults() : null;
    final performanceScore = _calculatePerformanceScore(baseReport.metrics);

    return EnhancedPerformanceReport(
      baseReport: baseReport,
      performanceScore: performanceScore,
      comparisons: comparisons,
      trendAnalysis: trendAnalysis,
      benchmarkResults: benchmarkResults,
      generatedAt: DateTime.now(),
    );
  }

  /// Creates a performance snapshot for before/after comparisons.
  PerformanceSnapshot takeSnapshot({String? label}) {
    final snapshot = PerformanceSnapshot(
      label: label ?? 'Snapshot ${_snapshots.length + 1}',
      metrics: _monitor.currentMetrics,
      timestamp: DateTime.now(),
    );

    _snapshots.add(snapshot);

    // Keep only recent snapshots (last 100)
    while (_snapshots.length > 100) {
      _snapshots.removeAt(0);
    }

    return snapshot;
  }

  /// Compares two performance snapshots.
  PerformanceComparison compareSnapshots(
    PerformanceSnapshot before,
    PerformanceSnapshot after,
  ) =>
      PerformanceComparison(
        before: before,
        after: after,
        fpsChange: after.metrics.fps - before.metrics.fps,
        memoryChange: after.metrics.memoryUsage - before.metrics.memoryUsage,
        frameTimeChange:
            after.metrics.averageFrameTime - before.metrics.averageFrameTime,
        rebuildCountChange:
            _calculateRebuildChange(before.metrics, after.metrics),
        improvementSummary:
            _generateImprovementSummary(before.metrics, after.metrics),
      );

  /// Runs a performance benchmark test.
  Future<BenchmarkResult> runBenchmark(PerformanceBenchmark benchmark) async {
    final startTime = DateTime.now();
    final beforeSnapshot = takeSnapshot(label: '${benchmark.name} - Before');

    // Wait for benchmark duration
    await Future<void>.delayed(benchmark.duration);

    final afterSnapshot = takeSnapshot(label: '${benchmark.name} - After');
    final endTime = DateTime.now();

    final result = BenchmarkResult(
      benchmark: benchmark,
      beforeMetrics: beforeSnapshot.metrics,
      afterMetrics: afterSnapshot.metrics,
      duration: endTime.difference(startTime),
      passed: _evaluateBenchmark(benchmark, afterSnapshot.metrics),
      score: _calculateBenchmarkScore(benchmark, afterSnapshot.metrics),
    );

    return result;
  }

  /// Adds a custom benchmark for performance testing.
  void addBenchmark(PerformanceBenchmark benchmark) {
    _benchmarks.add(benchmark);
  }

  /// Exports performance data to JSON format.
  String exportToJson({
    bool includeSnapshots = true,
    bool includeBenchmarks = true,
  }) {
    final data = <String, dynamic>{
      'currentMetrics': _metricsToJson(_monitor.currentMetrics),
      'exportedAt': DateTime.now().toIso8601String(),
    };

    if (includeSnapshots) {
      data['snapshots'] = _snapshots
          .map(
            (s) => {
              'label': s.label,
              'timestamp': s.timestamp.toIso8601String(),
              'metrics': _metricsToJson(s.metrics),
            },
          )
          .toList();
    }

    if (includeBenchmarks) {
      data['benchmarks'] = _benchmarks
          .map(
            (b) => {
              'name': b.name,
              'description': b.description,
              'duration': b.duration.inMilliseconds,
              'expectedFps': b.expectedFps,
              'maxMemoryUsage': b.maxMemoryUsage,
            },
          )
          .toList();
    }

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Saves performance report to file.
  Future<void> saveReportToFile(
    EnhancedPerformanceReport report,
    String filePath,
  ) async {
    final file = File(filePath);
    final content = _generateReportContent(report);
    await file.writeAsString(content);
  }

  void _takeSnapshot() {
    takeSnapshot(label: 'Auto-${DateTime.now().millisecondsSinceEpoch}');
  }

  void _checkForAlerts(PerformanceMetrics metrics) {
    final alerts = <PerformanceAlert>[];

    // Check for critical performance issues
    if (metrics.fps < 30) {
      alerts.add(
        PerformanceAlert(
          type: AlertType.criticalPerformance,
          message: 'Critical FPS drop: ${metrics.fps.toStringAsFixed(1)} FPS',
          severity: AlertSeverity.critical,
          metrics: metrics,
          timestamp: DateTime.now(),
        ),
      );
    }

    // Check for memory issues
    if (metrics.memoryUsage > 500 * 1024 * 1024) {
      // 500MB
      alerts.add(
        PerformanceAlert(
          type: AlertType.memoryWarning,
          message:
              'High memory usage: ${(metrics.memoryUsage / 1024 / 1024).toStringAsFixed(1)}MB',
          severity: AlertSeverity.high,
          metrics: metrics,
          timestamp: DateTime.now(),
        ),
      );
    }

    // Check for excessive rebuilds
    final totalRebuilds = metrics.widgetRebuildCounts.values
        .fold<int>(0, (sum, count) => sum + count);
    if (totalRebuilds > 1000) {
      alerts.add(
        PerformanceAlert(
          type: AlertType.excessiveRebuilds,
          message: 'Excessive widget rebuilds detected: $totalRebuilds total',
          severity: AlertSeverity.medium,
          metrics: metrics,
          timestamp: DateTime.now(),
        ),
      );
    }

    // Emit alerts
    for (final alert in alerts) {
      _alertController.add(alert);
    }
  }

  List<PerformanceComparison>? _generateComparisons() {
    if (_snapshots.length < 2) return null;

    final comparisons = <PerformanceComparison>[];

    // Compare recent snapshots
    for (var i = _snapshots.length - 1; i > 0 && comparisons.length < 5; i--) {
      comparisons.add(compareSnapshots(_snapshots[i - 1], _snapshots[i]));
    }

    return comparisons;
  }

  DetailedTrendAnalysis? _generateTrendAnalysis() {
    if (_snapshots.length < 10) return null;

    final recent = _snapshots.sublist(_snapshots.length - 10);
    final fpsTrend = _calculateTrend(recent.map((s) => s.metrics.fps).toList());
    final memoryTrend =
        _calculateTrend(recent.map((s) => s.metrics.memoryUsage).toList());
    final frameTimeTrend =
        _calculateTrend(recent.map((s) => s.metrics.averageFrameTime).toList());

    return DetailedTrendAnalysis(
      fpsTrend: fpsTrend,
      memoryTrend: memoryTrend,
      frameTimeTrend: frameTimeTrend,
      overallTrend:
          _determineOverallTrend(fpsTrend, memoryTrend, frameTimeTrend),
      timeRange: Duration(
        milliseconds: recent.last.timestamp.millisecondsSinceEpoch -
            recent.first.timestamp.millisecondsSinceEpoch,
      ),
    );
  }

  List<BenchmarkResult>? _generateBenchmarkResults() {
    // This would contain results from previously run benchmarks
    // For now, return null as benchmarks need to be run explicitly
    return null;
  }

  double _calculatePerformanceScore(PerformanceMetrics metrics) {
    var score = 100.0;

    // FPS score (0-40 points)
    final fpsScore = (metrics.fps / 60.0).clamp(0.0, 1.0) * 40;
    score = score - 40 + fpsScore;

    // Memory score (0-30 points)
    final memoryMB = metrics.memoryUsage / (1024 * 1024);
    final memoryScore = (1.0 - (memoryMB / 500).clamp(0.0, 1.0)) * 30;
    score = score - 30 + memoryScore;

    // Frame time score (0-20 points)
    final frameTimeScore =
        (1.0 - (metrics.averageFrameTime / 33.33).clamp(0.0, 1.0)) * 20;
    score = score - 20 + frameTimeScore;

    // Warnings penalty (0-10 points)
    final warningsPenalty = (metrics.warnings.length * 2).clamp(0, 10);
    score = score - warningsPenalty;

    return score.clamp(0.0, 100.0);
  }

  int _calculateRebuildChange(
    PerformanceMetrics before,
    PerformanceMetrics after,
  ) {
    final beforeTotal = before.widgetRebuildCounts.values
        .fold<int>(0, (sum, count) => sum + count);
    final afterTotal = after.widgetRebuildCounts.values
        .fold<int>(0, (sum, count) => sum + count);
    return afterTotal - beforeTotal;
  }

  String _generateImprovementSummary(
    PerformanceMetrics before,
    PerformanceMetrics after,
  ) {
    final improvements = <String>[];
    final regressions = <String>[];

    // FPS comparison
    final fpsChange = after.fps - before.fps;
    if (fpsChange > 1) {
      improvements.add('FPS improved by ${fpsChange.toStringAsFixed(1)}');
    } else if (fpsChange < -1) {
      regressions.add('FPS decreased by ${(-fpsChange).toStringAsFixed(1)}');
    }

    // Memory comparison
    final memoryChange = after.memoryUsage - before.memoryUsage;
    final memoryChangeMB = memoryChange / (1024 * 1024);
    if (memoryChangeMB < -5) {
      improvements.add(
        'Memory usage reduced by ${(-memoryChangeMB).toStringAsFixed(1)}MB',
      );
    } else if (memoryChangeMB > 5) {
      regressions.add(
        'Memory usage increased by ${memoryChangeMB.toStringAsFixed(1)}MB',
      );
    }

    if (improvements.isNotEmpty && regressions.isEmpty) {
      return 'Performance improved: ${improvements.join(', ')}';
    } else if (regressions.isNotEmpty && improvements.isEmpty) {
      return 'Performance regressed: ${regressions.join(', ')}';
    } else if (improvements.isNotEmpty && regressions.isNotEmpty) {
      return 'Mixed results: ${improvements.join(', ')} but ${regressions.join(', ')}';
    } else {
      return 'No significant performance changes detected';
    }
  }

  bool _evaluateBenchmark(
    PerformanceBenchmark benchmark,
    PerformanceMetrics metrics,
  ) {
    if (benchmark.expectedFps != null && metrics.fps < benchmark.expectedFps!) {
      return false;
    }
    if (benchmark.maxMemoryUsage != null &&
        metrics.memoryUsage > benchmark.maxMemoryUsage!) {
      return false;
    }
    return true;
  }

  double _calculateBenchmarkScore(
    PerformanceBenchmark benchmark,
    PerformanceMetrics metrics,
  ) {
    var score = 100.0;

    if (benchmark.expectedFps != null) {
      final fpsRatio = metrics.fps / benchmark.expectedFps!;
      score *= fpsRatio.clamp(0.0, 1.0);
    }

    if (benchmark.maxMemoryUsage != null) {
      final memoryRatio = benchmark.maxMemoryUsage! / metrics.memoryUsage;
      score *= memoryRatio.clamp(0.0, 1.0);
    }

    return score.clamp(0.0, 100.0);
  }

  TrendDirection _calculateTrend(List<double> values) {
    if (values.length < 3) return TrendDirection.stable;

    final firstHalf = values.sublist(0, values.length ~/ 2);
    final secondHalf = values.sublist(values.length ~/ 2);

    final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;

    final changePercent = ((secondAvg - firstAvg) / firstAvg) * 100;

    if (changePercent > 5) return TrendDirection.improving;
    if (changePercent < -5) return TrendDirection.declining;
    return TrendDirection.stable;
  }

  TrendDirection _determineOverallTrend(
    TrendDirection fpsTrend,
    TrendDirection memoryTrend,
    TrendDirection frameTimeTrend,
  ) {
    final trends = [fpsTrend, memoryTrend, frameTimeTrend];
    final improvingCount =
        trends.where((t) => t == TrendDirection.improving).length;
    final decliningCount =
        trends.where((t) => t == TrendDirection.declining).length;

    if (improvingCount > decliningCount) return TrendDirection.improving;
    if (decliningCount > improvingCount) return TrendDirection.declining;
    return TrendDirection.stable;
  }

  Map<String, dynamic> _metricsToJson(PerformanceMetrics metrics) => {
        'frameDrops': metrics.frameDrops,
        'memoryUsage': metrics.memoryUsage,
        'peakMemoryUsage': metrics.peakMemoryUsage,
        'widgetRebuildCounts': metrics.widgetRebuildCounts,
        'averageFrameTime': metrics.averageFrameTime,
        'p95FrameTime': metrics.p95FrameTime,
        'fps': metrics.fps,
        'customMetrics': metrics.customMetrics,
        'timestamp': metrics.timestamp.toIso8601String(),
        'warnings': metrics.warnings
            .map(
              (w) => {
                'type': w.type.toString(),
                'message': w.message,
                'suggestion': w.suggestion,
                'severity': w.severity.toString(),
                'timestamp': w.timestamp.toIso8601String(),
              },
            )
            .toList(),
      };

  String _generateReportContent(EnhancedPerformanceReport report) {
    final buffer = StringBuffer();

    buffer.writeln('# Performance Report');
    buffer.writeln('Generated: ${report.generatedAt}');
    buffer.writeln();

    buffer.writeln('## Summary');
    buffer.writeln(report.baseReport.summary);
    buffer.writeln(
      'Performance Score: ${report.performanceScore.toStringAsFixed(1)}/100',
    );
    buffer.writeln();

    buffer.writeln('## Current Metrics');
    final metrics = report.baseReport.metrics;
    buffer.writeln('- FPS: ${metrics.fps.toStringAsFixed(1)}');
    buffer.writeln(
      '- Average Frame Time: ${metrics.averageFrameTime.toStringAsFixed(2)}ms',
    );
    buffer.writeln(
      '- Memory Usage: ${(metrics.memoryUsage / 1024 / 1024).toStringAsFixed(1)}MB',
    );
    buffer.writeln('- Frame Drops: ${metrics.frameDrops}');
    buffer.writeln();

    if (report.baseReport.issues.isNotEmpty) {
      buffer.writeln('## Issues');
      for (final issue in report.baseReport.issues) {
        buffer.writeln('- **${issue.type}**: ${issue.description}');
        buffer.writeln('  - Impact: ${issue.impact}');
        buffer.writeln('  - Fix: ${issue.suggestedFix}');
      }
      buffer.writeln();
    }

    if (report.baseReport.recommendations.isNotEmpty) {
      buffer.writeln('## Recommendations');
      for (final rec in report.baseReport.recommendations) {
        buffer.writeln('- **${rec.title}** (${rec.priority} priority)');
        buffer.writeln('  - ${rec.description}');
        buffer.writeln('  - Expected: ${rec.expectedImprovement}');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Generates a quick performance summary report.
  String generateQuickSummary() {
    final metrics = _monitor.currentMetrics;
    final score = _calculatePerformanceScore(metrics);

    return 'Performance Score: ${score.toStringAsFixed(1)}/100 | '
        'FPS: ${metrics.fps.toStringAsFixed(1)} | '
        'Memory: ${(metrics.memoryUsage / 1024 / 1024).toStringAsFixed(1)}MB | '
        'Warnings: ${metrics.warnings.length}';
  }

  /// Gets performance statistics over a time period.
  PerformanceStatistics getStatistics({Duration? timeRange}) {
    final relevantSnapshots = timeRange != null
        ? _snapshots
            .where((s) => DateTime.now().difference(s.timestamp) <= timeRange)
            .toList()
        : _snapshots;

    if (relevantSnapshots.isEmpty) {
      return PerformanceStatistics.empty();
    }

    final fpsList = relevantSnapshots.map((s) => s.metrics.fps).toList();
    final memoryList =
        relevantSnapshots.map((s) => s.metrics.memoryUsage).toList();
    final frameTimeList =
        relevantSnapshots.map((s) => s.metrics.averageFrameTime).toList();

    return PerformanceStatistics(
      averageFps: fpsList.reduce((a, b) => a + b) / fpsList.length,
      minFps: fpsList.reduce((a, b) => a < b ? a : b),
      maxFps: fpsList.reduce((a, b) => a > b ? a : b),
      averageMemoryUsage:
          memoryList.reduce((a, b) => a + b) / memoryList.length,
      peakMemoryUsage: memoryList.reduce((a, b) => a > b ? a : b),
      averageFrameTime:
          frameTimeList.reduce((a, b) => a + b) / frameTimeList.length,
      sampleCount: relevantSnapshots.length,
      timeRange: timeRange ??
          Duration(
            milliseconds:
                relevantSnapshots.last.timestamp.millisecondsSinceEpoch -
                    relevantSnapshots.first.timestamp.millisecondsSinceEpoch,
          ),
    );
  }

  /// Clears all collected snapshots and benchmarks.
  void clearHistory() {
    _snapshots.clear();
    _benchmarks.clear();
  }

  /// Gets the number of snapshots currently stored.
  int get snapshotCount => _snapshots.length;

  /// Gets the number of benchmarks currently registered.
  int get benchmarkCount => _benchmarks.length;

  /// Disposes of the reporter and cleans up resources.
  void dispose() {
    stopReporting();
    _alertController.close();
  }
}

/// Enhanced performance report with additional analysis.
class EnhancedPerformanceReport {
  /// Creates a new enhanced performance report.
  const EnhancedPerformanceReport({
    required this.baseReport,
    required this.performanceScore,
    this.comparisons,
    this.trendAnalysis,
    this.benchmarkResults,
    required this.generatedAt,
  });

  /// The base performance report.
  final PerformanceReport baseReport;

  /// Overall performance score (0-100).
  final double performanceScore;

  /// Before/after performance comparisons.
  final List<PerformanceComparison>? comparisons;

  /// Detailed trend analysis over time.
  final DetailedTrendAnalysis? trendAnalysis;

  /// Results from performance benchmarks.
  final List<BenchmarkResult>? benchmarkResults;

  /// When this enhanced report was generated.
  final DateTime generatedAt;
}

/// Performance snapshot for before/after comparisons.
class PerformanceSnapshot {
  /// Creates a new performance snapshot.
  const PerformanceSnapshot({
    required this.label,
    required this.metrics,
    required this.timestamp,
  });

  /// Label for this snapshot.
  final String label;

  /// Performance metrics at the time of snapshot.
  final PerformanceMetrics metrics;

  /// When this snapshot was taken.
  final DateTime timestamp;
}

/// Comparison between two performance snapshots.
class PerformanceComparison {
  /// Creates a new performance comparison.
  const PerformanceComparison({
    required this.before,
    required this.after,
    required this.fpsChange,
    required this.memoryChange,
    required this.frameTimeChange,
    required this.rebuildCountChange,
    required this.improvementSummary,
  });

  /// The before snapshot.
  final PerformanceSnapshot before;

  /// The after snapshot.
  final PerformanceSnapshot after;

  /// Change in FPS.
  final double fpsChange;

  /// Change in memory usage (bytes).
  final double memoryChange;

  /// Change in average frame time (milliseconds).
  final double frameTimeChange;

  /// Change in total widget rebuild count.
  final int rebuildCountChange;

  /// Summary of improvements or regressions.
  final String improvementSummary;

  /// Whether this comparison shows overall improvement.
  bool get isImprovement =>
      fpsChange > 0 && memoryChange < 0 && frameTimeChange < 0;

  /// Whether this comparison shows overall regression.
  bool get isRegression =>
      fpsChange < 0 || memoryChange > 0 || frameTimeChange > 0;
}

/// Detailed trend analysis over time.
class DetailedTrendAnalysis {
  /// Creates a new detailed trend analysis.
  const DetailedTrendAnalysis({
    required this.fpsTrend,
    required this.memoryTrend,
    required this.frameTimeTrend,
    required this.overallTrend,
    required this.timeRange,
  });

  /// FPS trend direction.
  final TrendDirection fpsTrend;

  /// Memory usage trend direction.
  final TrendDirection memoryTrend;

  /// Frame time trend direction.
  final TrendDirection frameTimeTrend;

  /// Overall performance trend.
  final TrendDirection overallTrend;

  /// Time range covered by this analysis.
  final Duration timeRange;
}

/// Performance benchmark definition.
class PerformanceBenchmark {
  /// Creates a new performance benchmark.
  const PerformanceBenchmark({
    required this.name,
    required this.description,
    required this.duration,
    this.expectedFps,
    this.maxMemoryUsage,
  });

  /// Name of the benchmark.
  final String name;

  /// Description of what this benchmark tests.
  final String description;

  /// Duration to run the benchmark.
  final Duration duration;

  /// Expected minimum FPS during the benchmark.
  final double? expectedFps;

  /// Maximum allowed memory usage during the benchmark.
  final double? maxMemoryUsage;
}

/// Result of running a performance benchmark.
class BenchmarkResult {
  /// Creates a new benchmark result.
  const BenchmarkResult({
    required this.benchmark,
    required this.beforeMetrics,
    required this.afterMetrics,
    required this.duration,
    required this.passed,
    required this.score,
  });

  /// The benchmark that was run.
  final PerformanceBenchmark benchmark;

  /// Performance metrics before the benchmark.
  final PerformanceMetrics beforeMetrics;

  /// Performance metrics after the benchmark.
  final PerformanceMetrics afterMetrics;

  /// Actual duration the benchmark ran.
  final Duration duration;

  /// Whether the benchmark passed its criteria.
  final bool passed;

  /// Benchmark score (0-100).
  final double score;
}

/// Performance alert for real-time monitoring.
class PerformanceAlert {
  /// Creates a new performance alert.
  const PerformanceAlert({
    required this.type,
    required this.message,
    required this.severity,
    required this.metrics,
    required this.timestamp,
  });

  /// Type of alert.
  final AlertType type;

  /// Alert message.
  final String message;

  /// Severity level.
  final AlertSeverity severity;

  /// Performance metrics when alert was triggered.
  final PerformanceMetrics metrics;

  /// When the alert was generated.
  final DateTime timestamp;
}

/// Types of performance alerts.
enum AlertType {
  /// Critical performance degradation.
  criticalPerformance,

  /// Memory usage warning.
  memoryWarning,

  /// Excessive widget rebuilds.
  excessiveRebuilds,

  /// Frame rate issues.
  frameRateIssue,

  /// Custom threshold exceeded.
  customThreshold,
}

/// Alert severity levels.
enum AlertSeverity {
  /// Low severity alert.
  low,

  /// Medium severity alert.
  medium,

  /// High severity alert.
  high,

  /// Critical severity alert.
  critical,
}

/// Performance statistics over a time period.
class PerformanceStatistics {
  /// Creates new performance statistics.
  const PerformanceStatistics({
    required this.averageFps,
    required this.minFps,
    required this.maxFps,
    required this.averageMemoryUsage,
    required this.peakMemoryUsage,
    required this.averageFrameTime,
    required this.sampleCount,
    required this.timeRange,
  });

  /// Creates empty statistics when no data is available.
  factory PerformanceStatistics.empty() => const PerformanceStatistics(
        averageFps: 0,
        minFps: 0,
        maxFps: 0,
        averageMemoryUsage: 0,
        peakMemoryUsage: 0,
        averageFrameTime: 0,
        sampleCount: 0,
        timeRange: Duration.zero,
      );

  /// Average FPS over the time period.
  final double averageFps;

  /// Minimum FPS recorded.
  final double minFps;

  /// Maximum FPS recorded.
  final double maxFps;

  /// Average memory usage in bytes.
  final double averageMemoryUsage;

  /// Peak memory usage in bytes.
  final double peakMemoryUsage;

  /// Average frame time in milliseconds.
  final double averageFrameTime;

  /// Number of samples used for these statistics.
  final int sampleCount;

  /// Time range covered by these statistics.
  final Duration timeRange;

  @override
  String toString() => 'PerformanceStatistics('
      'avgFps: ${averageFps.toStringAsFixed(1)}, '
      'memory: ${(averageMemoryUsage / 1024 / 1024).toStringAsFixed(1)}MB, '
      'samples: $sampleCount, '
      'timeRange: ${timeRange.inMinutes}min'
      ')';
}
