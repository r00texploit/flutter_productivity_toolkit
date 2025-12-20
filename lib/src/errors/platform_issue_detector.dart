import 'dart:io';
import 'package:flutter/foundation.dart';
import 'toolkit_error.dart';

/// Detects platform-specific issues and provides targeted solutions.
class PlatformIssueDetector {
  static bool _isEnabled = kDebugMode;

  /// Enables or disables platform issue detection.
  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Checks if platform issue detection is enabled.
  static bool get isEnabled => _isEnabled;

  /// Analyzes an error and detects platform-specific issues.
  static List<PlatformIssue> analyzeError(
    error,
    StackTrace stackTrace, {
    ErrorCategory? category,
  }) {
    if (!_isEnabled) return [];

    final issues = <PlatformIssue>[];
    final errorMessage = error.toString().toLowerCase();
    final stackTraceString = stackTrace.toString().toLowerCase();

    // Detect platform-specific issues based on error patterns
    issues.addAll(_detectAndroidIssues(errorMessage, stackTraceString));
    issues.addAll(_detectIOSIssues(errorMessage, stackTraceString));
    issues.addAll(_detectWindowsIssues(errorMessage, stackTraceString));
    issues.addAll(_detectMacOSIssues(errorMessage, stackTraceString));
    issues.addAll(_detectLinuxIssues(errorMessage, stackTraceString));
    issues.addAll(_detectWebIssues(errorMessage, stackTraceString));

    // Add category-specific platform issues
    if (category != null) {
      issues.addAll(_detectCategorySpecificIssues(category, errorMessage));
    }

    return issues;
  }

  /// Gets platform-specific configuration recommendations.
  static List<PlatformRecommendation> getPlatformRecommendations() {
    if (!_isEnabled) return [];

    final recommendations = <PlatformRecommendation>[];

    if (Platform.isAndroid) {
      recommendations.addAll(_getAndroidRecommendations());
    } else if (Platform.isIOS) {
      recommendations.addAll(_getIOSRecommendations());
    } else if (Platform.isWindows) {
      recommendations.addAll(_getWindowsRecommendations());
    } else if (Platform.isMacOS) {
      recommendations.addAll(_getMacOSRecommendations());
    } else if (Platform.isLinux) {
      recommendations.addAll(_getLinuxRecommendations());
    }

    return recommendations;
  }

  /// Checks for common platform-specific configuration issues.
  static List<ConfigurationIssue> checkPlatformConfiguration() {
    if (!_isEnabled) return [];

    final issues = <ConfigurationIssue>[];

    if (Platform.isAndroid) {
      issues.addAll(_checkAndroidConfiguration());
    } else if (Platform.isIOS) {
      issues.addAll(_checkIOSConfiguration());
    } else if (Platform.isWindows) {
      issues.addAll(_checkWindowsConfiguration());
    } else if (Platform.isMacOS) {
      issues.addAll(_checkMacOSConfiguration());
    } else if (Platform.isLinux) {
      issues.addAll(_checkLinuxConfiguration());
    }

    return issues;
  }

  /// Gets the current platform information.
  static PlatformInfo getCurrentPlatformInfo() => PlatformInfo(
      operatingSystem: Platform.operatingSystem,
      operatingSystemVersion: Platform.operatingSystemVersion,
      isAndroid: Platform.isAndroid,
      isIOS: Platform.isIOS,
      isWindows: Platform.isWindows,
      isMacOS: Platform.isMacOS,
      isLinux: Platform.isLinux,
      isFuchsia: Platform.isFuchsia,
      dartVersion: Platform.version,
    );

