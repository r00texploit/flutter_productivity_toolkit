import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'error_reporter.dart';
import 'toolkit_error.dart';

/// Enhanced error handler that provides detailed error messages with
/// suggested solutions and platform-specific guidance.
class EnhancedErrorHandler implements ErrorHandler {
  /// Creates a new enhanced error handler.
  const EnhancedErrorHandler();

  @override
  int get priority => 100;

  @override
  bool canHandle(ErrorCategory category) => true;

  @override
  Future<bool> handleError(ToolkitError error) async {
    final enhancedMessage = _enhanceErrorMessage(error);
    final suggestion = _generateSuggestion(error);
    final platformSpecificAdvice = _getPlatformSpecificAdvice(error);

    // Log enhanced error information
    if (kDebugMode) {
      debugPrint('=== Enhanced Error Report ===');
      debugPrint('Category: ${error.category}');
      debugPrint('Message: $enhancedMessage');
      if (suggestion != null) {
        debugPrint('Suggestion: $suggestion');
      }
      if (platformSpecificAdvice != null) {
        debugPrint('Platform Advice: $platformSpecificAdvice');
      }
      if (error.context != null) {
        debugPrint('Context: ${error.context}');
      }
      debugPrint('============================');
    }

    return false; // Allow other handlers to process as well
  }

  @override
  Future<bool> handleWarning(WarningReport warning) async {
    if (kDebugMode) {
      debugPrint('=== Enhanced Warning ===');
      debugPrint('Message: ${warning.message}');
      if (warning.suggestion != null) {
        debugPrint('Suggestion: ${warning.suggestion}');
      }
      debugPrint('=======================');
    }
    return false;
  }

  @override
  Future<bool> handleInfo(InfoReport info) async {
    if (kDebugMode) {
      debugPrint('Info: ${info.message}');
    }
    return false;
  }

  /// Enhances the error message with additional context and clarity.
  String _enhanceErrorMessage(ToolkitError error) {
    final buffer = StringBuffer();
    buffer.write(error.message);

    // Add category-specific context
    switch (error.category) {
      case ErrorCategory.stateManagement:
        buffer.write(' This error occurred in the state management system.');
        break;
      case ErrorCategory.navigation:
        buffer.write(' This error occurred during navigation.');
        break;
      case ErrorCategory.codeGeneration:
        buffer.write(' This error occurred during code generation.');
        break;
      case ErrorCategory.testing:
        buffer.write(' This error occurred in the testing framework.');
        break;
      case ErrorCategory.performance:
        buffer.write(' This error occurred in performance monitoring.');
        break;
      case ErrorCategory.configuration:
        buffer.write(' This error is related to configuration.');
        break;
      case ErrorCategory.developmentTools:
        buffer.write(' This error occurred in development tools.');
        break;
      case ErrorCategory.fileSystem:
        buffer.write(' This error is related to file system operations.');
        break;
      case ErrorCategory.network:
        buffer.write(' This error is related to network operations.');
        break;
      case ErrorCategory.validation:
        buffer.write(' This error is related to data validation.');
        break;
      case ErrorCategory.unknown:
        buffer.write(' The cause of this error is unknown.');
        break;
    }

    return buffer.toString();
  }

  /// Generates actionable suggestions based on the error type and context.
  String? _generateSuggestion(ToolkitError error) {
    if (error.suggestion != null) {
      return error.suggestion;
    }

    switch (error.category) {
      case ErrorCategory.stateManagement:
        return _getStateManagementSuggestion(error);
      case ErrorCategory.navigation:
        return _getNavigationSuggestion(error);
      case ErrorCategory.codeGeneration:
        return _getCodeGenerationSuggestion(error);
      case ErrorCategory.testing:
        return _getTestingSuggestion(error);
      case ErrorCategory.performance:
        return _getPerformanceSuggestion(error);
      case ErrorCategory.configuration:
        return _getConfigurationSuggestion(error);
      case ErrorCategory.developmentTools:
        return _getDevelopmentToolsSuggestion(error);
      case ErrorCategory.fileSystem:
        return 'Check file permissions and ensure the file path exists.';
      case ErrorCategory.network:
        return 'Verify network connectivity and check API endpoints.';
      case ErrorCategory.validation:
        return 'Review the data format and ensure all required fields are present.';
      case ErrorCategory.unknown:
        return 'Try restarting the application or check the Flutter logs for more details.';
    }
  }

  /// Gets platform-specific advice for resolving the error.
  String? _getPlatformSpecificAdvice(ToolkitError error) {
    if (Platform.isAndroid) {
      return _getAndroidSpecificAdvice(error);
    } else if (Platform.isIOS) {
      return _getIOSSpecificAdvice(error);
    } else if (Platform.isWindows) {
      return _getWindowsSpecificAdvice(error);
    } else if (Platform.isMacOS) {
      return _getMacOSSpecificAdvice(error);
    } else if (Platform.isLinux) {
      return _getLinuxSpecificAdvice(error);
    }
    return null;
  }

