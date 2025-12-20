# Installation Guide

This guide provides detailed instructions for installing and setting up the Flutter Developer Productivity Toolkit in your project.

## Prerequisites

Before installing the toolkit, ensure you have:

- **Flutter 3.0.0 or higher** - [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Dart 2.17.0 or higher** - Included with Flutter
- **A Flutter project** - Create one with `flutter create my_app`

### Verify Your Environment

Check your Flutter installation:

```bash
flutter doctor
flutter --version
```

Expected output should show Flutter 3.0.0+ and Dart 2.17.0+.

## Installation Methods

### Method 1: Standard Installation (Recommended)

Add the toolkit to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_dev_toolkit: ^0.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.7
```

Then run:

```bash
flutter pub get
```

### Method 2: Development Version

To use the latest development version:

```yaml
dependencies:
  flutter_dev_toolkit:
    git:
      url: https://github.com/flutter-dev-toolkit/flutter_dev_toolkit.git
      ref: main
```

### Method 3: Local Development

For contributing or local modifications:

```yaml
dependencies:
  flutter_dev_toolkit:
    path: ../path/to/flutter_dev_toolkit
```

## Initial Setup

### 1. Initialize the Toolkit

Update your `main.dart` file:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_dev_toolkit/flutter_dev_toolkit.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the toolkit
  final config = ToolkitConfiguration.development();
  await config.initialize();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      home: MyHomePage(),
    );
  }
}
```

### 2. Configure Build Runner

Create or update `build.yaml` in your project root:

```yaml
targets:
  $default:
    builders:
      flutter_dev_toolkit|state_generator:
        enabled: true
        options:
          generate_for:
            - lib/**
      flutter_dev_toolkit|route_generator:
        enabled: true
        options:
          generate_for:
            - lib/**
      flutter_dev_toolkit|model_generator:
        enabled: true
        options:
          generate_for:
            - lib/**
```

### 3. Update Analysis Options

Add toolkit-specific linting rules to `analysis_options.yaml`:

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  plugins:
    - flutter_dev_toolkit

linter:
  rules:
    # Toolkit-specific rules
    prefer_toolkit_state_management: true
    prefer_type_safe_navigation: true
    avoid_manual_state_mutations: true
    
    # Enhanced Flutter rules
    prefer_const_constructors: true
    prefer_const_literals_to_create_immutables: true
    avoid_unnecessary_containers: true
```

## Configuration Options

### Development Configuration

For development with full debugging and monitoring:

```dart
final config = ToolkitConfiguration.development();
```

This enables:
- Performance monitoring
- Verbose logging
- State debugging
- Real-time linting
- Memory leak detection

### Production Configuration

For production builds with optimized performance:

```dart
final config = ToolkitConfiguration.production();
```

This enables:
- Minimal logging
- Optimized performance
- Error reporting
- Disabled debugging features

### Testing Configuration

For test environments:

```dart
final config = ToolkitConfiguration.testing();
```

This enables:
- Mock-friendly setup
- Deterministic behavior
- Fast test execution
- Isolated environments

### Custom Configuration

For fine-grained control:

```dart
final config = ToolkitConfiguration(
  stateManagement: StateManagementConfig(
    enablePersistence: true,
    enableDebugging: true,
    storageBackend: SharedPreferencesStorage(),
  ),
  navigation: NavigationConfig(
    enableDeepLinking: true,
    enableTypeValidation: true,
  ),
  performance: PerformanceConfig(
    enableMonitoring: true,
    enableRealTimeAlerts: true,
    thresholds: PerformanceThresholds(
      maxFrameDropsPerSecond: 3,
      maxMemoryUsageMB: 512,
    ),
  ),
  testing: TestingConfig(
    enableMockGeneration: true,
    enableTestDataFactories: true,
  ),
  developmentTools: DevelopmentToolsConfig(
    enableLinting: true,
    enableAssetGeneration: true,
    enablePubOptimization: true,
  ),
  logging: LoggingConfig(
    level: LogLevel.info,
    enableFileLogging: false,
  ),
);
```

## Platform-Specific Setup

### Android Configuration

Add to `android/app/build.gradle`:

```gradle
android {
    compileSdkVersion 33
    
    defaultConfig {
        minSdkVersion 21  // Required for toolkit features
        targetSdkVersion 33
    }
}

dependencies {
    // Required for performance monitoring
    implementation 'androidx.lifecycle:lifecycle-process:2.6.1'
}
```

### iOS Configuration

Update `ios/Runner/Info.plist` for deep linking:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>myapp.deeplink</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>myapp</string>
        </array>
    </dict>
</array>
```

Update `ios/Podfile`:

```ruby
platform :ios, '11.0'  # Minimum required version

target 'Runner' do
  use_frameworks!
  use_modular_headers!
  
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end
```

### Web Configuration

Add to `web/index.html`:

```html
<head>
  <!-- Existing head content -->
  
  <!-- Toolkit web support -->
  <script src="flutter_dev_toolkit_web.js" defer></script>
</head>
```

### Desktop Configuration

No additional configuration required for desktop platforms.

## Code Generation Setup

### Initial Generation

After installation, run code generation:

```bash
flutter packages pub run build_runner build
```

### Watch Mode (Development)

For automatic regeneration during development:

```bash
flutter packages pub run build_runner watch
```

### Clean and Rebuild

If you encounter issues:

```bash
flutter packages pub run build_runner clean
flutter packages pub run build_runner build --delete-conflicting-outputs
```

## Verification

### 1. Test Basic Functionality

Create a simple test to verify installation:

```dart
// test/installation_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dev_toolkit/flutter_dev_toolkit.dart';

void main() {
  test('toolkit initialization', () async {
    final config = ToolkitConfiguration.testing();
    await config.initialize();
    
    expect(config.isInitialized, isTrue);
  });
}
```

Run the test:

```bash
flutter test test/installation_test.dart
```

### 2. Verify Code Generation

Create a simple state class:

```dart
// lib/test_state.dart
import 'package:flutter_dev_toolkit/flutter_dev_toolkit.dart';

@GenerateState()
class TestState {
  final String message;
  
  const TestState({this.message = 'Hello, Toolkit!'});
  
  TestState copyWith({String? message}) {
    return TestState(message: message ?? this.message);
  }
}
```

Run code generation:

```bash
flutter packages pub run build_runner build
```

Verify that `test_state.g.dart` is created with `TestStateManager`.

### 3. Test Performance Monitoring

Add to your app:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final config = ToolkitConfiguration.development();
  await config.initialize();
  
  // Verify performance monitoring
  final monitor = PerformanceMonitor.instance;
  monitor.startMonitoring();
  
  runApp(MyApp());
}
```

## Troubleshooting Installation

### Common Issues

#### 1. Build Runner Fails

**Error**: `Could not find package flutter_dev_toolkit`

**Solution**:
```bash
flutter clean
flutter pub get
flutter packages pub run build_runner clean
flutter packages pub run build_runner build
```

#### 2. Version Conflicts

**Error**: `version solving failed`

**Solution**: Check for conflicting dependencies and use overrides:

```yaml
dependency_overrides:
  meta: ^1.9.0
  analyzer: ^5.13.0
