# API Reference

This document provides a comprehensive reference for all public APIs in the Flutter Developer Productivity Toolkit.

## Core Classes and Interfaces

### State Management

#### StateManager<T>
Abstract base class for all state managers in the toolkit.

```dart
abstract class StateManager<T> {
  /// Current state value
  T get state;
  
  /// Stream of state changes
  Stream<T> get stream;
  
  /// Update state using a function
  void update(T Function(T current) updater);
  
  /// Dispose resources
  void dispose();
}
```

**Methods:**
- `update(T Function(T current) updater)`: Updates the state by applying the updater function to the current state
- `dispose()`: Cleans up resources and closes streams

**Properties:**
- `state`: Returns the current state value
- `stream`: Returns a stream that emits state changes

#### StateProvider
Manages dependency injection for state managers.

```dart
abstract class StateProvider {
  /// Get or create a state manager instance
  T provide<T extends StateManager>();
  
  /// Register a state manager instance
  void register<T extends StateManager>(T manager);
}
```

### Navigation

#### RouteBuilder
Core interface for route management and navigation.

```dart
abstract class RouteBuilder {
  /// Define a new route with typed parameters
  void defineRoute<T>(String path, Widget Function(T params) builder);
  
  /// Navigate to a route with optional parameters
  Future<R?> navigate<T, R>(String path, {T? params});
  
  /// Register a deep link handler
  void registerDeepLinkHandler(String pattern, RouteHandler handler);
}
```

#### NavigationStack
Manages navigation history and stack operations.

```dart
abstract class NavigationStack {
  /// Push a new route onto the stack
  void push(Route route);
  
  /// Pop the current route
  void pop<T>([T? result]);
  
  /// Replace the current route
  void pushReplacement(Route route);
  
  /// Get navigation history
  List<Route> get history;
}
```

### Testing

#### TestHelper
Provides utilities for testing Flutter applications.

```dart
abstract class TestHelper {
  /// Wrap widget with necessary providers for testing
  Widget wrapWithProviders(Widget child, {List<Provider>? providers});
  
  /// Pump widget and wait for animations to settle
  Future<void> pumpAndSettle(WidgetTester tester, Widget widget);
  
  /// Create a mock state manager for testing
  MockStateManager<T> createMockState<T>();
}
```

#### TestDataFactory
Generates realistic test data for testing scenarios.

```dart
abstract class TestDataFactory {
  /// Create a single instance of type T
  T create<T>({Map<String, dynamic>? overrides});
  
  /// Create a list of instances
  List<T> createList<T>(int count, {Map<String, dynamic>? baseData});
}
```

### Performance Monitoring

#### PerformanceMonitor
Monitors application performance in real-time.

```dart
abstract class PerformanceMonitor {
  /// Start performance monitoring
  void startMonitoring();
  
  /// Stop performance monitoring
  void stopMonitoring();
  
  /// Stream of performance metrics
  Stream<PerformanceMetrics> get metricsStream;
  
  /// Report custom performance metric
  void reportCustomMetric(String name, double value);
}
```

#### PerformanceMetrics
Contains performance measurement data.

```dart
class PerformanceMetrics {
  /// Number of dropped frames
  final int frameDrops;
  
  /// Current memory usage in MB
  final double memoryUsage;
  
  /// Widget rebuild counts by type
  final Map<String, int> widgetRebuildCounts;
  
  /// Performance warnings
  final List<PerformanceWarning> warnings;
  
  /// Whether performance is within acceptable thresholds
  bool get isPerformanceGood;
}
```

### Code Generation

#### CodeGenerator
Base class for build_runner code generators.

```dart
abstract class CodeGenerator extends Builder {
  /// Generate state managers from annotations
  Future<void> generateStateManagers(BuildStep buildStep);
  
  /// Generate routes from annotations
  Future<void> generateRoutes(BuildStep buildStep);
  
  /// Generate data models from annotations
  Future<void> generateDataModels(BuildStep buildStep);
}
```

### Configuration

#### ToolkitConfiguration
Main configuration class for the toolkit.

```dart
class ToolkitConfiguration {
  /// State management configuration
  final StateManagementConfig stateManagement;
  
  /// Navigation configuration
  final NavigationConfig navigation;
  
  /// Performance monitoring configuration
  final PerformanceConfig performance;
  
  /// Testing configuration
  final TestingConfig testing;
  
  /// Development tools configuration
  final DevelopmentToolsConfig developmentTools;
  
  /// Create development configuration
  factory ToolkitConfiguration.development();
  
  /// Create production configuration
  factory ToolkitConfiguration.production();
  
  /// Create testing configuration
  factory ToolkitConfiguration.testing();
}
```

## Annotations

### @GenerateState
Marks a class for state manager generation.

```dart
class GenerateState {
  /// Whether to enable state persistence
  final bool persist;
  
  /// Storage key for persistence
  final String? storageKey;
  
  const GenerateState({this.persist = false, this.storageKey});
}
```

