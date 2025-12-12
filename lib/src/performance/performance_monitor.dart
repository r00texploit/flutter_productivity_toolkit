import 'dart:async';

/// Real-time performance monitoring system for Flutter applications.
///
/// Tracks widget rebuilds, memory usage, frame drops, and provides
/// actionable recommendations for performance optimization.
abstract class PerformanceMonitor {
  /// Starts performance monitoring.
  ///
  /// Should be called early in the application lifecycle to begin
  /// collecting performance metrics.
  void startMonitoring();

  /// Stops performance monitoring and cleans up resources.
  void stopMonitoring();

  /// Whether monitoring is currently active.
  bool get isMonitoring;

  /// Stream of real-time performance metrics.
  ///
  /// Emits updated metrics at regular intervals while monitoring is active.
  Stream<PerformanceMetrics> get metricsStream;

  /// Reports a custom performance metric.
  ///
  /// Allows applications to track custom performance indicators
  /// alongside the built-in metrics.
  void reportCustomMetric(String name, double value, {String? unit});

  /// Gets the current performance metrics snapshot.
  PerformanceMetrics get currentMetrics;

  /// Generates a performance report with recommendations.
  ///
  /// Analyzes collected metrics and provides actionable suggestions
  /// for improving application performance.
  Future<PerformanceReport> generateReport({
    Duration? timeRange,
    bool includeRecommendations = true,
  });

  /// Sets performance thresholds for automatic warnings.
  ///
  /// When metrics exceed these thresholds, warnings will be generated
  /// and included in the metrics stream.
  void setThresholds(PerformanceThresholds thresholds);

  /// Clears all collected performance data.
  void clearMetrics();
}

/// Comprehensive performance metrics collected by the monitor.
class PerformanceMetrics {
  /// Number of frame drops in the current monitoring period.
  final int frameDrops;

  /// Current memory usage in bytes.
  final double memoryUsage;

  /// Peak memory usage during the monitoring period.
  final double peakMemoryUsage;

  /// Widget rebuild counts by widget type.
  final Map<String, int> widgetRebuildCounts;

  /// Average frame render time in milliseconds.
  final double averageFrameTime;

  /// 95th percentile frame render time in milliseconds.
  final double p95FrameTime;

  /// Current frames per second.
  final double fps;

  /// List of performance warnings and recommendations.
  final List<PerformanceWarning> warnings;

  /// Custom metrics reported by the application.
  final Map<String, double> customMetrics;

  /// When these metrics were collected.
  final DateTime timestamp;

  /// Creates a new performance metrics snapshot.
  const PerformanceMetrics({
    required this.frameDrops,
    required this.memoryUsage,
    required this.peakMemoryUsage,
    required this.widgetRebuildCounts,
    required this.averageFrameTime,
    required this.p95FrameTime,
    required this.fps,
    required this.warnings,
    required this.customMetrics,
    required this.timestamp,
  });

  /// Whether the current metrics indicate good performance.
  bool get isPerformanceGood =>
      frameDrops == 0 &&
      fps >= 55.0 &&
      averageFrameTime <= 16.67 &&
      warnings.isEmpty;

  @override
  String toString() =>
      'PerformanceMetrics('
      'fps: ${fps.toStringAsFixed(1)}, '
      'frameDrops: $frameDrops, '
      'memory: ${(memoryUsage / 1024 / 1024).toStringAsFixed(1)}MB, '
      'warnings: ${warnings.length}'
      ')';
}

/// Performance data for individual widgets.
class WidgetPerformanceData {
  /// The widget type name.
  final String widgetType;

  /// Number of times this widget has been rebuilt.
  final int rebuildCount;

  /// Average time taken to build this widget.
  final Duration averageBuildTime;

  /// Estimated memory footprint of this widget.
  final double memoryFootprint;

  /// Whether this widget is causing performance issues.
  final bool isProblematic;

  /// Creates new widget performance data.
  const WidgetPerformanceData({
    required this.widgetType,
    required this.rebuildCount,
    required this.averageBuildTime,
    required this.memoryFootprint,
    required this.isProblematic,
  });

  @override
  String toString() =>
      'WidgetPerformanceData('
      'type: $widgetType, '
      'rebuilds: $rebuildCount, '
      'avgBuildTime: ${averageBuildTime.inMicroseconds}μs'
      ')';
}

/// Performance warning with actionable recommendations.
class PerformanceWarning {
  /// The type of performance issue detected.
  final WarningType type;

  /// Human-readable description of the issue.
  final String message;

  /// Specific suggestion for resolving the issue.
  final String? suggestion;

  /// Location in the widget tree where the issue was detected.
  final WidgetLocation? location;

  /// Severity level of the warning.
  final WarningSeverity severity;

  /// When this warning was generated.
  final DateTime timestamp;

  /// Creates a new performance warning.
  const PerformanceWarning({
    required this.type,
    required this.message,
    this.suggestion,
    this.location,
    required this.severity,
    required this.timestamp,
  });

  @override
  String toString() =>
      'PerformanceWarning('
      'type: $type, '
      'severity: $severity, '
      'message: $message'
      ')';
}

/// Types of performance warnings that can be detected.
enum WarningType {
  /// Excessive widget rebuilds detected.
  excessiveRebuilds,

  /// Memory leak or high memory usage detected.
  memoryLeak,

  /// Frame drops or slow rendering detected.
  frameDrops,

  /// Inefficient widget usage detected.
  inefficientWidget,

  /// Large widget tree detected.
  largeWidgetTree,

  /// Synchronous operations on main thread detected.
  blockingOperation,