```

#### 3. Import Errors

**Error**: `Target of URI doesn't exist`

**Solution**: Ensure you've run code generation:

```bash
flutter packages pub run build_runner build
```

#### 4. Platform Build Errors

**Android Error**: `Minimum supported Gradle version is 7.0.2`

**Solution**: Update `android/gradle/wrapper/gradle-wrapper.properties`:

```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-7.6-all.zip
```

**iOS Error**: `Podfile out of date`

**Solution**:
```bash
cd ios
rm Podfile.lock
rm -rf Pods
pod install
```

### Getting Help

If you encounter issues not covered here:

1. Check the [Troubleshooting Guide](troubleshooting.md)
2. Search [GitHub Issues](https://github.com/flutter-dev-toolkit/flutter_dev_toolkit/issues)
3. Ask in [GitHub Discussions](https://github.com/flutter-dev-toolkit/flutter_dev_toolkit/discussions)

## Next Steps

After successful installation:

1. **[Quick Start Tutorial](quick_start.md)** - Build your first app
2. **[Configuration Guide](configuration.md)** - Customize the toolkit
3. **[State Management Guide](state_management.md)** - Learn reactive state management
4. **[Examples](../example/README.md)** - Explore sample applications

## Updating the Toolkit

### Check for Updates

```bash
flutter pub outdated
```

### Update to Latest Version

```yaml
dependencies:
  flutter_dev_toolkit: ^0.2.0  # Update version
```

Then run:

```bash
flutter pub get
flutter packages pub run build_runner build
```

### Migration Between Versions

Check the [CHANGELOG.md](../CHANGELOG.md) for breaking changes and migration instructions when updating major versions.

## Uninstalling

To remove the toolkit:

1. Remove from `pubspec.yaml`:
   ```yaml
   dependencies:
     # flutter_dev_toolkit: ^0.1.0  # Remove this line
   ```

2. Clean generated files:
   ```bash
   flutter packages pub run build_runner clean
   find lib -name "*.g.dart" -delete
   ```

3. Remove configuration:
   ```bash
   rm build.yaml  # If only used for toolkit
   ```

4. Update imports and remove toolkit-specific code

The toolkit is designed for easy removal with minimal impact on your existing Flutter code.