  static List<PlatformIssue> _detectAndroidIssues(
    String errorMessage,
    String stackTrace,
  ) {
    final issues = <PlatformIssue>[];

    if (errorMessage.contains('permission denied') ||
        errorMessage.contains('security exception')) {
      issues.add(const PlatformIssue(
        platform: TargetPlatform.android,
        type: PlatformIssueType.permissions,
        title: 'Android Permission Issue',
        description: 'The app lacks required Android permissions',
        solution:
            'Add the required permissions to android/app/src/main/AndroidManifest.xml:\n'
            '<uses-permission android:name="android.permission.INTERNET" />\n'
            '<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />',
        severity: IssueSeverity.error,
      ),);
    }

    if (errorMessage.contains('cleartext') || errorMessage.contains('http')) {
      issues.add(const PlatformIssue(
        platform: TargetPlatform.android,
        type: PlatformIssueType.networkSecurity,
        title: 'Android Network Security Issue',
        description:
            'HTTP requests are blocked by Android network security policy',
        solution: 'Add network security config to allow HTTP or use HTTPS:\n'
            'In AndroidManifest.xml:\n'
            'android:networkSecurityConfig="@xml/network_security_config"',
        severity: IssueSeverity.warning,
      ),);
    }

    if (errorMessage.contains('multidex') ||
        errorMessage.contains('method count')) {
      issues.add(const PlatformIssue(
        platform: TargetPlatform.android,
        type: PlatformIssueType.buildConfiguration,
        title: 'Android MultiDex Issue',
        description: 'App exceeds the 64K method limit',
        solution: 'Enable MultiDex in android/app/build.gradle:\n'
            'android {\n'
            '  defaultConfig {\n'
            '    multiDexEnabled true\n'
            '  }\n'
            '}',
        severity: IssueSeverity.error,
      ),);
    }

    return issues;
  }

  static List<PlatformIssue> _detectIOSIssues(
    String errorMessage,
    String stackTrace,
  ) {
    final issues = <PlatformIssue>[];

    if (errorMessage.contains('app transport security') ||
        errorMessage.contains('ats')) {
      issues.add(const PlatformIssue(
        platform: TargetPlatform.iOS,
        type: PlatformIssueType.networkSecurity,
        title: 'iOS App Transport Security Issue',
        description: 'HTTP requests are blocked by iOS App Transport Security',
        solution: 'Configure ATS in ios/Runner/Info.plist:\n'
            '<key>NSAppTransportSecurity</key>\n'
            '<dict>\n'
            '  <key>NSAllowsArbitraryLoads</key>\n'
            '  <true/>\n'
            '</dict>',
        severity: IssueSeverity.warning,
      ),);
    }

    if (errorMessage.contains('code signing') ||
        errorMessage.contains('provisioning')) {
      issues.add(const PlatformIssue(
        platform: TargetPlatform.iOS,
        type: PlatformIssueType.codeSigningProvisioning,
        title: 'iOS Code Signing Issue',
        description: 'Code signing or provisioning profile issue',
        solution: 'Check your iOS development setup:\n'
            '1. Verify your Apple Developer account\n'
            '2. Update provisioning profiles in Xcode\n'
            '3. Check bundle identifier matches your app ID',
        severity: IssueSeverity.error,
      ),);
    }

    if (errorMessage.contains('sandbox') ||
        errorMessage.contains('file access')) {
      issues.add(const PlatformIssue(
        platform: TargetPlatform.iOS,
        type: PlatformIssueType.sandboxRestrictions,
        title: 'iOS Sandbox Restriction',
        description: 'File access restricted by iOS sandbox',
        solution: 'Use proper iOS file access methods:\n'
            '- Use getApplicationDocumentsDirectory() for app documents\n'
            '- Use getTemporaryDirectory() for temporary files\n'
            '- Request proper entitlements if needed',
        severity: IssueSeverity.warning,
      ),);
    }

    return issues;
  }

  static List<PlatformIssue> _detectWindowsIssues(
    String errorMessage,
    String stackTrace,
  ) {
    final issues = <PlatformIssue>[];

    if (errorMessage.contains('path too long') ||
        errorMessage.contains('260')) {
      issues.add(const PlatformIssue(
        platform: TargetPlatform.windows,
        type: PlatformIssueType.fileSystemLimitations,
        title: 'Windows Path Length Limitation',
        description: 'File path exceeds Windows 260 character limit',
        solution: 'Enable long path support or use shorter paths:\n'
            '1. Enable long paths in Windows group policy\n'
            '2. Use relative paths where possible\n'
            '3. Move project to shorter directory path',
        severity: IssueSeverity.error,
      ),);
    }

    if (errorMessage.contains('visual c++') || errorMessage.contains('msvcr')) {
      issues.add(const PlatformIssue(
        platform: TargetPlatform.windows,
        type: PlatformIssueType.runtimeDependencies,
        title: 'Windows Runtime Dependencies',
        description: 'Missing Visual C++ runtime dependencies',
        solution: 'Install Visual C++ Redistributable:\n'
            '1. Download from Microsoft website\n'
            '2. Install both x86 and x64 versions\n'
            '3. Restart your development environment',
        severity: IssueSeverity.error,
      ),);
    }

    return issues;
  }

