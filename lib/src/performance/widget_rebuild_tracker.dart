import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Widget rebuild tracker that provides visual indicators for excessive rebuilds.
///
/// This class tracks widget rebuilds in real-time and provides visual feedback
/// to developers about which widgets are rebuilding frequently.
class WidgetRebuildTracker {

  WidgetRebuildTracker._();
  static WidgetRebuildTracker? _instance;

  /// Gets the singleton instance of the widget rebuild tracker.
  static WidgetRebuildTracker get instance {
    _instance ??= WidgetRebuildTracker._();
    return _instance!;
  }

  final Map<String, RebuildInfo> _rebuildInfo = {};
  final StreamController<RebuildEvent> _rebuildController =
      StreamController<RebuildEvent>.broadcast();

  bool _isTracking = false;
  Timer? _cleanupTimer;

  /// Stream of rebuild events for real-time monitoring.
  Stream<RebuildEvent> get rebuildStream => _rebuildController.stream;

  /// Whether rebuild tracking is currently active.
  bool get isTracking => _isTracking;

  /// Starts tracking widget rebuilds.
  void startTracking() {
    if (_isTracking) return;

    _isTracking = true;

    // Start cleanup timer to remove old rebuild info
    _cleanupTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _cleanupOldRebuildInfo();
    });

    if (kDebugMode) {
      debugPrint('Widget rebuild tracking started');
    }
  }

  /// Stops tracking widget rebuilds.
  void stopTracking() {
    if (!_isTracking) return;

    _isTracking = false;
    _cleanupTimer?.cancel();
    _cleanupTimer = null;

    if (kDebugMode) {
      debugPrint('Widget rebuild tracking stopped');
    }
  }

  /// Records a widget rebuild event.
  void recordRebuild(
    String widgetType, {
    String? widgetKey,
    String? location,
    Duration? buildTime,
  }) {
    if (!_isTracking) return;

    final now = DateTime.now();
    final key = widgetKey ?? widgetType;

    final info = _rebuildInfo[key] ??
        RebuildInfo(
          widgetType: widgetType,
          widgetKey: widgetKey,
          location: location,
        );

    info.recordRebuild(now, buildTime);
    _rebuildInfo[key] = info;

    // Emit rebuild event
    final event = RebuildEvent(
      widgetType: widgetType,
      widgetKey: widgetKey,
      location: location,
      timestamp: now,
      rebuildCount: info.totalRebuilds,
      recentRebuildRate: info.getRecentRebuildRate(),
      averageBuildTime: info.averageBuildTime,
      isExcessive: info.isExcessive,
    );

    _rebuildController.add(event);

    // Log excessive rebuilds
    if (info.isExcessive && kDebugMode) {
      debugPrint('⚠️ Excessive rebuilds detected in $widgetType: '
          '${info.totalRebuilds} total, '
          '${info.getRecentRebuildRate().toStringAsFixed(1)}/sec recent');
    }
  }

  /// Gets rebuild information for a specific widget.
  RebuildInfo? getRebuildInfo(String widgetKey) => _rebuildInfo[widgetKey];

  /// Gets all widgets with excessive rebuilds.
  List<RebuildInfo> getExcessiveRebuilds() => _rebuildInfo.values.where((info) => info.isExcessive).toList();

  /// Gets rebuild statistics for all tracked widgets.
  Map<String, RebuildInfo> getAllRebuildInfo() => Map.from(_rebuildInfo);

  /// Clears all rebuild tracking data.
  void clearData() {
    _rebuildInfo.clear();
  }

  void _cleanupOldRebuildInfo() {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 5));

    _rebuildInfo.removeWhere((key, info) => info.lastRebuildTime.isBefore(cutoff));
  }

  /// Disposes of the tracker and cleans up resources.
  void dispose() {
    stopTracking();
    _rebuildController.close();
    _rebuildInfo.clear();
  }
}

/// Information about widget rebuilds for a specific widget.
class RebuildInfo {
  /// Creates new rebuild information.
  RebuildInfo({
    required this.widgetType,
    this.widgetKey,
    this.location,
  });

  /// The type of widget being tracked.
  final String widgetType;

