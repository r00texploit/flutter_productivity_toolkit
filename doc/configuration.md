# Configuration Guide

The Flutter Productivity Toolkit provides flexible configuration options to customize its behavior for different environments and use cases.

## Overview

The toolkit uses a centralized configuration system through the `ToolkitConfiguration` class. This allows you to customize all aspects of the toolkit's behavior from a single location.

## Pre-configured Setups

### Development Configuration

Optimized for development with debugging features enabled:

```dart
final config = ToolkitConfiguration.development();
```

Features enabled:
- Verbose logging
- Real-time performance monitoring
- Debug overlays
- Hot reload support
- Extended error messages

### Production Configuration

Optimized for production with minimal overhead:

```dart
final config = ToolkitConfiguration.production();
```

Features enabled:
- Minimal logging
- Performance optimizations
- Error reporting
- Reduced memory footprint

### Testing Configuration

Configured for reliable test execution:

```dart
final config = ToolkitConfiguration.testing();
```

Features enabled:
- Deterministic behavior
- Mock-friendly setup
- Fast execution
- Comprehensive logging for debugging

## Custom Configuration

Create a custom configuration by specifying individual components:

```dart
final config = ToolkitConfiguration(
  stateManagement: StateManagementConfig(
    enableDebugging: true,
    enablePersistence: true,
    persistenceKey: 'my_app_state',
  ),
  navigation: NavigationConfig(
    enableDeepLinking: true,
    enableTransitions: true,
    defaultTransition: TransitionType.slide,
  ),
  performance: PerformanceConfig(
    enableMonitoring: true,
    thresholds: PerformanceThresholds(
      maxFrameDropsPerSecond: 3,
      minFps: 58.0,
      maxMemoryUsageMB: 512,
    ),
  ),
  testing: TestingConfig(
    enableMockData: true,
    seedValue: 42,
  ),
  codeGeneration: CodeGenerationConfig(
    outputDirectory: 'lib/generated',
    enableNullSafety: true,
  ),
);
```

## Configuration Components

### State Management Configuration

```dart
StateManagementConfig(
  enableDebugging: bool,        // Enable debug tools
  enablePersistence: bool,      // Auto-save state
  persistenceKey: String,       // Storage key prefix
  enableTimeTravel: bool,       // Enable state history
  maxHistorySize: int,          // Max history entries
)
```

### Navigation Configuration

```dart
NavigationConfig(
  enableDeepLinking: bool,      // Handle deep links
  enableTransitions: bool,      // Animate transitions
  defaultTransition: TransitionType, // Default animation
  enableRouteGuards: bool,      // Authentication checks
  enableLogging: bool,          // Log navigation events
)
```

### Performance Configuration

```dart
PerformanceConfig(
  enableMonitoring: bool,       // Real-time monitoring
  thresholds: PerformanceThresholds, // Performance limits
  enableMemoryTracking: bool,   // Track memory usage
  enableFrameTracking: bool,    // Track frame drops
  reportingInterval: Duration,  // Metrics reporting frequency
)
```

### Testing Configuration

```dart
TestingConfig(
  enableMockData: bool,         // Use mock data generators
  seedValue: int,               // Random seed for consistency
  enableTestHelpers: bool,      // Additional test utilities
  mockNetworkCalls: bool,       // Mock HTTP requests
)
```

### Code Generation Configuration

```dart
CodeGenerationConfig(
  outputDirectory: String,      // Generated code location
  enableNullSafety: bool,       // Generate null-safe code
  enableDocumentation: bool,    // Generate documentation
  enableValidation: bool,       // Add validation code
)
```

## Environment-Specific Configuration

### Using Environment Variables

```dart
final config = ToolkitConfiguration(
  performance: PerformanceConfig(
    enableMonitoring: bool.fromEnvironment('ENABLE_MONITORING', defaultValue: false),
  ),
  // ... other configurations
);
```

### Conditional Configuration

```dart
final config = kDebugMode 
  ? ToolkitConfiguration.development()
  : ToolkitConfiguration.production();
```

## Runtime Configuration Updates

Some configuration options can be updated at runtime:

```dart
// Update performance thresholds
PerformanceMonitor.instance.updateThresholds(
  PerformanceThresholds(
    maxFrameDropsPerSecond: 5,
    minFps: 55.0,
  ),
);

// Toggle debugging
StateManager.instance.setDebuggingEnabled(true);
```

## Configuration Validation

The toolkit validates configuration at startup and provides helpful error messages:

```dart
try {
  final config = ToolkitConfiguration(/* ... */);
  await ToolkitInitializer.initialize(config);
} on ConfigurationException catch (e) {
  print('Configuration error: ${e.message}');
  print('Suggestions: ${e.suggestions}');
}
```

## Best Practices

1. **Use pre-configured setups** when possible for consistency
2. **Validate configuration** in development builds
3. **Document custom configurations** for team members
4. **Use environment variables** for deployment-specific settings
5. **Test configuration changes** thoroughly before deployment

## Examples

### Mobile App Configuration

```dart
final config = ToolkitConfiguration(
  performance: PerformanceConfig(
    enableMonitoring: kDebugMode,
    thresholds: PerformanceThresholds(
      maxFrameDropsPerSecond: 2,
      minFps: 60.0,
      maxMemoryUsageMB: 256,
    ),
  ),
  stateManagement: StateManagementConfig(
    enablePersistence: true,
    enableTimeTravel: kDebugMode,
  ),
);
```

### Web App Configuration

```dart
final config = ToolkitConfiguration(
  navigation: NavigationConfig(
    enableDeepLinking: true,
    enableTransitions: false, // Better web performance
  ),
  performance: PerformanceConfig(
    enableMonitoring: false, // Not needed for web
  ),
);
```

### Testing Configuration

```dart
final config = ToolkitConfiguration.testing().copyWith(
  testing: TestingConfig(
    seedValue: 12345, // Consistent test data
    enableMockData: true,
  ),
);
```