  static List<PlatformIssue> _detectMacOSIssues(
    String errorMessage,
    String stackTrace,
  ) {
    final issues = <PlatformIssue>[];

    if (errorMessage.contains('gatekeeper') ||
        errorMessage.contains('notarization')) {
      issues.add(const PlatformIssue(
        platform: TargetPlatform.macOS,
        type: PlatformIssueType.codeSigningProvisioning,
        title: 'macOS Gatekeeper Issue',
        description: 'App blocked by macOS Gatekeeper',
        solution: 'Sign and notarize your macOS app:\n'
            '1. Sign with valid Developer ID\n'
            '2. Notarize through Apple\n'
            '3. Add proper entitlements',
        severity: IssueSeverity.warning,
      ),);
    }

    if (errorMessage.contains('sandbox') ||
        errorMessage.contains('entitlement')) {
      issues.add(const PlatformIssue(
        platform: TargetPlatform.macOS,
        type: PlatformIssueType.sandboxRestrictions,
        title: 'macOS Sandbox Restriction',
        description: 'Operation restricted by macOS sandbox',
        solution:
            'Add required entitlements to macos/Runner/DebugProfile.entitlements:\n'
            '<key>com.apple.security.files.user-selected.read-write</key>\n'
            '<true/>',
        severity: IssueSeverity.warning,
      ),);
    }

    return issues;
  }

  static List<PlatformIssue> _detectLinuxIssues(
    String errorMessage,
    String stackTrace,
  ) {
    final issues = <PlatformIssue>[];

    if (errorMessage.contains('permission denied') ||
        errorMessage.contains('access denied')) {
      issues.add(const PlatformIssue(
        platform: TargetPlatform.linux,
        type: PlatformIssueType.permissions,
        title: 'Linux Permission Issue',
        description: 'File or directory access permission denied',
        solution: 'Fix file permissions:\n'
            '1. Check file ownership: ls -la\n'
            '2. Change permissions: chmod 755 <file>\n'
            '3. Change ownership: chown user:group <file>',
        severity: IssueSeverity.error,
      ),);
    }

    if (errorMessage.contains('library') || errorMessage.contains('.so')) {
      issues.add(const PlatformIssue(
        platform: TargetPlatform.linux,
        type: PlatformIssueType.runtimeDependencies,
        title: 'Linux Library Dependencies',
        description: 'Missing shared library dependencies',
        solution: 'Install required libraries:\n'
            '1. Check missing libraries: ldd <binary>\n'
            '2. Install via package manager: apt-get install <package>\n'
            '3. Update library cache: ldconfig',
        severity: IssueSeverity.error,
      ),);
    }

    return issues;
  }

  static List<PlatformIssue> _detectWebIssues(
    String errorMessage,
    String stackTrace,
  ) {
    final issues = <PlatformIssue>[];

    if (kIsWeb) {
      if (errorMessage.contains('cors') ||
          errorMessage.contains('cross-origin')) {
        issues.add(const PlatformIssue(
          platform: TargetPlatform.web,
          type: PlatformIssueType.networkSecurity,
          title: 'Web CORS Issue',
          description: 'Cross-Origin Resource Sharing (CORS) policy violation',
          solution: 'Configure CORS on your server or use a proxy:\n'
              '1. Add CORS headers to your API server\n'
              '2. Use flutter run --web-port=<port> for development\n'
              '3. Configure web server for production',
          severity: IssueSeverity.error,
        ),);
      }

      if (errorMessage.contains('canvaskit') ||
          errorMessage.contains('html renderer')) {
        issues.add(const PlatformIssue(
          platform: TargetPlatform.web,
          type: PlatformIssueType.webRenderer,
          title: 'Web Renderer Issue',
          description: 'Web renderer compatibility issue',
          solution: 'Try different web renderer:\n'
              '1. Use --web-renderer html for better compatibility\n'
              '2. Use --web-renderer canvaskit for better performance\n'
              '3. Test on different browsers',
          severity: IssueSeverity.warning,
        ),);
      }
    }

    return issues;
  }