**Usage:**
```dart
@GenerateState(persist: true, storageKey: 'counter')
class CounterState {
  final int count;
  const CounterState({this.count = 0});
}
```

### @GenerateRoute
Marks a class for route generation.

```dart
class GenerateRoute {
  /// Route path pattern
  final String path;
  
  /// Whether route requires authentication
  final bool requiresAuth;
  
  const GenerateRoute(this.path, {this.requiresAuth = false});
}
```

**Usage:**
```dart
@GenerateRoute('/user/:id/profile', requiresAuth: true)
class UserProfileRoute {
  final String userId;
  const UserProfileRoute({required this.userId});
}
```

### @GenerateModel
Marks a class for data model generation.

```dart
class GenerateModel {
  /// Whether to generate serialization methods
  final bool serializable;
  
  /// Whether to generate equality methods
  final bool equatable;
  
  const GenerateModel({this.serializable = true, this.equatable = true});
}
```

## Error Types

### ToolkitError
Base error class for all toolkit-related errors.

```dart
class ToolkitError extends Error {
  /// Error category
  final ErrorCategory category;
  
  /// Error message
  final String message;
  
  /// Suggested solution
  final String? suggestion;
  
  /// Original stack trace
  final StackTrace? originalStackTrace;
  
  /// Additional context
  final Map<String, dynamic>? context;
}
```

### ErrorCategory
Enumeration of error categories.

```dart
enum ErrorCategory {
  configuration,
  runtime,
  generation,
  performance,
  testing,
}
```

## Development Tools

### PubOptimizer
Analyzes and optimizes packages for pub.dev publishing.

```dart
abstract class PubOptimizer {
  /// Analyze package for optimization opportunities
  Future<OptimizationReport> analyzePackage(String packagePath);
  
  /// Generate publication report
  Future<PublicationReport> generatePublicationReport(String packagePath);
  
  /// Validate package metadata
  Future<ValidationResult> validateMetadata(String packagePath);
}
```

### ProjectMaintenance
Provides utilities for maintaining project structure and code quality.

```dart
abstract class ProjectMaintenance {
  /// Optimize import statements
  Future<void> optimizeImports(String projectPath);
  
  /// Validate project structure
  Future<ValidationResult> validateProjectStructure(String projectPath);
  
  /// Generate asset reference classes
  Future<void> generateAssetReferences(String projectPath);
}
```

## Constants and Enums

### PerformanceThresholds
Default performance thresholds used by the monitoring system.

```dart
class PerformanceThresholds {
  static const int maxFrameDropsPerSecond = 3;
  static const double minFps = 58.0;
  static const double maxMemoryUsageMB = 512.0;
  static const int maxWidgetRebuildsPerSecond = 60;
}
```

### LogLevel
Logging levels for the toolkit.

```dart
enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}
```

## Type Definitions

### RouteHandler
Function signature for handling route navigation.

```dart
typedef RouteHandler = Future<void> Function(RouteContext context);
```

### StateUpdater<T>
Function signature for state update operations.

```dart
typedef StateUpdater<T> = T Function(T current);
```

### PerformanceCallback
Function signature for performance event callbacks.

```dart
typedef PerformanceCallback = void Function(PerformanceMetrics metrics);
```

## Extension Methods

### BuildContextExtensions
Convenient extensions for BuildContext.

```dart
extension BuildContextExtensions on BuildContext {
  /// Get state manager from context
  T state<T extends StateManager>();
  
  /// Navigate using context
  Future<R?> navigate<T, R>(String path, {T? params});
  
  /// Get performance monitor from context
  PerformanceMonitor get performance;
}
```

### WidgetExtensions
Extensions for Widget testing and debugging.

```dart
extension WidgetExtensions on Widget {
  /// Wrap widget with test providers
  Widget withTestProviders({List<Provider>? providers});
  
  /// Add performance monitoring to widget
  Widget withPerformanceMonitoring();
}
```

## Migration Helpers

### ProviderMigrationHelper
Helps migrate from Provider package.

```dart
class ProviderMigrationHelper {
  /// Convert Provider to StateManager
  static StateManager<T> convertProvider<T>(ChangeNotifierProvider<T> provider);
  
  /// Generate migration report
  static MigrationReport analyzeMigration(String projectPath);
}
```

### BlocMigrationHelper
Helps migrate from Bloc package.

```dart
class BlocMigrationHelper {
  /// Convert Bloc to StateManager
  static StateManager<T> convertBloc<T>(Bloc<dynamic, T> bloc);
  
  /// Convert Cubit to StateManager
  static StateManager<T> convertCubit<T>(Cubit<T> cubit);
}
```

This API reference covers all major public interfaces and classes. For more detailed examples and usage patterns, see the individual feature documentation and the examples directory.