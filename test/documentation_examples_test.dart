import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_productivity_toolkit/src/state_management/state_manager.dart';
import 'package:flutter_productivity_toolkit/src/navigation/route_builder.dart';
import 'package:flutter_productivity_toolkit/src/performance/performance_monitor.dart';
import 'package:flutter_productivity_toolkit/src/errors/error_reporter.dart';

/// Tests to validate that key code examples from documentation work correctly
void main() {
  group('Documentation Examples Validation', () {
    test('State Management example from documentation should work', () async {
      // Example from state_management.md - Basic Usage section
      final errorReporter = DefaultErrorReporter();

      final stateManager = ReactiveStateManager<int>(
        0,
        config: const StateConfiguration(
          enableDebugging: true,
          enablePersistence: false,
        ),
        errorReporter: errorReporter,
      );

      final states = <int>[];
      final subscription = stateManager.stream.listen(states.add);

      // Update state as shown in documentation
      stateManager.update((current) => current + 1);
      stateManager.update((current) => current * 2);

      // Allow async operations to complete
      await Future.delayed(const Duration(milliseconds: 10));

      // Verify the example works as documented
      expect(stateManager.state, equals(2));
      expect(states, equals([1, 2]));

      // Cleanup
      await subscription.cancel();
      stateManager.dispose();
      errorReporter.dispose();
    });

    test('Navigation example from documentation should work', () async {
      // Example from navigation.md - Basic Usage section
      final routeBuilder = DefaultRouteBuilder();
      final navigationStack = routeBuilder.createNavigationStack();
      routeBuilder.setActiveStack(navigationStack);

      // Define route as shown in documentation
      routeBuilder.defineRoute<void>('/home', (params) {
        return const MockScreen();
      });

      // Navigate as shown in documentation
      await routeBuilder.navigate<void, void>('/home');

      // Verify navigation worked
      expect(navigationStack.history.length, equals(1));
      expect(navigationStack.history.first.path, equals('/home'));

      // Cleanup
      routeBuilder.dispose();
    });

    test('Performance monitoring example should work', () {
      // Example from performance.md - Basic Performance Monitoring Setup
      final monitor = MockPerformanceMonitor();

      // Set thresholds as shown in documentation
      monitor.setThresholds(
        const PerformanceThresholds(
          maxFrameDropsPerSecond: 5,
          maxMemoryUsage: 512 * 1024 * 1024, // 512MB
          maxWidgetRebuilds: 100,
          minFps: 55.0,
          maxFrameTime: 16.67, // ~60fps
        ),
      );

      // Start monitoring as shown in documentation
      monitor.startMonitoring();
      expect(monitor.isMonitoring, isTrue);

      // Stop monitoring
      monitor.stopMonitoring();
      expect(monitor.isMonitoring, isFalse);
    });

    test('State Provider example from documentation should work', () {
      // Example from state_management.md - Dependency Injection section
      final errorReporter = DefaultErrorReporter();
      final stateProvider = DefaultStateProvider(
        errorReporter: errorReporter,
        defaultConfig: const StateConfiguration(enableDebugging: true),
      );

      final manager = ReactiveStateManager<String>(
        'initial',
        config: const StateConfiguration(enableDebugging: true),
        errorReporter: errorReporter,
      );

      // Register and provide as shown in documentation
      stateProvider.register<ReactiveStateManager<String>>(manager);
      final retrieved = stateProvider.provide<ReactiveStateManager<String>>();

      expect(retrieved, same(manager));
      expect(retrieved.state, equals('initial'));

      // Cleanup
      stateProvider.disposeAll();
      errorReporter.dispose();
    });

    test('Route guards example from documentation should work', () async {
      // Example from navigation.md - Navigation Guards section
      final routeBuilder = DefaultRouteBuilder();

      final authGuard = DefaultRouteGuard((route) async {
        // Simulate authentication check
        return false; // Not authenticated
      });

      routeBuilder.defineRouteWithGuards<void>(
        '/protected',
        (params) => const MockScreen(),
        guards: [authGuard],
        requiresAuthentication: true,
      );

      // Should throw when trying to navigate to protected route
      expect(
        () => routeBuilder.navigate<void, void>('/protected'),
        throwsA(isA<StateError>()),
      );

      routeBuilder.dispose();
    });

    test('Navigation stack operations from documentation should work', () {
      // Example from navigation.md - Basic Navigation section
      final routeBuilder = DefaultRouteBuilder();
      final navigationStack = routeBuilder.createNavigationStack();

      const route1 = NavigationRoute(path: '/home');
      const route2 = NavigationRoute(path: '/profile');
      const route3 = NavigationRoute(path: '/settings');

      // Push operations as shown in documentation
      navigationStack.push(route1);
      navigationStack.push(route2);
      navigationStack.push(route3);

      expect(navigationStack.history.length, equals(3));
      expect(navigationStack.canPop, isTrue);
      expect(navigationStack.history.last.path, equals('/settings'));

      // Pop operation as shown in documentation
      navigationStack.pop();
      expect(navigationStack.history.length, equals(2));
      expect(navigationStack.history.last.path, equals('/profile'));

      routeBuilder.dispose();
    });
  });
}

// Mock classes for testing
class MockScreen {
  const MockScreen();
}

class MockPerformanceMonitor extends PerformanceMonitor {
  bool _isMonitoring = false;
  PerformanceThresholds _thresholds = const PerformanceThresholds();

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
  Stream<PerformanceMetrics> get metricsStream => const Stream.empty();

  @override
  void reportCustomMetric(String name, double value, {String? unit}) {
    // Mock implementation
  }

  @override
  PerformanceMetrics get currentMetrics => PerformanceMetrics(
        frameDrops: 0,
        memoryUsage: 50 * 1024 * 1024,
        peakMemoryUsage: 60 * 1024 * 1024,
        widgetRebuildCounts: const {},
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
}
