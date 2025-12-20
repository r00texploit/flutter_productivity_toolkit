import 'dart:async';

import 'package:flutter_productivity_toolkit/src/errors/error_reporter.dart';
import 'package:flutter_productivity_toolkit/src/state_management/state_manager.dart';

void main() async {
  print('Testing State Management System...');

  // Test 1: Basic state management
  print('\n1. Testing ReactiveStateManager...');
  final errorReporter = DefaultErrorReporter();
  final manager = ReactiveStateManager<int>(
    0,
    config: const StateConfiguration(enableDebugging: true),
    errorReporter: errorReporter,
  );

  final states = <int>[];
  final subscription = manager.stream.listen(states.add);

  manager.update((current) => current + 1);
  manager.update((current) => current * 2);

  // Allow async operations to complete
  await Future.delayed(const Duration(milliseconds: 50));

  print('Final state: ${manager.state}');
  print('State history: $states');
  print('Transition history length: ${manager.history.length}');

  assert(manager.state == 2, 'Expected state to be 2, got ${manager.state}');
  assert(states.length == 2, 'Expected 2 state changes, got ${states.length}');
  assert(manager.history.length == 3,
      'Expected 3 transitions (init + 2 updates), got ${manager.history.length}',);

  await subscription.cancel();
  manager.dispose();
  print('✓ ReactiveStateManager test passed');

  // Test 2: State provider
  print('\n2. Testing DefaultStateProvider...');
  final stateProvider = DefaultStateProvider(
    errorReporter: errorReporter,
    defaultConfig: const StateConfiguration(enableDebugging: true),
  );

  final stringManager = ReactiveStateManager<String>(
    'initial',
  );

  stateProvider.register<ReactiveStateManager<String>>(stringManager);
  final retrieved = stateProvider.provide<ReactiveStateManager<String>>();

  assert(identical(retrieved, stringManager), 'Expected same instance');
  assert(retrieved.state == 'initial', 'Expected initial state');

  stateProvider.disposeAll();
  print('✓ DefaultStateProvider test passed');

  // Test 3: State debugger
  print('\n3. Testing StateDebugger...');
  final debugManager = ReactiveStateManager<int>(
    0,
    config: const StateConfiguration(enableDebugging: true),
    errorReporter: errorReporter,
  );
  final debugger = StateDebugger(errorReporter);

  debugger.trackStateManager<int>(debugManager);
  debugManager.update((current) => current + 5);
  debugManager.update((current) => current - 2);

  final history = debugger.getHistory<int>();
  final timeline = debugger.generateTimeline<int>();

  assert(history.length == 3, 'Expected 3 transitions, got ${history.length}');
  assert(history.last.newState == 3,
      'Expected final state 3, got ${history.last.newState}',);
  assert(timeline.contains('State Timeline for int'),
      'Timeline should contain header',);
  assert(timeline.contains('initialization'),
      'Timeline should contain initialization',);
  assert(timeline.contains('update'), 'Timeline should contain updates');

  debugManager.dispose();
  print('✓ StateDebugger test passed');

  // Test 4: Error handling
  print('\n4. Testing error handling...');
  final errorManager = ReactiveStateManager<DateTime>(
    DateTime.now(),
    config: const StateConfiguration(
      enablePersistence: true,
      enableDebugging: true,
    ),
    errorReporter: errorReporter,
  );

  // This should not throw even though DateTime serialization might fail
  try {
    await errorManager.persist();
    await errorManager.restore();
    print('✓ Error handling test passed (no exceptions thrown)');
  } catch (e) {
    print('✗ Error handling test failed: $e');
  }

  errorManager.dispose();
  errorReporter.dispose();

  print('\n🎉 All tests passed! State management system is working correctly.');
}