  static List<PlatformIssue> _detectCategorySpecificIssues(
    ErrorCategory category,
    String errorMessage,
  ) {
    final issues = <PlatformIssue>[];

    switch (category) {
      case ErrorCategory.network:
        if (Platform.isAndroid && errorMessage.contains('cleartext')) {
          issues.add(const PlatformIssue(
            platform: TargetPlatform.android,
            type: PlatformIssueType.networkSecurity,
            title: 'Android Cleartext Traffic',
            description: 'HTTP traffic not allowed on Android',
            solution: 'Use HTTPS or configure network security policy',
            severity: IssueSeverity.error,
          ),);
        }
        break;
      case ErrorCategory.fileSystem:
        if (Platform.isIOS && errorMessage.contains('sandbox')) {
          issues.add(const PlatformIssue(
            platform: TargetPlatform.iOS,
            type: PlatformIssueType.sandboxRestrictions,
            title: 'iOS File Access Restriction',
            description: 'File access restricted by iOS sandbox',
            solution: 'Use proper iOS file access APIs',
            severity: IssueSeverity.warning,
          ),);
        }
        break;
      default:
        break;
    }

    return issues;
  }

  static List<PlatformRecommendation> _getAndroidRecommendations() => [
      const PlatformRecommendation(
        platform: TargetPlatform.android,
        category: 'Performance',
        title: 'Enable R8 Code Shrinking',
        description: 'Reduce APK size and improve performance',
        implementation: 'Add to android/app/build.gradle:\n'
            'buildTypes {\n'
            '  release {\n'
            '    minifyEnabled true\n'
            '    useProguard true\n'
            '  }\n'
            '}',
      ),
      const PlatformRecommendation(
        platform: TargetPlatform.android,
        category: 'Security',
        title: 'Configure Network Security',
        description: 'Properly configure network security policy',
        implementation: 'Create res/xml/network_security_config.xml',
      ),
    ];

  static List<PlatformRecommendation> _getIOSRecommendations() => [
      const PlatformRecommendation(
        platform: TargetPlatform.iOS,
        category: 'Performance',
        title: 'Enable Bitcode',
        description: 'Allow Apple to optimize your app',
        implementation: 'Enable in Xcode build settings: ENABLE_BITCODE = YES',
      ),
      const PlatformRecommendation(
        platform: TargetPlatform.iOS,
        category: 'Security',
        title: 'Configure App Transport Security',
        description: 'Properly configure ATS for network security',
        implementation: 'Configure in Info.plist with specific exceptions',
      ),
    ];

  static List<PlatformRecommendation> _getWindowsRecommendations() => [
      const PlatformRecommendation(
        platform: TargetPlatform.windows,
        category: 'Compatibility',
        title: 'Enable Long Path Support',
        description: 'Support file paths longer than 260 characters',
        implementation: 'Enable in Windows group policy or registry',
      ),
    ];

  static List<PlatformRecommendation> _getMacOSRecommendations() => [
      const PlatformRecommendation(
        platform: TargetPlatform.macOS,
        category: 'Security',
        title: 'Configure Hardened Runtime',
        description: 'Enable security features for distribution',
        implementation: 'Configure in Xcode signing & capabilities',
      ),
    ];

  static List<PlatformRecommendation> _getLinuxRecommendations() => [
      const PlatformRecommendation(
        platform: TargetPlatform.linux,
        category: 'Distribution',
        title: 'Create AppImage',
        description: 'Package app for easy Linux distribution',
        implementation: 'Use AppImage tools to create portable package',
      ),
    ];

  static List<ConfigurationIssue> _checkAndroidConfiguration() {
    // In a real implementation, this would check actual files
    return [];
  }

