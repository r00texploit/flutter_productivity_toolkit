import 'flutter_performance_monitor.dart';
import 'performance_monitor.dart';
import 'performance_reporter.dart';

/// Factory class for creating and managing performance monitoring components.
///
/// Provides a unified API for accessing performance monitoring, reporting,
/// and benchmarking functionality.
class PerformanceToolkit {
  static PerformanceMonitor? _monitor;
  static PerformanceReporter? _reporter;

  /// Gets the singleton performance monitor instance.
  static PerformanceMonitor get monitor {
    _monitor ??= FlutterPerformanceMonitor();
    return _monitor!;
  }

  /// Gets the performance reporter instance.
  static PerformanceReporter get reporter {
    _reporter ??= PerformanceReporter(monitor);
    return _reporter!;
  }

  /// Initializes the performance toolkit with custom configuration.
  static void initialize({
    PerformanceThresholds? thresholds,
    bool autoStartMonitoring = true,
    bool enableReporting = true,
  }) {
    if (thresholds != null) {
      monitor.setThresholds(thresholds);
    }

    if (autoStartMonitoring) {
      monitor.startMonitoring();
    }

    if (enableReporting) {
      reporter.startReporting();
    }
  }

  /// Disposes of all performance monitoring resources.
  static void dispose() {
    _reporter?.dispose();
    if (_monitor is FlutterPerformanceMonitor) {
      (_monitor! as FlutterPerformanceMonitor).dispose();
    }
    _monitor = null;
    _reporter = null;
  }

  /// Creates a performance benchmark for testing.
  static PerformanceBenchmark createBenchmark({
    required String name,
    required String description,
    Duration duration = const Duration(seconds: 30),
    double? expectedFps,
    double? maxMemoryUsage,
  }) => PerformanceBenchmark(
      name: name,
      description: description,
      duration: duration,
      expectedFps: expectedFps,
      maxMemoryUsage: maxMemoryUsage,
    );

  /// Quick performance check that returns a simple health status.
  static PerformanceHealth checkHealth() {
    final metrics = monitor.currentMetrics;

    HealthStatus status;
    final issues = <String>[];

    if (metrics.fps < 30) {
      status = HealthStatus.critical;
      issues.add('Critical FPS: ${metrics.fps.toStringAsFixed(1)}');
    } else if (metrics.fps < 50) {
      status = HealthStatus.warning;
      issues.add('Low FPS: ${metrics.fps.toStringAsFixed(1)}');
    } else if (metrics.memoryUsage > 400 * 1024 * 1024) {
      status = HealthStatus.warning;
      issues.add(
          'High memory usage: ${(metrics.memoryUsage / 1024 / 1024).toStringAsFixed(1)}MB',);
    } else if (metrics.warnings.isNotEmpty) {
      status = HealthStatus.warning;
      issues.add('${metrics.warnings.length} performance warnings');
    } else {
      status = HealthStatus.good;
    }

    return PerformanceHealth(
      status: status,
      fps: metrics.fps,
      memoryUsageMB: metrics.memoryUsage / (1024 * 1024),
      issues: issues,
      timestamp: DateTime.now(),
    );
  }

  /// Generates a comprehensive performance report.
  static Future<EnhancedPerformanceReport> generateReport({
    Duration? timeRange,
    bool includeComparisons = true,
    bool includeTrendAnalysis = true,
    bool includeBenchmarks = true,
  }) => reporter.generateEnhancedReport(
      timeRange: timeRange,
      includeComparisons: includeComparisons,
      includeTrendAnalysis: includeTrendAnalysis,
      includeBenchmarks: includeBenchmarks,
    );

  /// Takes a performance snapshot for comparison purposes.
  static PerformanceSnapshot takeSnapshot({String? label}) => reporter.takeSnapshot(label: label);

  /// Gets performance statistics over a time period.
  static PerformanceStatistics getStatistics({Duration? timeRange}) => reporter.getStatistics(timeRange: timeRange);

  /// Runs a performance benchmark test.
  static Future<BenchmarkResult> runBenchmark(PerformanceBenchmark benchmark) => reporter.runBenchmark(benchmark);
}

/// Simple performance health status.
class PerformanceHealth {

  /// Creates a new performance health status.
  const PerformanceHealth({
    required this.status,
    required this.fps,
    required this.memoryUsageMB,
    required this.issues,
    required this.timestamp,
  });
  /// Overall health status.
  final HealthStatus status;

  /// Current FPS.
  final double fps;

  /// Current memory usage in MB.
  final double memoryUsageMB;

  /// List of current issues.
  final List<String> issues;

  /// When this health check was performed.
  final DateTime timestamp;

  /// Whether the performance is considered healthy.
  bool get isHealthy => status == HealthStatus.good;

  @override
  String toString() => 'PerformanceHealth('
        'status: $status, '
        'fps: ${fps.toStringAsFixed(1)}, '
        'memory: ${memoryUsageMB.toStringAsFixed(1)}MB'
        '${issues.isNotEmpty ? ', issues: ${issues.length}' : ''}'
        ')';
}

/// Health status levels.
enum HealthStatus {
  /// Performance is good.
  good,

  /// Performance has warnings.
  warning,

  /// Performance is critical.
  critical,
}
