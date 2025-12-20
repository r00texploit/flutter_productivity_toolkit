import 'package:flutter_dev_toolkit/src/errors/error_reporter.dart';
import 'package:flutter_dev_toolkit/src/state_management/state_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('State Management System', () {
    late DefaultErrorReporter errorReporter;
    late DefaultStateProvider stateProvider;

    setUp(() {
      errorReporter = DefaultErrorReporter();
      stateProvider = DefaultStateProvider(
        errorReporter: errorReporter,
        defaultConfig: const StateConfiguration(enableDebugging: true),
      );
    });

    tearDown(() {
      stateProvider.disposeAll();
      errorReporter.dispose();
    });

    test('ReactiveStateManager should update state and notify listeners',
        () async {
      // Arrange
      final manager = ReactiveStateManager<int>(
        0,
        config: const StateConfiguration(enableDebugging: true),
        errorReporter: errorReporter,
      );

      final states = <int>[];
      final subscription = manager.stream.listen(states.add);

      // Act
      manager.update((current) => current + 1);
      manager.update((current) => current * 2);

      // Allow async operations to complete
      await Future.delayed(const Duration(milliseconds: 10));

      // Assert
      expect(manager.state, equals(2));
      expect(states, equals([1, 2]));
      expect(manager.history.length, equals(3)); // init + 2 updates

      // Cleanup
      await subscription.cancel();
      manager.dispose();
    });

    test('StateProvider should register and provide state managers', () {
      // Arrange
      final manager = ReactiveStateManager<String>(
        'initial',
      );

      // Act
      stateProvider.register<ReactiveStateManager<String>>(manager);
      final retrieved = stateProvider.provide<ReactiveStateManager<String>>();

      // Assert
      expect(retrieved, same(manager));
      expect(retrieved.state, equals('initial'));
    });

    test('StateDebugger should track state transitions', () {
      // Arrange
      final manager = ReactiveStateManager<int>(
        0,
        config: const StateConfiguration(enableDebugging: true),
        errorReporter: errorReporter,
      );
      final debugger = StateDebugger(errorReporter);

      // Act
      debugger.trackStateManager<int>(manager);
      manager.update((current) => current + 5);
      manager.update((current) => current - 2);

      // Assert
      final history = debugger.getHistory<int>();
      expect(history.length, equals(3)); // init + 2 updates
      expect(history.last.newState, equals(3));

      final timeline = debugger.generateTimeline<int>();
      expect(timeline, contains('State Timeline for int'));
      expect(timeline, contains('initialization'));
      expect(timeline, contains('update'));

      // Cleanup
      manager.dispose();
    });

    test('State persistence should handle serialization errors gracefully',
        () async {
      // Arrange
      final manager = ReactiveStateManager<DateTime>(
        DateTime.now(),
        config: const StateConfiguration(
          enablePersistence: true,
          enableDebugging: true,
        ),
        errorReporter: errorReporter,
      );

      // Act & Assert - should not throw
      await manager.persist();
      await manager.restore();

      // Cleanup
      manager.dispose();
    });
  });
}
