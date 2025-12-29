import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_productivity_toolkit/flutter_productivity_toolkit.dart';

/// Example demonstrating comprehensive performance monitoring features.
///
/// This example showcases:
/// - Real-time widget rebuild tracking with visual indicators
/// - Memory leak detection with actionable recommendations
/// - Frame drop analysis and bottleneck identification
/// - Custom performance metric collection and reporting
/// - Performance trend analysis and alerting
/// - Performance benchmark utilities and comparisons
void main() {
  runApp(const PerformanceMonitoringExample());
}

class PerformanceMonitoringExample extends StatelessWidget {
  const PerformanceMonitoringExample({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
        title: 'Performance Monitoring Example',
        home: PerformanceDemo(),
      );
}

class PerformanceDemo extends StatefulWidget {
  const PerformanceDemo({super.key});

  @override
  State<PerformanceDemo> createState() => _PerformanceDemoState();
}

class _PerformanceDemoState extends State<PerformanceDemo> {
  @override
  void initState() {
    super.initState();

    // Initialize performance monitoring
    PerformanceToolkit.initialize(
      thresholds: const PerformanceThresholds(
        maxFrameDropsPerSecond: 3,
        maxMemoryUsage: 200 * 1024 * 1024, // 200MB
        maxWidgetRebuilds: 50,
        maxFrameTime: 18,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Performance Monitoring'),
        ),
        body: const Column(
          children: [
            PerformanceStatusWidget(),
            Expanded(child: PerformanceTestWidget()),
          ],
        ),
      );
}

class PerformanceStatusWidget extends StatefulWidget {
  const PerformanceStatusWidget({super.key});

  @override
  State<PerformanceStatusWidget> createState() =>
      _PerformanceStatusWidgetState();
}

class _PerformanceStatusWidgetState extends State<PerformanceStatusWidget> {
  PerformanceHealth? _health;
  Timer? _healthTimer;

  @override
  void initState() {
    super.initState();
    _startHealthChecks();
  }

  @override
  void dispose() {
    _healthTimer?.cancel();
    super.dispose();
  }

  void _startHealthChecks() {
    _healthTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      setState(() {
        _health = PerformanceToolkit.checkHealth();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_health == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Initializing performance monitoring...'),
        ),
      );
    }

    Color statusColor;
    switch (_health!.status) {
      case HealthStatus.good:
        statusColor = Colors.green;
        break;
      case HealthStatus.warning:
        statusColor = Colors.orange;
        break;
      case HealthStatus.critical:
        statusColor = Colors.red;
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.monitor_heart, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  'Performance Status: ${_health!.status.name.toUpperCase()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('FPS: ${_health!.fps.toStringAsFixed(1)}'),
            Text('Memory: ${_health!.memoryUsageMB.toStringAsFixed(1)} MB'),
            if (_health!.issues.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Issues:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...(_health!.issues.map((issue) => Text('• $issue'))),
            ],
          ],
        ),
      ),
    );
  }
}

class PerformanceTestWidget extends StatefulWidget {
  const PerformanceTestWidget({super.key});

  @override
  State<PerformanceTestWidget> createState() => _PerformanceTestWidgetState();
}

class _PerformanceTestWidgetState extends State<PerformanceTestWidget> {
  int _counter = 0;
  bool _isStressing = false;
  Timer? _stressTimer;

  @override
  void dispose() {
    _stressTimer?.cancel();
    super.dispose();
  }

  void _startStressTest() {
    setState(() {
      _isStressing = true;
    });

    _stressTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (mounted) {
        setState(() {
          _counter++;
        });

        // Report custom metrics
        PerformanceToolkit.monitor.reportCustomMetric(
          'stress_test_counter',
          _counter.toDouble(),
        );

        // Simulate some expensive work
        _doExpensiveWork();
      }
    });
  }

  void _stopStressTest() {
    _stressTimer?.cancel();
    setState(() {
      _isStressing = false;
    });
  }

  void _doExpensiveWork() {
    // Simulate expensive computation
    var sum = 0;
    for (var i = 0; i < 10000; i++) {
      sum += i;
    }
    // Use sum to prevent optimization
    if (sum < 0) print('Unexpected result');
  }

  Future<void> _generateReport() async {
    final report = await PerformanceToolkit.generateReport();

    if (mounted) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Performance Report'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Summary: ${report.baseReport.summary}'),
                const SizedBox(height: 8),
                Text(
                  'Score: ${report.performanceScore.toStringAsFixed(1)}/100',
                ),
                const SizedBox(height: 8),
                Text(
                  'FPS: ${report.baseReport.metrics.fps.toStringAsFixed(1)}',
                ),
                Text(
                  'Memory: ${(report.baseReport.metrics.memoryUsage / 1024 / 1024).toStringAsFixed(1)} MB',
                ),
                Text('Frame Drops: ${report.baseReport.metrics.frameDrops}'),
                if (report.baseReport.issues.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Issues:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...report.baseReport.issues
                      .map((issue) => Text('• ${issue.description}')),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => RebuildIndicator(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Counter: $_counter',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed:
                        _isStressing ? _stopStressTest : _startStressTest,
                    child: Text(
                      _isStressing ? 'Stop Stress Test' : 'Start Stress Test',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _generateReport,
                    child: const Text('Generate Report'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  PerformanceToolkit.takeSnapshot(label: 'Manual Snapshot');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Performance snapshot taken')),
                  );
                },
                child: const Text('Take Snapshot'),
              ),
            ],
          ),
        ),
      );
}
