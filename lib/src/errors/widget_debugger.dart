import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'platform_issue_detector.dart' show IssueSeverity;

/// Visual widget debugging tools for enhanced development experience.
class WidgetDebugger {
  static bool _isEnabled = kDebugMode;
  static final Map<String, WidgetInspectionData> _inspectionCache = {};

  /// Enables or disables widget debugging.
  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Checks if widget debugging is currently enabled.
  static bool get isEnabled => _isEnabled;

  /// Inspects a widget and returns detailed debugging information.
  static WidgetInspectionData inspectWidget(Widget widget) {
    if (!_isEnabled) {
      return WidgetInspectionData.empty();
    }

    final key = widget.runtimeType.toString();
    if (_inspectionCache.containsKey(key)) {
      return _inspectionCache[key]!;
    }

    final data = _performWidgetInspection(widget);
    _inspectionCache[key] = data;
    return data;
  }

  /// Analyzes the widget tree for common issues.
  static List<WidgetIssue> analyzeWidgetTree(Widget root) {
    if (!_isEnabled) return [];

    final issues = <WidgetIssue>[];
    _analyzeWidgetRecursively(root, issues, 0);
    return issues;
  }

  /// Highlights performance issues in the widget tree.
  static List<PerformanceIssue> findPerformanceIssues(Widget root) {
    if (!_isEnabled) return [];

    final issues = <PerformanceIssue>[];
    _findPerformanceIssuesRecursively(root, issues);
    return issues;
  }

  /// Creates a visual overlay showing widget boundaries and information.
  static Widget createDebugOverlay(Widget child) {
    if (!_isEnabled) return child;

    return DebugWidgetOverlay(child: child);
  }

  /// Logs detailed widget tree information.
  static void logWidgetTree(Widget root, {int maxDepth = 10}) {
    if (!_isEnabled) return;

    developer.log('=== Widget Tree Analysis ===');
    _logWidgetRecursively(root, 0, maxDepth);
    developer.log('===========================');
  }

  /// Captures a snapshot of the current widget state for debugging.
  static WidgetSnapshot captureSnapshot(BuildContext context) {
    if (!_isEnabled) {
      return WidgetSnapshot.empty();
    }

    return WidgetSnapshot(
      timestamp: DateTime.now(),
      widgetType: context.widget.runtimeType.toString(),
      renderObject: context.findRenderObject(),
      size: context.size,
      constraints: _getConstraints(context),
      properties: _extractWidgetProperties(context.widget),
    );
  }

  static WidgetInspectionData _performWidgetInspection(Widget widget) => WidgetInspectionData(
      widgetType: widget.runtimeType.toString(),
      key: widget.key?.toString(),
      properties: _extractWidgetProperties(widget),
      memoryFootprint: _estimateMemoryFootprint(widget),
      buildComplexity: _calculateBuildComplexity(widget),
      recommendations: _generateRecommendations(widget),
    );

  static void _analyzeWidgetRecursively(
    Widget widget,
    List<WidgetIssue> issues,
    int depth,
  ) {
    // Check for excessive nesting
    if (depth > 20) {
      issues.add(WidgetIssue(
        type: WidgetIssueType.excessiveNesting,
        widget: widget.runtimeType.toString(),
        message: 'Widget tree is deeply nested (depth: $depth)',
        severity: IssueSeverity.warning,
        suggestion:
            'Consider breaking down complex widgets into smaller components',
      ),);
    }

    // Check for missing keys in lists
    if (widget is ListView || widget is Column || widget is Row) {
      issues.add(WidgetIssue(
        type: WidgetIssueType.missingKeys,
        widget: widget.runtimeType.toString(),
        message: 'List widget children should have keys for better performance',
        severity: IssueSeverity.info,
        suggestion: 'Add Key objects to list children for efficient updates',
      ),);
    }

    // Check for non-const constructors
    if (!_isConstWidget(widget)) {
      issues.add(WidgetIssue(
        type: WidgetIssueType.nonConstConstructor,
        widget: widget.runtimeType.toString(),
        message: 'Widget could be const for better performance',
        severity: IssueSeverity.info,
        suggestion:
            'Use const constructor when widget properties are compile-time constants',
      ),);
    }
  }