  /// Custom performance threshold exceeded.
  customThreshold,
}

/// Severity levels for performance warnings.
enum WarningSeverity {
  /// Low severity - minor performance impact.
  low,

  /// Medium severity - noticeable performance impact.
  medium,

  /// High severity - significant performance impact.
  high,

  /// Critical severity - severe performance impact.
  critical,
}

/// Location information for performance issues in the widget tree.
class WidgetLocation {
  /// The widget type at this location.
  final String widgetType;

  /// Path to this widget in the widget tree.
  final List<String> path;

  /// Line number in source code if available.
  final int? lineNumber;

  /// Source file if available.
  final String? sourceFile;

  /// Creates a new widget location.
  const WidgetLocation({
    required this.widgetType,
    required this.path,
    this.lineNumber,
    this.sourceFile,
  });

  @override
  String toString() =>
      'WidgetLocation('
      'type: $widgetType, '
      'path: ${path.join(' > ')}'
      '${sourceFile != null ? ', file: $sourceFile' : ''}'
      '${lineNumber != null ? ':$lineNumber' : ''}'
      ')';
}

/// Configurable thresholds for performance warnings.
class PerformanceThresholds {
  /// Maximum acceptable frame drops per second.
  final int maxFrameDropsPerSecond;

  /// Maximum acceptable memory usage in bytes.
  final double maxMemoryUsage;

  /// Maximum acceptable widget rebuild count per widget.
  final int maxWidgetRebuilds;

  /// Minimum acceptable frames per second.
  final double minFps;

  /// Maximum acceptable frame render time in milliseconds.
  final double maxFrameTime;

  /// Creates new performance thresholds.
  const PerformanceThresholds({
    this.maxFrameDropsPerSecond = 5,
    this.maxMemoryUsage = 512 * 1024 * 1024, // 512MB
    this.maxWidgetRebuilds = 100,
    this.minFps = 55.0,
    this.maxFrameTime = 16.67, // ~60fps
  });
}

/// Comprehensive performance report with analysis and recommendations.
class PerformanceReport {
  /// Summary of overall performance during the reporting period.
  final String summary;

  /// Detailed performance metrics.
  final PerformanceMetrics metrics;

  /// List of identified performance issues.
  final List<PerformanceIssue> issues;

  /// Actionable recommendations for improvement.
  final List<PerformanceRecommendation> recommendations;

  /// Performance trend analysis if historical data is available.
  final PerformanceTrend? trend;

  /// When this report was generated.
  final DateTime generatedAt;

  /// Time range covered by this report.
  final Duration timeRange;

  /// Creates a new performance report.
  const PerformanceReport({
    required this.summary,
    required this.metrics,
    required this.issues,
    required this.recommendations,
    this.trend,
    required this.generatedAt,
    required this.timeRange,
  });
}

/// Detailed performance issue with context and impact analysis.
class PerformanceIssue {
  /// Type of performance issue.
  final WarningType type;

  /// Detailed description of the issue.
  final String description;

  /// Estimated impact on user experience.
  final ImpactLevel impact;

  /// Specific location where the issue occurs.
  final WidgetLocation? location;

  /// Suggested fix for the issue.
  final String suggestedFix;

  /// Creates a new performance issue.
  const PerformanceIssue({
    required this.type,
    required this.description,
    required this.impact,
    this.location,
    required this.suggestedFix,
  });
}

/// Actionable recommendation for performance improvement.
class PerformanceRecommendation {
  /// Title of the recommendation.
  final String title;

  /// Detailed explanation of the recommendation.
  final String description;

  /// Expected performance improvement if implemented.
  final String expectedImprovement;

  /// Implementation difficulty level.
  final DifficultyLevel difficulty;

  /// Priority level for this recommendation.
  final PriorityLevel priority;

  /// Creates a new performance recommendation.
  const PerformanceRecommendation({
    required this.title,
    required this.description,
    required this.expectedImprovement,
    required this.difficulty,
    required this.priority,
  });
}

/// Performance trend analysis over time.
class PerformanceTrend {
  /// Whether performance is improving, declining, or stable.
  final TrendDirection direction;

  /// Percentage change in overall performance.
  final double percentageChange;

  /// Key metrics that are trending positively.
  final List<String> improvingMetrics;

  /// Key metrics that are trending negatively.
  final List<String> decliningMetrics;

  /// Creates a new performance trend analysis.
  const PerformanceTrend({
    required this.direction,
    required this.percentageChange,
    required this.improvingMetrics,
    required this.decliningMetrics,
  });
}

/// Impact levels for performance issues.
enum ImpactLevel {
  /// Minimal impact on user experience.
  minimal,

  /// Minor impact on user experience.
  minor,

  /// Moderate impact on user experience.
  moderate,

  /// Major impact on user experience.
  major,

  /// Severe impact on user experience.
  severe,
}

/// Difficulty levels for implementing recommendations.
enum DifficultyLevel {
  /// Easy to implement, minimal code changes.
  easy,

  /// Moderate difficulty, some refactoring required.
  moderate,

  /// Hard to implement, significant changes required.
  hard,

  /// Very hard, major architectural changes required.
  veryHard,
}

/// Priority levels for recommendations.
enum PriorityLevel {
  /// Low priority, can be addressed later.
  low,

  /// Medium priority, should be addressed soon.
  medium,

  /// High priority, should be addressed quickly.
  high,

  /// Critical priority, should be addressed immediately.
  critical,
}

/// Performance trend directions.
enum TrendDirection {
  /// Performance is improving over time.
  improving,

  /// Performance is stable over time.
  stable,

  /// Performance is declining over time.
  declining,
}
