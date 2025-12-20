import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dev_toolkit/flutter_dev_toolkit.dart';

/// Example demonstrating comprehensive state management features.
///
/// This example showcases:
/// - Reactive state updates with automatic widget rebuilds
/// - State persistence and restoration
/// - Dependency injection with lifecycle management
/// - State debugging and transition history
/// - Multiple state managers working together
void main() {
  runApp(const StateManagementExample());
}

class StateManagementExample extends StatelessWidget {
  const StateManagementExample({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
        title: 'State Management Example',
        home: StateManagementDemo(),
      );
}

class StateManagementDemo extends StatefulWidget {
  const StateManagementDemo({super.key});

  @override
  State<StateManagementDemo> createState() => _StateManagementDemoState();
}

class _StateManagementDemoState extends State<StateManagementDemo> {
  late DefaultStateProvider _stateProvider;
  late StateDebugger _debugger;
  late ReactiveStateManager<CounterState> _counterManager;
  late ReactiveStateManager<UserPreferences> _preferencesManager;
  late ReactiveStateManager<TodoList> _todoManager;

  @override
  void initState() {
    super.initState();
    _setupStateManagement();
  }

  void _setupStateManagement() {
    // Create error reporter for debugging
    final errorReporter = DefaultErrorReporter();

    // Create state provider with debugging enabled
    _stateProvider = DefaultStateProvider(
      errorReporter: errorReporter,
      defaultConfig: StateConfiguration.development(),
    );

    // Create state debugger
    _debugger = StateDebugger(errorReporter);

    // Create counter state manager
    _counterManager = ReactiveStateManager<CounterState>(
      CounterState(count: 0, lastIncrement: DateTime.now()),
      config: const StateConfiguration(
        enableDebugging: true,
        enablePersistence: true,
        storageKey: 'counter_state',
      ),
      errorReporter: errorReporter,
    );

    // Create user preferences state manager
    _preferencesManager = ReactiveStateManager<UserPreferences>(
      const UserPreferences(
        theme: 'light',
        notifications: true,
        language: 'en',
      ),
      config: const StateConfiguration(
        enableDebugging: true,
        enablePersistence: true,
        storageKey: 'user_preferences',
      ),
      errorReporter: errorReporter,
    );

    // Create todo list state manager
    _todoManager = ReactiveStateManager<TodoList>(
      const TodoList(items: []),
      config: const StateConfiguration(
        enableDebugging: true,
      ),
      errorReporter: errorReporter,
    );

    // Register state managers with provider
    _stateProvider
        .register<ReactiveStateManager<CounterState>>(_counterManager);
    _stateProvider
        .register<ReactiveStateManager<UserPreferences>>(_preferencesManager);
    _stateProvider.register<ReactiveStateManager<TodoList>>(_todoManager);

    // Start tracking for debugging
    _debugger.trackStateManager(_counterManager);
    _debugger.trackStateManager(_preferencesManager);
    _debugger.trackStateManager(_todoManager);

    // Restore persisted state
    _counterManager.restore().catchError((Object error) {
      debugPrint('Failed to restore counter state: $error');
    });
    _preferencesManager.restore().catchError((Object error) {
      debugPrint('Failed to restore preferences: $error');
    });
  }