  static void _findPerformanceIssuesRecursively(
    Widget widget,
    List<PerformanceIssue> issues,
  ) {
    // Check for expensive operations in build methods
    if (widget is StatefulWidget) {
      issues.add(PerformanceIssue(
        type: PerformanceIssueType.expensiveBuild,
        widget: widget.runtimeType.toString(),
        message: 'StatefulWidget may have expensive build operations',
        impact: PerformanceImpact.medium,
        suggestion: 'Move expensive operations to initState or use memoization',
      ),);
    }

    // Check for potential memory leaks
    if (widget.toString().contains('Stream') ||
        widget.toString().contains('Animation')) {
      issues.add(PerformanceIssue(
        type: PerformanceIssueType.memoryLeak,
        widget: widget.runtimeType.toString(),
        message: 'Widget may have stream or animation that needs disposal',
        impact: PerformanceImpact.high,
        suggestion:
            'Ensure streams and animations are properly disposed in dispose()',
      ),);
    }
  }

  static void _logWidgetRecursively(Widget widget, int depth, int maxDepth) {
    if (depth >= maxDepth) return;

    final indent = '  ' * depth;
    final widgetInfo =
        '${widget.runtimeType}${widget.key != null ? ' (${widget.key})' : ''}';
    developer.log('$indent$widgetInfo');
  }

  static Map<String, dynamic> _extractWidgetProperties(Widget widget) {
    final properties = <String, dynamic>{};

    if (widget is Container) {
      properties['margin'] = widget.margin?.toString();
      properties['padding'] = widget.padding?.toString();
      properties['color'] = widget.color?.toString();
    } else if (widget is Text) {
      properties['data'] = widget.data;
      properties['style'] = widget.style?.toString();
    } else if (widget is Icon) {
      properties['icon'] = widget.icon?.toString();
      properties['color'] = widget.color?.toString();
      properties['size'] = widget.size;
    }

    return properties;
  }

  static int _estimateMemoryFootprint(Widget widget) {
    // Simplified memory estimation based on widget type
    if (widget is Image) return 1000; // Images are memory-heavy
    if (widget is ListView) return 500; // Lists can be memory-intensive
    if (widget is Container) return 100;
    if (widget is Text) return 50;
    return 25; // Base widget memory
  }

  static int _calculateBuildComplexity(Widget widget) {
    // Simplified complexity calculation
    var complexity = 1;

    if (widget is StatefulWidget) complexity += 2;
    if (widget is AnimatedWidget) complexity += 3;
    if (widget is CustomPaint) complexity += 4;

    return complexity;
  }

  static List<String> _generateRecommendations(Widget widget) {
    final recommendations = <String>[];

    if (!_isConstWidget(widget)) {
      recommendations
          .add('Consider using const constructor for better performance');
    }

    if (widget is Container && _hasUnnecessaryContainer(widget)) {
      recommendations.add(
          'Container might be unnecessary - consider using simpler widgets',);
    }

    return recommendations;
  }

  static bool _isConstWidget(Widget widget) {
    // Simplified check - in real implementation, this would use reflection
    return widget.toString().startsWith('const ');
  }

  static bool _hasUnnecessaryContainer(Container container) {
    // Check if Container has minimal properties and could be replaced
    return container.child != null &&
        container.decoration == null &&
        container.margin == null &&
        container.padding == null &&
        container.color == null;
  }

  static BoxConstraints? _getConstraints(BuildContext context) {
    final renderObject = context.findRenderObject();
    if (renderObject is RenderBox) {
      return renderObject.constraints;
    }
    return null;
  }
}

/// Data structure containing widget inspection information.
class WidgetInspectionData {

  /// Creates widget inspection data.
  const WidgetInspectionData({
    required this.widgetType,
    this.key,
    required this.properties,
    required this.memoryFootprint,
    required this.buildComplexity,
    required this.recommendations,
  });

