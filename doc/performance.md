# Performance Guide

The Flutter Productivity Toolkit provides comprehensive performance monitoring, debugging, and optimization tools to help you build high-performance Flutter applications. This guide covers performance monitoring, optimization techniques, debugging tools, and best practices for handling large datasets.

## Prerequisites

- Flutter 3.0.0 or higher
- Dart 2.17.0 or higher
- Basic understanding of Flutter performance concepts
- Flutter Productivity Toolkit installed and configured

## Table of Contents

1. [Performance Overview](#performance-overview)
2. [Performance Monitoring](#performance-monitoring)
3. [Real-time Metrics Collection](#real-time-metrics-collection)
4. [Performance Debugging](#performance-debugging)
5. [Widget Optimization](#widget-optimization)
6. [Memory Management](#memory-management)
7. [Large Dataset Handling](#large-dataset-handling)
8. [State Management Performance](#state-management-performance)
9. [Custom Performance Metrics](#custom-performance-metrics)
10. [Performance Benchmarking](#performance-benchmarking)
11. [Performance Reporting](#performance-reporting)
12. [Production Monitoring](#production-monitoring)
13. [Troubleshooting](#troubleshooting)

## Performance Overview

The Flutter Productivity Toolkit's performance system provides comprehensive monitoring and optimization tools designed around three core principles:

- **Real-time Monitoring**: Continuous performance tracking with minimal overhead
- **Actionable Insights**: Clear recommendations for performance improvements
- **Proactive Alerting**: Early detection of performance issues before they impact users

### Performance Architecture

```dart
// Core performance components
PerformanceMonitor        // Main monitoring interface
FlutterPerformanceMonitor // Flutter-specific implementation
PerformanceReporter       // Advanced reporting and analysis
WidgetRebuildTracker     // Widget-specific performance tracking
PerformanceToolkit       // Integrated performance utilities
```

### Key Performance Metrics

The toolkit tracks essential performance indicators:

- **Frame Rate (FPS)**: Smoothness of animations and UI interactions
- **Frame Time**: Time taken to render each frame
- **Memory Usage**: Current and peak memory consumption
- **Widget Rebuilds**: Frequency and patterns of widget rebuilds
- **Custom Metrics**: Application-specific performance indicators

## Performance Monitoring

### Basic Performance Monitoring Setup

Initialize performance monitoring in your application:

```dart
import 'package:flutter_productivity_toolkit/flutter_productivity_toolkit.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late FlutterPerformanceMonitor _performanceMonitor;
  late PerformanceReporter _performanceReporter;

  @override
  void initState() {
    super.initState();
    _setupPerformanceMonitoring();
  }

  void _setupPerformanceMonitoring() {
    // Create performance monitor
    _performanceMonitor = FlutterPerformanceMonitor();
    
    // Create performance reporter
    _performanceReporter = PerformanceReporter(_performanceMonitor);
    
    // Set performance thresholds
    _performanceMonitor.setThresholds(
      const PerformanceThresholds(
        maxFrameDropsPerSecond: 5,
        maxMemoryUsage: 512 * 1024 * 1024, // 512MB
        maxWidgetRebuilds: 100,
        minFps: 55.0,
        maxFrameTime: 16.67, // ~60fps
      ),
    );
    
    // Start monitoring
    _performanceMonitor.startMonitoring();
    _performanceReporter.startReporting();
    
    // Listen to performance alerts
    _performanceReporter.alertStream.listen(_handlePerformanceAlert);
  }

  void _handlePerformanceAlert(PerformanceAlert alert) {
    print('Performance Alert: ${alert.message}');
    
    // Handle critical alerts
    if (alert.severity == AlertSeverity.critical) {
      _showPerformanceWarning(alert);
    }
  }

  void _showPerformanceWarning(PerformanceAlert alert) {
    // Show user-friendly performance warning
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Performance issue detected: ${alert.message}'),
        backgroundColor: Colors.orange,
        action: SnackBarAction(
          label: 'Details',
          onPressed: () => _showPerformanceDetails(),
        ),
      ),
    );
  }

  void _showPerformanceDetails() async {
    final report = await _performanceReporter.generateEnhancedReport();
    
    showDialog(
      context: context,
      builder: (context) => PerformanceReportDialog(report: report),
    );
  }

  @override
  void dispose() {
    _performanceMonitor.stopMonitoring();
    _performanceReporter.stopReporting();
    _performanceMonitor.dispose();
    _performanceReporter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Performance Demo',
      home: HomeScreen(
        performanceMonitor: _performanceMonitor,
        performanceReporter: _performanceReporter,
      ),
    );
  }
}
```

### Performance Metrics Display

Create a widget to display real-time performance metrics:

```dart
class PerformanceMetricsWidget extends StatelessWidget {
  final FlutterPerformanceMonitor performanceMonitor;
  
  const PerformanceMetricsWidget({
    required this.performanceMonitor,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PerformanceMetrics>(
      stream: performanceMonitor.metricsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final metrics = snapshot.data!;
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Performance Metrics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildMetricRow('FPS', '${metrics.fps.toStringAsFixed(1)}'),
                _buildMetricRow(
                  'Frame Time', 
                  '${metrics.averageFrameTime.toStringAsFixed(2)}ms',
                ),
                _buildMetricRow(
                  'Memory', 
                  '${(metrics.memoryUsage / 1024 / 1024).toStringAsFixed(1)}MB',
                ),
                _buildMetricRow('Frame Drops', '${metrics.frameDrops}'),
                _buildMetricRow('Warnings', '${metrics.warnings.length}'),
                const SizedBox(height: 16),
                _buildPerformanceIndicator(metrics),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceIndicator(PerformanceMetrics metrics) {
    final isGood = metrics.isPerformanceGood;
    
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: isGood ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Icon(
            isGood ? Icons.check_circle : Icons.warning,
            color: isGood ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            isGood ? 'Performance Good' : 'Performance Issues Detected',
            style: TextStyle(
              color: isGood ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
```

## Real-time Metrics Collection

### Custom Metrics Tracking

Track application-specific performance metrics:

```dart
class ApiPerformanceTracker {
  final FlutterPerformanceMonitor performanceMonitor;
  
  ApiPerformanceTracker(this.performanceMonitor);

  Future<T> trackApiCall<T>(
    String apiName,
    Future<T> Function() apiCall,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await apiCall();
      stopwatch.stop();
      
      // Report successful API call time
      performanceMonitor.reportCustomMetric(
        'api_${apiName}_response_time',
        stopwatch.elapsedMilliseconds.toDouble(),
        unit: 'ms',
      );
      
      // Track success rate
      performanceMonitor.reportCustomMetric(
        'api_${apiName}_success_rate',
        1.0,
      );
      
      return result;
    } catch (e) {
      stopwatch.stop();
      
      // Report failed API call
      performanceMonitor.reportCustomMetric(
        'api_${apiName}_error_rate',
        1.0,
      );
      
      performanceMonitor.reportCustomMetric(
        'api_${apiName}_response_time',
        stopwatch.elapsedMilliseconds.toDouble(),
        unit: 'ms',
      );
      
      rethrow;
    }
  }
}

// Usage example
class UserService {
  final ApiPerformanceTracker _performanceTracker;
  
  UserService(this._performanceTracker);

  Future<List<User>> fetchUsers() async {
    return _performanceTracker.trackApiCall(
      'fetch_users',
      () async {
        // Simulate API call
        await Future.delayed(const Duration(milliseconds: 500));
        return [
          User(id: '1', name: 'John Doe'),
          User(id: '2', name: 'Jane Smith'),
        ];
      },
    );
  }
}
```

### Database Performance Tracking

Monitor database operation performance:

```dart
class DatabasePerformanceTracker {
  final FlutterPerformanceMonitor performanceMonitor;
  
  DatabasePerformanceTracker(this.performanceMonitor);

  Future<T> trackDatabaseOperation<T>(
    String operationType,
    String tableName,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await operation();
      stopwatch.stop();
      
      final metricName = 'db_${operationType}_${tableName}_time';
      performanceMonitor.reportCustomMetric(
        metricName,
        stopwatch.elapsedMilliseconds.toDouble(),
        unit: 'ms',
      );
      
      return result;
    } catch (e) {
      stopwatch.stop();
      
      final errorMetricName = 'db_${operationType}_${tableName}_errors';
      performanceMonitor.reportCustomMetric(errorMetricName, 1.0);
      
      rethrow;
    }
  }
}

// Usage with state management
class TodoRepository {
  final DatabasePerformanceTracker _performanceTracker;
  
  TodoRepository(this._performanceTracker);

  Future<List<Todo>> getAllTodos() async {
    return _performanceTracker.trackDatabaseOperation(
      'select',
      'todos',
      () async {
        // Database query implementation
        return await database.query('todos');
      },
    );
  }

  Future<void> insertTodo(Todo todo) async {
    return _performanceTracker.trackDatabaseOperation(
      'insert',
      'todos',
      () async {
        await database.insert('todos', todo.toMap());
      },
    );
  }
}
```

## Performance Debugging

### Widget Rebuild Tracking

Track and analyze widget rebuild patterns:

```dart
class PerformanceDebugWidget extends StatefulWidget {
  final Widget child;
  final String debugName;
  
  const PerformanceDebugWidget({
    required this.child,
    required this.debugName,
  });

  @override
  _PerformanceDebugWidgetState createState() => _PerformanceDebugWidgetState();
}

class _PerformanceDebugWidgetState extends State<PerformanceDebugWidget> {
  int _buildCount = 0;
  DateTime? _lastBuildTime;

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    final now = DateTime.now();
    
    if (kDebugMode) {
      final timeSinceLastBuild = _lastBuildTime != null 
          ? now.difference(_lastBuildTime!).inMilliseconds 
          : 0;
      
      print('${widget.debugName} rebuilt #$_buildCount '
            '(${timeSinceLastBuild}ms since last build)');
      
      // Track rebuild in performance monitor
      final performanceMonitor = PerformanceToolkit.instance.monitor;
      performanceMonitor.trackWidgetRebuild(
        widget.debugName,
        buildTime: Duration(milliseconds: timeSinceLastBuild),
      );
    }
    
    _lastBuildTime = now;
    
    return widget.child;
  }
}

// Usage example
class OptimizedTodoList extends StatelessWidget {
  final List<Todo> todos;
  
  const OptimizedTodoList({required this.todos});

  @override
  Widget build(BuildContext context) {
    return PerformanceDebugWidget(
      debugName: 'TodoList',
      child: ListView.builder(
        itemCount: todos.length,
        itemBuilder: (context, index) {
          return PerformanceDebugWidget(
            debugName: 'TodoItem_${todos[index].id}',
            child: TodoItemWidget(todo: todos[index]),
          );
        },
      ),
    );
  }
}
```

## Widget Optimization

### Preventing Unnecessary Rebuilds

Optimize widgets to minimize rebuilds:

```dart
// ❌ Inefficient widget that rebuilds frequently
class InefficientTodoList extends StatelessWidget {
  final TodoState state;
  
  const InefficientTodoList({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Total: ${state.todos.length}'), // Rebuilds when any todo changes
        ListView.builder(
          shrinkWrap: true,
          itemCount: state.todos.length,
          itemBuilder: (context, index) {
            final todo = state.todos[index];
            return ListTile(
              title: Text(todo.title),
              trailing: Checkbox(
                value: todo.completed,
                onChanged: (value) => _toggleTodo(todo.id),
              ),
            );
          },
        ),
      ],
    );
  }
  
  void _toggleTodo(String id) {
    // Toggle implementation
  }
}

// ✅ Optimized widget with selective rebuilds
class OptimizedTodoList extends StatelessWidget {
  final Stream<TodoState> stateStream;
  
  const OptimizedTodoList({required this.stateStream});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Only rebuild when todo count changes
        StreamBuilder<int>(
          stream: stateStream.map((state) => state.todos.length).distinct(),
          builder: (context, snapshot) {
            return Text('Total: ${snapshot.data ?? 0}');
          },
        ),
        
        // Only rebuild when todo list changes
        StreamBuilder<List<Todo>>(
          stream: stateStream.map((state) => state.todos).distinct(),
          builder: (context, snapshot) {
            final todos = snapshot.data ?? [];
            return ListView.builder(
              shrinkWrap: true,
              itemCount: todos.length,
              itemBuilder: (context, index) {
                return OptimizedTodoItem(
                  key: ValueKey(todos[index].id),
                  todo: todos[index],
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class OptimizedTodoItem extends StatelessWidget {
  final Todo todo;
  
  const OptimizedTodoItem({
    Key? key,
    required this.todo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(todo.title),
      trailing: Checkbox(
        value: todo.completed,
        onChanged: (value) => _toggleTodo(todo.id),
      ),
    );
  }
  
  void _toggleTodo(String id) {
    // Toggle implementation
  }
}
```

### Using const Constructors

Leverage const constructors for better performance:

```dart
// ✅ Optimized with const constructors
class PerformantStaticWidget extends StatelessWidget {
  const PerformantStaticWidget();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        // These widgets are created once and reused
        Text('Static Title'),
        SizedBox(height: 16),
        Icon(Icons.star, size: 24),
        Divider(),
      ],
    );
  }
}

// ✅ Conditional const usage
class ConditionalConstWidget extends StatelessWidget {
  final bool showIcon;
  final String title;
  
  const ConditionalConstWidget({
    required this.showIcon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title), // Dynamic content
        const SizedBox(height: 16), // Static spacing
        if (showIcon) 
          const Icon(Icons.star) // Const when possible
        else 
          const SizedBox.shrink(), // Const empty widget
      ],
    );
  }
}
```

## Memory Management

### Memory Usage Monitoring

Monitor and optimize memory usage:

```dart
class MemoryManager {
  final FlutterPerformanceMonitor performanceMonitor;
  Timer? _memoryCheckTimer;
  
  MemoryManager(this.performanceMonitor);

  void startMemoryMonitoring() {
    _memoryCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkMemoryUsage(),
    );
  }

  void stopMemoryMonitoring() {
    _memoryCheckTimer?.cancel();
    _memoryCheckTimer = null;
  }

  void _checkMemoryUsage() async {
    final metrics = performanceMonitor.currentMetrics;
    final memoryMB = metrics.memoryUsage / (1024 * 1024);
    
    if (memoryMB > 400) { // 400MB threshold
      print('High memory usage detected: ${memoryMB.toStringAsFixed(1)}MB');
      await _performMemoryCleanup();
    }
  }

  Future<void> _performMemoryCleanup() async {
    // Clear image cache
    PaintingBinding.instance.imageCache.clear();
    
    // Force garbage collection
    await _forceGarbageCollection();
    
    print('Memory cleanup completed');
  }

  Future<void> _forceGarbageCollection() async {
    // Trigger garbage collection
    for (int i = 0; i < 3; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      // Create and discard objects to trigger GC
      List.generate(1000, (index) => Object());
    }
  }
}
```

## Large Dataset Handling

### Efficient List Rendering

Handle large datasets efficiently:

```dart
class EfficientLargeListWidget extends StatefulWidget {
  final List<DataItem> items;
  
  const EfficientLargeListWidget({required this.items});

  @override
  _EfficientLargeListWidgetState createState() => _EfficientLargeListWidgetState();
}

class _EfficientLargeListWidgetState extends State<EfficientLargeListWidget> {
  final ScrollController _scrollController = ScrollController();
  final int _itemsPerPage = 50;
  int _currentPage = 0;
  
  List<DataItem> get _visibleItems {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, widget.items.length);
    return widget.items.sublist(startIndex, endIndex);
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreItems();
    }
  }

  void _loadMoreItems() {
    if ((_currentPage + 1) * _itemsPerPage < widget.items.length) {
      setState(() {
        _currentPage++;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _visibleItems.length + 1, // +1 for loading indicator
      itemBuilder: (context, index) {
        if (index == _visibleItems.length) {
          return _buildLoadingIndicator();
        }
        
        return _buildOptimizedListItem(_visibleItems[index]);
      },
    );
  }

  Widget _buildOptimizedListItem(DataItem item) {
    return ListTile(
      key: ValueKey(item.id),
      title: Text(item.title),
      subtitle: Text(item.subtitle),
      // Use const widgets where possible
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () => _handleItemTap(item),
    );
  }

  Widget _buildLoadingIndicator() {
    final hasMoreItems = (_currentPage + 1) * _itemsPerPage < widget.items.length;
    
    if (!hasMoreItems) {
      return const SizedBox.shrink();
    }
    
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _handleItemTap(DataItem item) {
    // Handle item tap
  }
}
```

## State Management Performance

Optimizing state management performance is crucial for responsive applications. The toolkit's state management system provides built-in performance optimizations, but understanding how to use them effectively is important. For detailed state management patterns and optimization techniques, see the [State Management Guide](state_management.md#performance-optimization).

### Optimizing State Updates

Optimize state management for better performance:

```dart
class PerformantStateManager<T> extends ReactiveStateManager<T> {
  final PerformanceProfiler _profiler;
  
  PerformantStateManager(
    T initialState,
    this._profiler, {
    StateConfiguration? config,
  }) : super(initialState, config: config);

  @override
  void update(T Function(T current) updater) {
    _profiler.profileOperation('state_update_${T.toString()}', () {
      super.update(updater);
    });
  }

  @override
  Future<void> persist() async {
    await _profiler.profileAsyncOperation('state_persist_${T.toString()}', () {
      return super.persist();
    });
  }

  @override
  Future<void> restore() async {
    await _profiler.profileAsyncOperation('state_restore_${T.toString()}', () {
      return super.restore();
    });
  }
}
```

## Custom Performance Metrics

### Application-Specific Metrics

Track metrics specific to your application:

```dart
class AppPerformanceMetrics {
  final FlutterPerformanceMonitor performanceMonitor;
  
  AppPerformanceMetrics(this.performanceMonitor);

  void trackUserInteraction(String interactionType) {
    performanceMonitor.reportCustomMetric(
      'user_interaction_$interactionType',
      1.0,
    );
  }

  void trackScreenTransition(String fromScreen, String toScreen, Duration duration) {
    performanceMonitor.reportCustomMetric(
      'screen_transition_${fromScreen}_to_$toScreen',
      duration.inMilliseconds.toDouble(),
      unit: 'ms',
    );
  }

  void trackDataSyncOperation(String operationType, int itemCount, Duration duration) {
    performanceMonitor.reportCustomMetric(
      'data_sync_${operationType}_time',
      duration.inMilliseconds.toDouble(),
      unit: 'ms',
    );
    
    performanceMonitor.reportCustomMetric(
      'data_sync_${operationType}_items',
      itemCount.toDouble(),
    );
  }
}
```

## Performance Benchmarking

### Automated Performance Testing

Create automated performance benchmarks:

```dart
class PerformanceBenchmarkSuite {
  final PerformanceReporter performanceReporter;
  final List<PerformanceBenchmark> benchmarks = [];
  
  PerformanceBenchmarkSuite(this.performanceReporter);

  void addBenchmark(PerformanceBenchmark benchmark) {
    benchmarks.add(benchmark);
  }

  Future<List<BenchmarkResult>> runAllBenchmarks() async {
    final results = <BenchmarkResult>[];
    
    for (final benchmark in benchmarks) {
      print('Running benchmark: ${benchmark.name}');
      final result = await performanceReporter.runBenchmark(benchmark);
      results.add(result);
      
      print('Benchmark ${benchmark.name}: '
            '${result.passed ? 'PASSED' : 'FAILED'} '
            '(Score: ${result.score.toStringAsFixed(1)})');
    }
    
    return results;
  }

  void setupStandardBenchmarks() {
    // UI responsiveness benchmark
    addBenchmark(
      const PerformanceBenchmark(
        name: 'UI Responsiveness',
        description: 'Tests UI responsiveness under normal load',
        duration: Duration(seconds: 30),
        expectedFps: 55.0,
        maxMemoryUsage: 200 * 1024 * 1024, // 200MB
      ),
    );

    // Heavy computation benchmark
    addBenchmark(
      const PerformanceBenchmark(
        name: 'Heavy Computation',
        description: 'Tests performance during heavy computation',
        duration: Duration(seconds: 10),
        expectedFps: 45.0,
        maxMemoryUsage: 300 * 1024 * 1024, // 300MB
      ),
    );
  }
}
```

## Performance Reporting

### Comprehensive Performance Reports

Generate detailed performance reports:

```dart
class PerformanceReportGenerator {
  final PerformanceReporter performanceReporter;
  
  PerformanceReportGenerator(this.performanceReporter);

  Future<void> generateDailyReport() async {
    final report = await performanceReporter.generateEnhancedReport(
      timeRange: const Duration(hours: 24),
      includeComparisons: true,
      includeTrendAnalysis: true,
      includeBenchmarks: true,
    );

    final reportContent = _formatReport(report);
    
    // Save to file
    await performanceReporter.saveReportToFile(
      report,
      'performance_report_${DateTime.now().toIso8601String()}.md',
    );
    
    print('Daily performance report generated');
  }

  String _formatReport(EnhancedPerformanceReport report) {
    final buffer = StringBuffer();
    
    buffer.writeln('# Performance Report');
    buffer.writeln('Generated: ${report.generatedAt}');
    buffer.writeln('Score: ${report.performanceScore.toStringAsFixed(1)}/100');
    buffer.writeln();
    
    buffer.writeln('## Executive Summary');
    buffer.writeln(report.baseReport.summary);
    buffer.writeln();
    
    if (report.trendAnalysis != null) {
      buffer.writeln('## Performance Trends');
      final trend = report.trendAnalysis!;
      buffer.writeln('Overall Trend: ${trend.overallTrend}');
      buffer.writeln('FPS Trend: ${trend.fpsTrend}');
      buffer.writeln('Memory Trend: ${trend.memoryTrend}');
      buffer.writeln();
    }
    
    return buffer.toString();
  }
}
```

## Production Monitoring

### Production Performance Monitoring

Set up performance monitoring for production:

```dart
class ProductionPerformanceMonitor {
  final FlutterPerformanceMonitor performanceMonitor;
  final PerformanceReporter performanceReporter;
  Timer? _reportingTimer;
  
  ProductionPerformanceMonitor()
      : performanceMonitor = FlutterPerformanceMonitor(),
        performanceReporter = PerformanceReporter(FlutterPerformanceMonitor());

  void initialize() {
    // Configure for production
    performanceMonitor.setThresholds(
      const PerformanceThresholds(
        maxFrameDropsPerSecond: 10, // More lenient for production
        maxMemoryUsage: 1024 * 1024 * 1024, // 1GB
        maxWidgetRebuilds: 200,
        minFps: 45.0, // Lower threshold for production
        maxFrameTime: 22.0, // ~45fps
      ),
    );

    // Start monitoring
    performanceMonitor.startMonitoring();
    performanceReporter.startReporting(
      snapshotInterval: const Duration(minutes: 5),
      enableAlerting: true,
    );

    // Set up periodic reporting
    _reportingTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _sendPerformanceData(),
    );

    // Listen to critical alerts
    performanceReporter.alertStream
        .where((alert) => alert.severity == AlertSeverity.critical)
        .listen(_handleCriticalAlert);
  }

  void _sendPerformanceData() async {
    try {
      final summary = performanceReporter.generateQuickSummary();
      final statistics = performanceReporter.getStatistics(
        timeRange: const Duration(hours: 1),
      );

      // Send to crash reporting service
      await _sendToCrashlytics({
        'performance_summary': summary,
        'avg_fps': statistics.averageFps,
        'avg_memory_mb': statistics.averageMemoryUsage / (1024 * 1024),
        'sample_count': statistics.sampleCount,
      });
    } catch (e) {
      print('Failed to send performance data: $e');
    }
  }

  void _handleCriticalAlert(PerformanceAlert alert) {
    // Log critical performance issues
    print('CRITICAL PERFORMANCE ALERT: ${alert.message}');
    
    // Send to crash reporting
    _sendToCrashlytics({
      'alert_type': alert.type.toString(),
      'alert_message': alert.message,
      'alert_severity': alert.severity.toString(),
      'fps': alert.metrics.fps,
      'memory_mb': alert.metrics.memoryUsage / (1024 * 1024),
    });
  }

  Future<void> _sendToCrashlytics(Map<String, dynamic> data) async {
    // Send to your crash reporting service (Firebase Crashlytics, Sentry, etc.)
    // await FirebaseCrashlytics.instance.setCustomKey('performance_data', data);
  }

  void dispose() {
    _reportingTimer?.cancel();
    performanceMonitor.stopMonitoring();
    performanceReporter.stopReporting();
    performanceMonitor.dispose();
    performanceReporter.dispose();
  }
}
```

## Troubleshooting

### Common Performance Issues

#### Issue: High Memory Usage

**Symptoms**: App crashes with out-of-memory errors, slow performance, high memory usage in profiler

**Causes**:
- Image cache not properly configured
- Large objects not being garbage collected
- Memory leaks in state managers or streams

**Solutions**:
```dart
// Configure image cache
PaintingBinding.instance.imageCache.maximumSize = 100;
PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024;

// Properly dispose of resources
@override
void dispose() {
  _streamSubscription?.cancel();
  _controller.dispose();
  super.dispose();
}
```

#### Issue: Low Frame Rate

**Symptoms**: Choppy animations, UI lag, frame drops

**Causes**:
- Expensive operations on main thread
- Excessive widget rebuilds
- Inefficient list rendering

**Solutions**:
```dart
// Move expensive operations to isolates
Future<List<ProcessedData>> processDataInIsolate(List<RawData> data) async {
  return compute(_processData, data);
}

static List<ProcessedData> _processData(List<RawData> data) {
  return data.map((item) => ProcessedData.fromRaw(item)).toList();
}

// Use const constructors
const MyWidget({
  Key? key,
  required this.title,
}) : super(key: key);

// Optimize list rendering
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ListTile(
      key: ValueKey(items[index].id), // Add keys for better performance
      title: Text(items[index].title),
    );
  },
)
```

### Performance Debugging Tools

Use the toolkit's debugging tools to identify performance issues:

```dart
// Enable performance debugging in development
void main() {
  if (kDebugMode) {
    PerformanceToolkit.instance.enableDebugging();
  }
  
  runApp(MyApp());
}

// Use performance debug widgets
PerformanceDebugWidget(
  debugName: 'ExpensiveWidget',
  child: ExpensiveWidget(),
)

// Profile specific operations
final profiler = PerformanceProfiler(performanceMonitor);
final result = profiler.profileOperation('expensive_calculation', () {
  return expensiveCalculation();
});
```

## Next Steps

Now that you understand performance monitoring and optimization:

1. **Implement Monitoring**: Set up performance monitoring in your application
2. **Establish Baselines**: Create performance benchmarks for your app
3. **Optimize Critical Paths**: Focus on the most performance-critical parts of your app
4. **Monitor Production**: Set up production performance monitoring
5. **Iterate and Improve**: Continuously monitor and optimize based on real-world data

## Related Documentation

- [State Management Guide](state_management.md) - Optimize state management performance, including selective updates and memory management strategies
- [Testing Guide](testing.md) - Performance testing strategies, benchmarking approaches, and automated performance validation
- [API Reference](api_reference.md) - Detailed performance API documentation with method signatures and usage examples
- [Troubleshooting](troubleshooting.md) - Common performance issues and their solutions, including debugging techniques

For more advanced performance optimization techniques and platform-specific optimizations, check out the [example applications](../example/) and [performance monitoring examples](../example/performance_monitoring_example.dart).