  @override
  void dispose() {
    _counterManager.dispose();
    _preferencesManager.dispose();
    _todoManager.dispose();
    _stateProvider.disposeAll();
    _debugger.clearAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('State Management Demo'),
          actions: [
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: _showDebugInfo,
              tooltip: 'Show Debug Info',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCounterSection(),
              const SizedBox(height: 24),
              _buildPreferencesSection(),
              const SizedBox(height: 24),
              _buildTodoSection(),
              const SizedBox(height: 24),
              _buildActionsSection(),
            ],
          ),
        ),
      );

  Widget _buildCounterSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Counter State (Persistent)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              StreamBuilder<CounterState>(
                stream: _counterManager.stream,
                initialData: _counterManager.state,
                builder: (context, snapshot) {
                  final state = snapshot.data!;
                  return Column(
                    children: [
                      Text(
                        'Count: ${state.count}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        'Last increment: ${_formatTime(state.lastIncrement)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: _incrementCounter,
                            child: const Text('Increment'),
                          ),
                          ElevatedButton(
                            onPressed: _decrementCounter,
                            child: const Text('Decrement'),
                          ),
                          ElevatedButton(
                            onPressed: _resetCounter,
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      );

  Widget _buildPreferencesSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User Preferences (Persistent)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              StreamBuilder<UserPreferences>(
                stream: _preferencesManager.stream,
                initialData: _preferencesManager.state,
                builder: (context, snapshot) {
                  final prefs = snapshot.data!;
                  return Column(
                    children: [
                      ListTile(
                        title: const Text('Theme'),
                        subtitle: Text(prefs.theme),
                        trailing: DropdownButton<String>(
                          value: prefs.theme,
                          items: ['light', 'dark', 'auto']
                              .map((theme) => DropdownMenuItem(
                                    value: theme,
                                    child: Text(theme),
                                  ),)
                              .toList(),
                          onChanged: (theme) => _updateTheme(theme!),
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Notifications'),
                        value: prefs.notifications,
                        onChanged: _updateNotifications,
                      ),
                      ListTile(
                        title: const Text('Language'),
                        subtitle: Text(prefs.language),
                        trailing: DropdownButton<String>(
                          value: prefs.language,
                          items: ['en', 'es', 'fr', 'de']
                              .map((lang) => DropdownMenuItem(
                                    value: lang,
                                    child: Text(lang.toUpperCase()),
                                  ),)
                              .toList(),
                          onChanged: (lang) => _updateLanguage(lang!),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      );

  Widget _buildTodoSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Todo List (In-Memory)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              StreamBuilder<TodoList>(
                stream: _todoManager.stream,
                initialData: _todoManager.state,
                builder: (context, snapshot) {
                  final todoList = snapshot.data!;
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'Enter todo item...',
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: _addTodoItem,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _addTodoItem('Sample Todo'),
                            child: const Text('Add Sample'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (todoList.items.isEmpty)
                        const Text('No todo items yet')
                      else
                        ...todoList.items.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          return ListTile(
                            leading: Checkbox(
                              value: item.completed,
                              onChanged: (value) =>
                                  _toggleTodoItem(index, value ?? false),
                            ),
                            title: Text(
                              item.title,
                              style: TextStyle(
                                decoration: item.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            subtitle: Text(
                              'Created: ${_formatTime(item.createdAt)}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _removeTodoItem(index),
                            ),
                          );
                        }),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      );

  Widget _buildActionsSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'State Management Actions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: _persistAllStates,
                    child: const Text('Persist All States'),
                  ),
                  ElevatedButton(
                    onPressed: _restoreAllStates,
                    child: const Text('Restore All States'),
                  ),
                  ElevatedButton(
                    onPressed: _clearAllStates,
                    child: const Text('Clear All States'),
                  ),
                  ElevatedButton(
                    onPressed: _showStateStatistics,
                    child: const Text('Show Statistics'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  // Counter actions
  void _incrementCounter() {
    _counterManager.update((state) => CounterState(
          count: state.count + 1,
          lastIncrement: DateTime.now(),
        ),);
  }

  void _decrementCounter() {
    _counterManager.update((state) => CounterState(
          count: state.count - 1,
          lastIncrement: state.lastIncrement,
        ),);
  }

  void _resetCounter() {
    _counterManager.update((state) => CounterState(
          count: 0,
          lastIncrement: DateTime.now(),
        ),);
  }

  // Preferences actions
  void _updateTheme(String theme) {
    _preferencesManager.update((prefs) => UserPreferences(
          theme: theme,
          notifications: prefs.notifications,
          language: prefs.language,
        ),);
  }

  void _updateNotifications(bool enabled) {
    _preferencesManager.update((prefs) => UserPreferences(
          theme: prefs.theme,
          notifications: enabled,
          language: prefs.language,
        ),);
  }

  void _updateLanguage(String language) {
    _preferencesManager.update((prefs) => UserPreferences(
          theme: prefs.theme,
          notifications: prefs.notifications,
          language: language,
        ),);
  }

  // Todo actions
  void _addTodoItem(String title) {
    if (title.trim().isEmpty) return;

    _todoManager.update((todoList) => TodoList(
          items: [
            ...todoList.items,
            TodoItem(
              title: title.trim(),
              completed: false,
              createdAt: DateTime.now(),
            ),
          ],
        ),);
  }

  void _toggleTodoItem(int index, bool completed) {
    _todoManager.update((todoList) {
      final items = List<TodoItem>.from(todoList.items);
      items[index] = TodoItem(
        title: items[index].title,
        completed: completed,
        createdAt: items[index].createdAt,
      );
      return TodoList(items: items);
    });
  }

  void _removeTodoItem(int index) {
    _todoManager.update((todoList) {
      final items = List<TodoItem>.from(todoList.items);
      items.removeAt(index);
      return TodoList(items: items);
    });
  }

  // Global state actions
  Future<void> _persistAllStates() async {
    try {
      await _counterManager.persist();
      await _preferencesManager.persist();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All states persisted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to persist states: $e')),
        );
      }
    }
  }

  Future<void> _restoreAllStates() async {
    try {
      await _counterManager.restore();
      await _preferencesManager.restore();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All states restored successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to restore states: $e')),
        );
      }
    }
  }

  void _clearAllStates() {
    _resetCounter();
    _preferencesManager.update((prefs) => const UserPreferences(
          theme: 'light',
          notifications: true,
          language: 'en',
        ),);
    _todoManager.update((todoList) => const TodoList(items: []));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All states cleared')),
    );
  }

  void _showStateStatistics() {
    final stats = _stateProvider.getStatistics();
    final debugStats = _debugger.getStatistics();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('State Management Statistics'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total State Managers: ${stats.totalManagers}'),
              const SizedBox(height: 8),
              const Text('Registered Types:'),
              ...stats.managerTypes.map((type) => Text('  • $type')),
              const SizedBox(height: 16),
              const Text('Debug Statistics:'),
              Text('Tracked Managers: ${debugStats['trackedManagers']}'),
              const SizedBox(height: 8),
              const Text('Manager Details:'),
              ...(debugStats['managerDetails'] as Map<String, dynamic>)
                  .entries
                  .map((entry) {
                final details = entry.value as Map<String, dynamic>;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('  ${entry.key}:'),
                    Text('    History: ${details['historySize']} transitions'),
                    Text('    Persistence: ${details['supportsPersistence']}'),
                    Text('    Current: ${details['currentState']}'),
                  ],
                );
              }),
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

  void _showDebugInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('State Debug Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Counter State Timeline:'),
              Text(_debugger.generateTimeline<CounterState>()),
              const SizedBox(height: 16),
              const Text('Preferences Timeline:'),
              Text(_debugger.generateTimeline<UserPreferences>()),
              const SizedBox(height: 16),
              const Text('Todo List Timeline:'),
              Text(_debugger.generateTimeline<TodoList>()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _debugger.clearAll();
              Navigator.of(context).pop();
            },
            child: const Text('Clear History'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}:'
      '${time.second.toString().padLeft(2, '0')}';
}

// State classes for the example
class CounterState {
  const CounterState({
    required this.count,
    required this.lastIncrement,
  });

  final int count;
  final DateTime lastIncrement;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CounterState &&
          runtimeType == other.runtimeType &&
          count == other.count &&
          lastIncrement == other.lastIncrement;

  @override
  int get hashCode => count.hashCode ^ lastIncrement.hashCode;

  @override
  String toString() =>
      'CounterState(count: $count, lastIncrement: $lastIncrement)';
}

class UserPreferences {
  const UserPreferences({
    required this.theme,
    required this.notifications,
    required this.language,
  });

  final String theme;
  final bool notifications;
  final String language;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPreferences &&
          runtimeType == other.runtimeType &&
          theme == other.theme &&
          notifications == other.notifications &&
          language == other.language;

  @override
  int get hashCode =>
      theme.hashCode ^ notifications.hashCode ^ language.hashCode;

  @override
  String toString() =>
      'UserPreferences(theme: $theme, notifications: $notifications, language: $language)';
}

class TodoList {
  const TodoList({required this.items});

  final List<TodoItem> items;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoList &&
          runtimeType == other.runtimeType &&
          _listEquals(items, other.items);

  @override
  int get hashCode => items.hashCode;

  @override
  String toString() => 'TodoList(items: ${items.length})';

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class TodoItem {
  const TodoItem({
    required this.title,
    required this.completed,
    required this.createdAt,
  });

  final String title;
  final bool completed;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoItem &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          completed == other.completed &&
          createdAt == other.createdAt;

  @override
  int get hashCode => title.hashCode ^ completed.hashCode ^ createdAt.hashCode;

  @override
  String toString() => 'TodoItem(title: $title, completed: $completed)';
}

// Use the built-in DefaultErrorReporter from the toolkit