  /// Creates empty inspection data.
  factory WidgetInspectionData.empty() => const WidgetInspectionData(
      widgetType: 'Unknown',
      properties: {},
      memoryFootprint: 0,
      buildComplexity: 0,
      recommendations: [],
    );
  /// The type of the widget.
  final String widgetType;

  /// The widget's key, if any.
  final String? key;

  /// Properties of the widget.
  final Map<String, dynamic> properties;

  /// Estimated memory footprint in bytes.
  final int memoryFootprint;

  /// Build complexity score.
  final int buildComplexity;

  /// Performance recommendations.
  final List<String> recommendations;
}

/// Represents an issue found in the widget tree.
class WidgetIssue {

  /// Creates a widget issue.
  const WidgetIssue({
    required this.type,
    required this.widget,
    required this.message,
    required this.severity,
    required this.suggestion,
  });
  /// The type of issue.
  final WidgetIssueType type;

  /// The widget where the issue was found.
  final String widget;

  /// Description of the issue.
  final String message;

  /// Severity of the issue.
  final IssueSeverity severity;

  /// Suggested fix for the issue.
  final String suggestion;
}

/// Types of widget issues that can be detected.
enum WidgetIssueType {
  /// Widget tree is too deeply nested.
  excessiveNesting,

  /// List widgets missing keys.
  missingKeys,

  /// Widget could use const constructor.
  nonConstConstructor,

  /// Unnecessary widget wrapper.
  unnecessaryWrapper,

  /// Widget has accessibility issues.
  accessibility,
}

/// Represents a performance issue in the widget tree.
class PerformanceIssue {

  /// Creates a performance issue.
  const PerformanceIssue({
    required this.type,
    required this.widget,
    required this.message,
    required this.impact,
    required this.suggestion,
  });
  /// The type of performance issue.
  final PerformanceIssueType type;

  /// The widget with the performance issue.
  final String widget;

  /// Description of the performance issue.
  final String message;

  /// Impact level of the issue.
  final PerformanceImpact impact;

  /// Suggested optimization.
  final String suggestion;
}

/// Types of performance issues.
enum PerformanceIssueType {
  /// Expensive operations in build method.
  expensiveBuild,

  /// Potential memory leak.
  memoryLeak,

  /// Excessive widget rebuilds.
  excessiveRebuilds,

  /// Inefficient list rendering.
  inefficientList,
}

/// Impact levels for performance issues.
enum PerformanceImpact {
  /// Low impact on performance.
  low,

  /// Medium impact on performance.
  medium,

  /// High impact on performance.
  high,

  /// Critical performance impact.
  critical,
}

/// Snapshot of widget state for debugging.
class WidgetSnapshot {

  /// Creates a widget snapshot.
  const WidgetSnapshot({
    required this.timestamp,
    required this.widgetType,
    this.renderObject,
    this.size,
    this.constraints,
    required this.properties,
  });

  /// Creates an empty snapshot.
  factory WidgetSnapshot.empty() => WidgetSnapshot(
      timestamp: DateTime.now(),
      widgetType: 'Unknown',
      properties: const {},
    );
  /// When the snapshot was taken.
  final DateTime timestamp;

  /// Type of the widget.
  final String widgetType;

  /// The render object, if available.
  final RenderObject? renderObject;

  /// Size of the widget.
  final Size? size;

  /// Layout constraints.
  final BoxConstraints? constraints;

  /// Widget properties at snapshot time.
  final Map<String, dynamic> properties;
}

/// Visual overlay for debugging widgets.
class DebugWidgetOverlay extends StatelessWidget {

  /// Creates a debug widget overlay.
  const DebugWidgetOverlay({
    super.key,
    required this.child,
  });
  /// The child widget to overlay.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!WidgetDebugger.isEnabled) {
      return child;
    }

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: DebugOverlayPainter(),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter for debug overlay.
class DebugOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw widget boundaries
    canvas.drawRect(Offset.zero & size, paint);

    // Draw center lines
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