  String? _getStateManagementSuggestion(ToolkitError error) {
    if (error.message.contains('disposed')) {
      return 'Ensure the state manager is not accessed after disposal. '
          'Check widget lifecycle and dispose patterns.';
    }
    if (error.message.contains('not found')) {
      return 'Register the state manager with the dependency injection container '
          'before trying to access it.';
    }
    if (error.message.contains('circular dependency')) {
      return 'Review your state manager dependencies to avoid circular references. '
          'Consider using lazy initialization or breaking the dependency cycle.';
    }
    return 'Check state manager initialization and ensure proper lifecycle management.';
  }

  String? _getNavigationSuggestion(ToolkitError error) {
    if (error.message.contains('route not found')) {
      return 'Ensure the route is properly registered in your route configuration. '
          'Check for typos in the route path.';
    }
    if (error.message.contains('parameter')) {
      return 'Verify that all required route parameters are provided and have the correct types.';
    }
    if (error.message.contains('deep link')) {
      return 'Check your deep link configuration and ensure the URL pattern matches your route definition.';
    }
    return 'Review your navigation setup and route definitions.';
  }

  String? _getCodeGenerationSuggestion(ToolkitError error) {
    if (error.message.contains('annotation')) {
      return 'Check the annotation syntax and ensure all required parameters are provided. '
          'Run "flutter packages pub run build_runner clean" and try again.';
    }
    if (error.message.contains('build_runner')) {
      return 'Run "flutter packages pub run build_runner build --delete-conflicting-outputs" '
          'to regenerate the code.';
    }
    return 'Clean and rebuild the generated code using build_runner.';
  }

  String? _getTestingSuggestion(ToolkitError error) {
    if (error.message.contains('mock')) {
      return 'Ensure mock objects are properly configured and implement all required methods.';
    }
    if (error.message.contains('widget test')) {
      return 'Check that all required providers and dependencies are available in the test environment.';
    }
    return 'Review test setup and ensure all dependencies are properly mocked or provided.';
  }

  String? _getPerformanceSuggestion(ToolkitError error) {
    if (error.message.contains('memory')) {
      return 'Check for memory leaks by reviewing object disposal and stream subscriptions. '
          'Use the Flutter Inspector to analyze widget tree depth.';
    }
    if (error.message.contains('rebuild')) {
      return 'Optimize widget rebuilds by using const constructors, keys, and proper state management.';
    }
    return 'Use the Flutter Performance tools to identify bottlenecks.';
  }

  String? _getConfigurationSuggestion(ToolkitError error) {
    if (error.message.contains('pubspec')) {
      return 'Check your pubspec.yaml file for syntax errors and ensure all dependencies are properly declared.';
    }
    if (error.message.contains('asset')) {
      return 'Verify that asset paths in pubspec.yaml match the actual file locations.';
    }
    return 'Review configuration files for syntax errors and missing required fields.';
  }

  String? _getDevelopmentToolsSuggestion(ToolkitError error) {
    if (error.message.contains('analysis')) {
      return 'Check your analysis_options.yaml file and ensure it follows the correct format.';
    }
    if (error.message.contains('lint')) {
      return 'Review the linting rules and fix any code style issues reported.';
    }
    return 'Update your development tools and check for configuration issues.';
  }

  String? _getAndroidSpecificAdvice(ToolkitError error) {
    switch (error.category) {
      case ErrorCategory.fileSystem:
        return 'On Android, check app permissions in AndroidManifest.xml for file access.';
      case ErrorCategory.network:
        return 'Ensure INTERNET permission is declared in AndroidManifest.xml.';
      case ErrorCategory.performance:
        return 'Use Android Studio Profiler to analyze performance on Android devices.';
      default:
        return null;
    }
  }

  String? _getIOSSpecificAdvice(ToolkitError error) {
    switch (error.category) {
      case ErrorCategory.fileSystem:
        return "On iOS, ensure you're accessing files within the app sandbox.";
      case ErrorCategory.network:
        return 'Check Info.plist for network security settings and App Transport Security.';
      case ErrorCategory.performance:
        return 'Use Xcode Instruments to profile performance on iOS devices.';
      default:
        return null;
    }
  }

  String? _getWindowsSpecificAdvice(ToolkitError error) {
    switch (error.category) {
      case ErrorCategory.fileSystem:
        return 'On Windows, check file path length limits and special characters.';
      case ErrorCategory.configuration:
        return 'Ensure Windows-specific configuration in windows/runner is correct.';
      default:
        return null;
    }
  }

  String? _getMacOSSpecificAdvice(ToolkitError error) {
    switch (error.category) {
      case ErrorCategory.fileSystem:
        return 'On macOS, check app sandbox entitlements for file access.';
      case ErrorCategory.configuration:
        return 'Verify macOS-specific configuration in macos/Runner.';
      default:
        return null;
    }
  }

  String? _getLinuxSpecificAdvice(ToolkitError error) {
    switch (error.category) {
      case ErrorCategory.fileSystem:
        return 'On Linux, check file permissions and user access rights.';
      case ErrorCategory.configuration:
        return 'Ensure Linux-specific dependencies are installed.';
      default:
        return null;
    }
  }
}
