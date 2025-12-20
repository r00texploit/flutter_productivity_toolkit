# Troubleshooting Guide

This guide helps you resolve common issues when using the Flutter Developer Productivity Toolkit.

## Table of Contents

- [Installation Issues](#installation-issues)
- [State Management Issues](#state-management-issues)
- [Navigation Issues](#navigation-issues)
- [Code Generation Issues](#code-generation-issues)
- [Performance Monitoring Issues](#performance-monitoring-issues)
- [Testing Issues](#testing-issues)
- [Build and Compilation Issues](#build-and-compilation-issues)
- [Runtime Errors](#runtime-errors)

## Installation Issues

### Package Not Found

**Problem:** `flutter pub get` fails with "package not found" error.

**Solution:**
1. Verify the package name in `pubspec.yaml`:
   ```yaml
   dependencies:
     flutter_dev_toolkit: ^0.1.0
   ```
2. Run `flutter clean` and then `flutter pub get`
3. Check your Flutter version compatibility (requires Flutter 3.0+)

### Build Runner Dependency Issues

**Problem:** Code generation fails with build_runner errors.

**Solution:**
1. Add build_runner to dev_dependencies:
   ```yaml
   dev_dependencies:
     build_runner: ^2.4.7
   ```
2. Run `flutter packages pub run build_runner clean`
3. Run `flutter packages pub run build_runner build --delete-conflicting-outputs`

### Version Conflicts

**Problem:** Dependency version conflicts during installation.

**Solution:**
1. Check for conflicting packages in `pubspec.yaml`
2. Use dependency overrides if necessary:
   ```yaml
   dependency_overrides:
     meta: ^1.9.0
   ```
3. Run `flutter pub deps` to analyze dependency tree

## State Management Issues

### State Not Updating

**Problem:** UI doesn't update when state changes.

**Symptoms:**
- State manager shows correct values in debugger
- UI remains unchanged after state updates
- No error messages

**Solutions:**
1. Ensure you're using the generated state manager:
   ```dart
   // Wrong - using the state class directly
   final state = CounterState(count: 5);
   
   // Correct - using generated state manager
   final stateManager = CounterStateManager();
   stateManager.update((current) => current.copyWith(count: 5));
   ```

2. Verify widget is listening to state changes:
   ```dart
   StreamBuilder<CounterState>(
     stream: stateManager.stream,
     builder: (context, snapshot) {
       final state = snapshot.data ?? CounterState();
       return Text('Count: ${state.count}');
     },
   )
   ```

3. Check if state manager is properly registered:
   ```dart
   // In main.dart or app initialization
   final provider = StateProvider();
   provider.register<CounterStateManager>(CounterStateManager());
   ```

### State Persistence Not Working

**Problem:** State doesn't persist between app restarts.

**Solutions:**
1. Verify persistence is enabled in annotation:
   ```dart
   @GenerateState(persist: true, storageKey: 'counter')
   class CounterState {
     // ...
   }
   ```

2. Check storage permissions (Android/iOS):
   ```yaml
   # pubspec.yaml
   dependencies:
     shared_preferences: ^2.0.0
   ```

3. Ensure proper initialization:
   ```dart
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await ToolkitConfiguration.initialize();
     runApp(MyApp());
   }
   ```

### Memory Leaks in State Managers

**Problem:** Memory usage increases over time.

**Solutions:**
1. Always dispose state managers:
   ```dart
   @override
   void dispose() {
     stateManager.dispose();
     super.dispose();
   }
   ```

2. Use weak references for listeners:
   ```dart
   stateManager.stream.listen(
     (state) => updateUI(state),
     cancelOnError: true,
   );
   ```

## Navigation Issues

### Routes Not Generated

**Problem:** Generated route classes are missing.

**Solutions:**
1. Run code generation:
   ```bash
   flutter packages pub run build_runner build
   ```

2. Verify route annotation syntax:
   ```dart
   @GenerateRoute('/user/:id/profile')
   class UserProfileRoute {
     final String userId;
     const UserProfileRoute({required this.userId});
   }
   ```

3. Check build.yaml configuration:
   ```yaml
   targets:
     $default:
       builders:
         flutter_dev_toolkit|route_generator:
           enabled: true
   ```

### Deep Links Not Working

**Problem:** Deep links don't navigate to correct screens.

**Solutions:**
1. Configure deep link handling in main.dart:
   ```dart
   final routeBuilder = RouteBuilder();
   routeBuilder.registerDeepLinkHandler(
     '/user/:id',
     (context) => UserProfileRoute(userId: context.params['id']!),
   );
   ```

2. Add URL scheme configuration (iOS):
   ```xml
   <!-- ios/Runner/Info.plist -->
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

3. Add intent filter (Android):
   ```xml
   <!-- android/app/src/main/AndroidManifest.xml -->
   <intent-filter android:autoVerify="true">
     <action android:name="android.intent.action.VIEW" />
     <category android:name="android.intent.category.DEFAULT" />
     <category android:name="android.intent.category.BROWSABLE" />
     <data android:scheme="myapp" />
   </intent-filter>
   ```

### Navigation Stack Issues

**Problem:** Back button behavior is incorrect.

**Solutions:**
1. Use proper navigation methods:
   ```dart
   // For replacing current route
   navigator.pushReplacement('/new-route');
   
   // For adding to stack
   navigator.push('/new-route');
   
   // For clearing stack
   navigator.pushAndClearStack('/home');
   ```

2. Handle system back button:
   ```dart
   WillPopScope(
     onWillPop: () async {
       return navigator.canPop();
     },
     child: YourWidget(),
   )
   ```

## Code Generation Issues

### Generated Files Not Found

**Problem:** Import statements fail for generated files.

**Solutions:**
1. Run build_runner:
   ```bash
   flutter packages pub run build_runner build
   ```

2. Check generated file location:
   ```dart
   // Generated files are typically in the same directory
   import 'counter_state.g.dart'; // Generated file
   ```

3. Clean and rebuild:
   ```bash
   flutter packages pub run build_runner clean
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

### Build Runner Hangs

**Problem:** Code generation process never completes.

**Solutions:**
1. Kill existing processes:
   ```bash
   pkill -f build_runner
   ```

2. Clear build cache:
   ```bash
   flutter clean
   rm -rf .dart_tool/build
   ```

3. Use watch mode for development:
   ```bash
   flutter packages pub run build_runner watch
   ```

### Annotation Not Recognized

**Problem:** Annotations don't trigger code generation.

**Solutions:**
1. Verify annotation import:
   ```dart
   import 'package:flutter_dev_toolkit/flutter_dev_toolkit.dart';
   
   @GenerateState()
   class MyState {
     // ...
   }
   ```

2. Check annotation parameters:
   ```dart
   // Correct
   @GenerateState(persist: true)
   
   // Incorrect - missing parentheses
   @GenerateState
   ```

## Performance Monitoring Issues

### Performance Monitor Not Starting

**Problem:** Performance metrics are not collected.

**Solutions:**
1. Enable monitoring in configuration:
   ```dart
   final config = ToolkitConfiguration(
     performance: PerformanceConfig(
       enableMonitoring: true,
       enableRealTimeAlerts: true,
     ),
   );
   ```

2. Start monitoring explicitly:
   ```dart
   final monitor = PerformanceMonitor();
   monitor.startMonitoring();
   ```

3. Check debug mode:
   ```dart
   // Performance monitoring only works in debug mode
   assert(() {
     monitor.startMonitoring();
     return true;
   }());
   ```

### Inaccurate Performance Metrics

**Problem:** Performance data seems incorrect.

**Solutions:**
1. Ensure proper measurement context:
   ```dart
   // Measure specific operations
   monitor.measureOperation('database_query', () async {
     return await database.query('users');
   });
   ```

2. Exclude development overhead:
   ```dart
   final config = PerformanceConfig(
     excludeDebugOverhead: true,
     measurementInterval: Duration(milliseconds: 100),
   );
   ```

### Memory Leak Detection False Positives

**Problem:** Memory leak warnings for legitimate usage.

**Solutions:**
1. Configure thresholds:
   ```dart
   final config = PerformanceConfig(
     memoryLeakThreshold: Duration(minutes: 5),
     memoryGrowthThreshold: 50.0, // MB
   );
   ```

2. Exclude specific widgets:
   ```dart
   monitor.excludeFromMemoryTracking([
     'CachedNetworkImage',
     'VideoPlayer',
   ]);
   ```

## Testing Issues

### Test Environment Setup Fails

**Problem:** Tests fail during environment initialization.

**Solutions:**
1. Use proper test setup:
   ```dart
   void main() {
     late TestEnvironment testEnv;
     
     setUpAll(() async {
       testEnv = await TestHelper().setupTestEnvironment();
     });
     
     tearDownAll(() async {
       await testEnv.dispose();
     });
   }
   ```

2. Mock external dependencies:
   ```dart
   testWidgets('should work with mocked services', (tester) async {
     final mockService = MockApiService();
     when(mockService.getData()).thenReturn(Future.value(testData));
     
     await testEnv.helper.pumpAndSettle(
       tester,
       MyWidget(service: mockService),
     );
   });
   ```

### Mock State Managers Not Working

**Problem:** Mock state managers don't behave as expected.

**Solutions:**
1. Use proper mock creation:
   ```dart
   final mockState = testEnv.helper.createMockState<CounterState>();
   mockState.setupInitialState(CounterState(count: 5));
   ```

2. Verify mock behavior:
   ```dart
   // Set up expected behavior
   mockState.whenUpdated((state) => state.copyWith(count: state.count + 1));
   
   // Trigger update
   mockState.update((current) => current.copyWith(count: current.count + 1));
   
   // Verify result
   expect(mockState.state.count, equals(6));
   ```

### Integration Tests Failing

**Problem:** Integration tests fail with timeout or setup errors.

**Solutions:**
1. Increase test timeouts:
   ```dart
   testWidgets('integration test', (tester) async {
     tester.binding.defaultTestTimeout = Timeout(Duration(minutes: 2));
     
     await testEnv.helper.pumpAndSettle(tester, MyApp());
   });
   ```

2. Use proper app initialization:
   ```dart
   await testEnv.helper.initializeApp(
     config: ToolkitConfiguration.testing(),
     providers: [
       MockProvider<ApiService>(MockApiService()),
     ],
   );
   ```

## Build and Compilation Issues

### Compilation Errors After Adding Toolkit

**Problem:** Project fails to compile after adding the toolkit.

**Solutions:**
1. Check Flutter version compatibility:
   ```bash
   flutter --version
   # Requires Flutter 3.0.0 or higher
   ```

2. Update dependencies:
   ```bash
   flutter pub upgrade
   ```

3. Clean and rebuild:
   ```bash
   flutter clean
   flutter pub get
   flutter build
   ```

### Import Conflicts

**Problem:** Import statements conflict with existing packages.

**Solutions:**
1. Use selective imports:
   ```dart
   import 'package:flutter_dev_toolkit/flutter_dev_toolkit.dart' 
       show StateManager, RouteBuilder;
   ```

2. Use import aliases:
   ```dart
   import 'package:flutter_dev_toolkit/flutter_dev_toolkit.dart' as toolkit;
   
   final stateManager = toolkit.StateManager<MyState>();
   ```

### Platform-Specific Build Issues

**Problem:** Builds fail on specific platforms.

**Solutions:**

**iOS:**
1. Update iOS deployment target:
   ```ruby
   # ios/Podfile
   platform :ios, '11.0'
   ```

2. Clean iOS build:
   ```bash
   cd ios && rm -rf Pods Podfile.lock && pod install
   ```

**Android:**
1. Update minimum SDK version:
   ```gradle
   // android/app/build.gradle
   minSdkVersion 21
   ```

2. Enable multidex if needed:
   ```gradle
   implementation 'androidx.multidex:multidex:2.0.1'
   ```

## Runtime Errors

### Null Safety Errors

**Problem:** Null safety violations at runtime.

**Solutions:**
1. Use null-aware operators:
   ```dart
   final state = stateManager.state;
   final count = state?.count ?? 0;
   ```

2. Proper null checking:
   ```dart
   if (stateManager.state != null) {
     // Safe to use state
     updateUI(stateManager.state);
   }
   ```

### Async Operation Errors

**Problem:** Errors in async state updates or navigation.

**Solutions:**
1. Use proper error handling:
   ```dart
   try {
     await stateManager.updateAsync((current) async {
       final data = await apiService.fetchData();
       return current.copyWith(data: data);
     });
   } catch (e) {
     // Handle error appropriately
     errorReporter.reportError(e);
   }
   ```

2. Handle navigation errors:
   ```dart
   try {
     await navigator.navigate('/user/profile');
   } on NavigationError catch (e) {
     // Handle navigation-specific errors
     showErrorDialog(e.message);
   }
   ```

### Performance Degradation

**Problem:** App becomes slow after integrating toolkit.

**Solutions:**
1. Disable debug features in production:
   ```dart
   final config = ToolkitConfiguration.production(); // Optimized for performance
   ```

2. Optimize state updates:
   ```dart
   // Batch multiple updates
   stateManager.batchUpdate((current) {
     return current
         .copyWith(field1: value1)
         .copyWith(field2: value2);
   });
   ```

3. Use selective rebuilds:
   ```dart
   StreamBuilder<CounterState>(
     stream: stateManager.stream.where((state) => state.count > 0),
     builder: (context, snapshot) {
       // Only rebuilds when count > 0
     },
   )
   ```

## Getting Help

If you're still experiencing issues:

1. **Check the FAQ**: [docs/faq.md](faq.md)
2. **Search existing issues**: [GitHub Issues](https://github.com/flutter-dev-toolkit/flutter_dev_toolkit/issues)
3. **Create a new issue**: Include:
   - Flutter version (`flutter --version`)
   - Toolkit version
   - Minimal reproduction code
   - Error messages and stack traces
   - Platform information (iOS/Android/Web)

4. **Join discussions**: [GitHub Discussions](https://github.com/flutter-dev-toolkit/flutter_dev_toolkit/discussions)

## Debugging Tips

### Enable Verbose Logging

```dart
final config = ToolkitConfiguration(
  logging: LoggingConfig(
    level: LogLevel.debug,
    enableVerboseLogging: true,
  ),
);
```

### Use Debug Tools

```dart
// Enable debug mode for detailed information
assert(() {
  ToolkitDebugger.enableDebugMode();
  return true;
}());
```

### Performance Profiling

```dart
// Profile specific operations
final profiler = PerformanceProfiler();
profiler.profile('state_update', () {
  stateManager.update((current) => current.copyWith(data: newData));
});
```