  static List<ConfigurationIssue> _checkIOSConfiguration() {
    // In a real implementation, this would check actual files
    return [];
  }

  static List<ConfigurationIssue> _checkWindowsConfiguration() {
    // In a real implementation, this would check actual files
    return [];
  }

  static List<ConfigurationIssue> _checkMacOSConfiguration() {
    // In a real implementation, this would check actual files
    return [];
  }

  static List<ConfigurationIssue> _checkLinuxConfiguration() {
    // In a real implementation, this would check actual files
    return [];
  }
}

/// Represents a platform-specific issue.
class PlatformIssue {

  /// Creates a platform issue.
  const PlatformIssue({
    required this.platform,
    required this.type,
    required this.title,
    required this.description,
    required this.solution,
    required this.severity,
  });
  /// The target platform where this issue occurs.
  final TargetPlatform platform;

  /// Type of the platform issue.
  final PlatformIssueType type;

  /// Title of the issue.
  final String title;

  /// Detailed description of the issue.
  final String description;

  /// Suggested solution for the issue.
  final String solution;

  /// Severity of the issue.
  final IssueSeverity severity;
}

/// Types of platform-specific issues.
enum PlatformIssueType {
  /// Permission-related issues.
  permissions,

  /// Network security configuration issues.
  networkSecurity,

  /// Build configuration problems.
  buildConfiguration,

  /// Code signing and provisioning issues.
  codeSigningProvisioning,

  /// Sandbox restriction issues.
  sandboxRestrictions,

  /// File system limitation issues.
  fileSystemLimitations,

  /// Runtime dependency issues.
  runtimeDependencies,

  /// Web renderer issues.
  webRenderer,
}

/// Platform-specific recommendation.
class PlatformRecommendation {

  /// Creates a platform recommendation.
  const PlatformRecommendation({
    required this.platform,
    required this.category,
    required this.title,
    required this.description,
    required this.implementation,
  });
  /// The target platform.
  final TargetPlatform platform;

  /// Category of the recommendation.
  final String category;

  /// Title of the recommendation.
  final String title;

  /// Description of the recommendation.
  final String description;

  /// Implementation details.
  final String implementation;
}

/// Configuration issue detected on a platform.
class ConfigurationIssue {

  /// Creates a configuration issue.
  const ConfigurationIssue({
    required this.platform,
    required this.file,
    required this.issue,
    required this.fix,
    required this.severity,
  });
  /// The platform where the issue was found.
  final TargetPlatform platform;

  /// File where the issue was found.
  final String file;

  /// Description of the configuration issue.
  final String issue;

  /// Suggested fix for the issue.
  final String fix;

  /// Severity of the configuration issue.
  final IssueSeverity severity;
}

/// Information about the current platform.
class PlatformInfo {

  /// Creates platform information.
  const PlatformInfo({
    required this.operatingSystem,
    required this.operatingSystemVersion,
    required this.isAndroid,
    required this.isIOS,
    required this.isWindows,
    required this.isMacOS,
    required this.isLinux,
    required this.isFuchsia,
    required this.dartVersion,
  });
  /// Operating system name.
  final String operatingSystem;

  /// Operating system version.
  final String operatingSystemVersion;

  /// Whether running on Android.
  final bool isAndroid;

  /// Whether running on iOS.
  final bool isIOS;

  /// Whether running on Windows.
  final bool isWindows;

  /// Whether running on macOS.
  final bool isMacOS;

  /// Whether running on Linux.
  final bool isLinux;

  /// Whether running on Fuchsia.
  final bool isFuchsia;

  /// Dart version information.
  final String dartVersion;
}

/// Severity levels for issues.
enum IssueSeverity {
  /// Informational - nice to fix but not critical.
  info,

  /// Warning - should be addressed.
  warning,

  /// Error - needs immediate attention.
  error,
}

/// Target platforms for Flutter applications.
enum TargetPlatform {
  /// Android platform.
  android,

  /// iOS platform.
  iOS,

  /// Windows platform.
  windows,

  /// macOS platform.
  macOS,

  /// Linux platform.
  linux,

  /// Web platform.
  web,

  /// Fuchsia platform.
  fuchsia,
}