  /// Optional widget key for identification.
  final String? widgetKey;

  /// Optional location information (file, line number, etc.).
  final String? location;

  /// Total number of rebuilds recorded.
  int totalRebuilds = 0;

  /// Timestamps of recent rebuilds (last 60 seconds).
  final Queue<DateTime> _recentRebuilds = Queue<DateTime>();

  /// Build times for calculating averages.
  final Queue<Duration> _buildTimes = Queue<Duration>();

  /// When this widget was first tracked.
  late DateTime firstRebuildTime = DateTime.now();

  /// When this widget was last rebuilt.
  late DateTime lastRebuildTime = DateTime.now();

  /// Records a rebuild event.
  void recordRebuild(DateTime timestamp, Duration? buildTime) {
    totalRebuilds++;
    lastRebuildTime = timestamp;

    if (totalRebuilds == 1) {
      firstRebuildTime = timestamp;
    }

    // Track recent rebuilds (last 60 seconds)
    _recentRebuilds.add(timestamp);
    final cutoff = timestamp.subtract(const Duration(seconds: 60));
    while (
        _recentRebuilds.isNotEmpty && _recentRebuilds.first.isBefore(cutoff)) {
      _recentRebuilds.removeFirst();
    }

    // Track build times
    if (buildTime != null) {
      _buildTimes.add(buildTime);
      // Keep only recent build times (last 100)
      while (_buildTimes.length > 100) {
        _buildTimes.removeFirst();
      }
    }
  }

  /// Gets the recent rebuild rate (rebuilds per second).
  double getRecentRebuildRate() {
    if (_recentRebuilds.isEmpty) return 0;

    final now = DateTime.now();
    final timeSpan =
        now.difference(_recentRebuilds.first).inMilliseconds / 1000.0;

    return timeSpan > 0 ? _recentRebuilds.length / timeSpan : 0.0;
  }

  /// Gets the average build time.
  Duration? get averageBuildTime {
    if (_buildTimes.isEmpty) return null;

    final totalMicroseconds =
        _buildTimes.map((d) => d.inMicroseconds).reduce((a, b) => a + b);

    return Duration(microseconds: totalMicroseconds ~/ _buildTimes.length);
  }

  /// Whether this widget has excessive rebuilds.
  bool get isExcessive {
    // Consider excessive if:
    // 1. More than 100 total rebuilds, OR
    // 2. More than 5 rebuilds per second recently, OR
    // 3. Average build time > 10ms and more than 20 rebuilds
    return totalRebuilds > 100 ||
        getRecentRebuildRate() > 5.0 ||
        (averageBuildTime != null &&
            averageBuildTime!.inMilliseconds > 10 &&
            totalRebuilds > 20);
  }

  /// Gets the severity level of the rebuild pattern.
  RebuildSeverity get severity {
    final recentRate = getRecentRebuildRate();
    final avgBuildTime = averageBuildTime?.inMilliseconds ?? 0;

    if (totalRebuilds > 1000 || recentRate > 20 || avgBuildTime > 50) {
      return RebuildSeverity.critical;
    } else if (totalRebuilds > 500 || recentRate > 10 || avgBuildTime > 25) {
      return RebuildSeverity.high;
    } else if (totalRebuilds > 100 || recentRate > 5 || avgBuildTime > 10) {
      return RebuildSeverity.medium;
    } else {
      return RebuildSeverity.low;
    }
  }

  @override
  String toString() => 'RebuildInfo('
      'type: $widgetType, '
      'total: $totalRebuilds, '
      'rate: ${getRecentRebuildRate().toStringAsFixed(1)}/sec, '
      'avgBuildTime: ${averageBuildTime?.inMilliseconds ?? 0}ms'
      ')';
}

/// Event emitted when a widget rebuild is recorded.
class RebuildEvent {
  /// Creates a new rebuild event.
  const RebuildEvent({
    required this.widgetType,
    this.widgetKey,
    this.location,
    required this.timestamp,
    required this.rebuildCount,
    required this.recentRebuildRate,
    this.averageBuildTime,
    required this.isExcessive,
  });

  /// The type of widget that was rebuilt.
  final String widgetType;

  /// Optional widget key for identification.
  final String? widgetKey;

  /// Optional location information.
  final String? location;

  /// When the rebuild occurred.
  final DateTime timestamp;

  /// Total rebuild count for this widget.
  final int rebuildCount;

  /// Recent rebuild rate (rebuilds per second).
  final double recentRebuildRate;

  /// Average build time for this widget.
  final Duration? averageBuildTime;

  /// Whether this widget has excessive rebuilds.
  final bool isExcessive;

  @override
  String toString() => 'RebuildEvent('
      'type: $widgetType, '
      'count: $rebuildCount, '
      'rate: ${recentRebuildRate.toStringAsFixed(1)}/sec, '
      'excessive: $isExcessive'
      ')';
}

/// Severity levels for widget rebuild patterns.
enum RebuildSeverity {
  /// Low severity - normal rebuild pattern.
  low,

  /// Medium severity - elevated rebuild activity.
  medium,

  /// High severity - concerning rebuild pattern.
  high,

  /// Critical severity - severe rebuild issues.
  critical,
}

/// Widget that provides visual indicators for rebuild tracking.
class RebuildIndicator extends StatefulWidget {
  /// Creates a rebuild indicator widget.
  const RebuildIndicator({
    super.key,
    required this.child,
    this.showIndicator = true,
    this.indicatorPosition = RebuildIndicatorPosition.topRight,
  });

  /// The child widget to wrap with rebuild tracking.
  final Widget child;

  /// Whether to show the visual rebuild indicator.
  final bool showIndicator;

  /// Position of the rebuild indicator.
  final RebuildIndicatorPosition indicatorPosition;

  @override
  State<RebuildIndicator> createState() => _RebuildIndicatorState();
}

class _RebuildIndicatorState extends State<RebuildIndicator> {
  RebuildInfo? _rebuildInfo;
  StreamSubscription<RebuildEvent>? _subscription;

  @override
  void initState() {
    super.initState();

    if (kDebugMode && widget.showIndicator) {
      _subscription = WidgetRebuildTracker.instance.rebuildStream
          .where((event) => event.widgetType == widget.runtimeType.toString())
          .listen((event) {
        if (mounted) {
          setState(() {
            _rebuildInfo = WidgetRebuildTracker.instance
                .getRebuildInfo(event.widgetKey ?? event.widgetType);
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Record this rebuild
    if (kDebugMode) {
      WidgetRebuildTracker.instance.recordRebuild(
        widget.runtimeType.toString(),
        widgetKey: widget.key?.toString(),
      );
    }

    if (!widget.showIndicator || !kDebugMode || _rebuildInfo == null) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        _buildIndicator(),
      ],
    );
  }

  Widget _buildIndicator() {
    final info = _rebuildInfo!;
    final severity = info.severity;

    Color indicatorColor;
    switch (severity) {
      case RebuildSeverity.low:
        indicatorColor = Colors.green;
        break;
      case RebuildSeverity.medium:
        indicatorColor = Colors.orange;
        break;
      case RebuildSeverity.high:
        indicatorColor = Colors.red;
        break;
      case RebuildSeverity.critical:
        indicatorColor = Colors.purple;
        break;
    }

    final Widget indicator = Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: indicatorColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${info.totalRebuilds}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    // Position the indicator
    switch (widget.indicatorPosition) {
      case RebuildIndicatorPosition.topLeft:
        return Positioned(
          top: 0,
          left: 0,
          child: indicator,
        );
      case RebuildIndicatorPosition.topRight:
        return Positioned(
          top: 0,
          right: 0,
          child: indicator,
        );
      case RebuildIndicatorPosition.bottomLeft:
        return Positioned(
          bottom: 0,
          left: 0,
          child: indicator,
        );
      case RebuildIndicatorPosition.bottomRight:
        return Positioned(
          bottom: 0,
          right: 0,
          child: indicator,
        );
    }
  }
}

/// Position options for the rebuild indicator.
enum RebuildIndicatorPosition {
  /// Top-left corner.
  topLeft,

  /// Top-right corner.
  topRight,

  /// Bottom-left corner.
  bottomLeft,

  /// Bottom-right corner.
  bottomRight,
}
