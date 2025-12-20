import 'dart:async';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:path/path.dart' as path;

/// Integrated development workflow tools for Flutter projects.
///
/// Provides real-time linting, asset reference generation, build configuration
/// validation, and dependency update analysis with migration guidance.
abstract class WorkflowTools {
  /// Performs real-time Flutter-specific linting on the project.
  ///
  /// Analyzes Dart files for Flutter-specific best practices and common
  /// issues, providing actionable feedback for developers.
  Future<LintingResult> performFlutterLinting(String projectPath);

  /// Generates automatic asset reference classes from assets directory.
  ///
  /// Scans the assets directory and generates type-safe Dart classes
  /// for referencing assets in code, reducing string-based asset references.
  Future<AssetGenerationResult> generateAssetReferences(String projectPath);

  /// Validates build configuration consistency across platforms.
  ///
  /// Checks that build configurations (Android, iOS, Web, etc.) are
  /// consistent and properly configured for the project requirements.
  Future<BuildValidationResult> validateBuildConfiguration(String projectPath);

  /// Analyzes dependency updates and provides migration guidance.
  ///
  /// Checks for available dependency updates and provides detailed
  /// migration guidance including breaking changes and required code updates.
  Future<DependencyUpdateResult> analyzeDependencyUpdates(String projectPath);
}

/// Concrete implementation of [WorkflowTools].
class WorkflowToolsImpl implements WorkflowTools {
  /// Creates a new workflow tools implementation.
  const WorkflowToolsImpl();

  @override
  Future<LintingResult> performFlutterLinting(String projectPath) async {
    final issues = <LintIssue>[];
    final suggestions = <LintSuggestion>[];

    try {
      // Check if project directory exists
      if (!Directory(projectPath).existsSync()) {
        return LintingResult(
          success: false,
          issues: [
            LintIssue(
              severity: LintSeverity.error,
              message: 'Project directory does not exist',
              file: projectPath,
              rule: 'project-structure',
            ),
          ],
          suggestions: [],
          totalFiles: 0,
          processedFiles: 0,
        );
      }

      final libPath = path.join(projectPath, 'lib');
      if (!Directory(libPath).existsSync()) {
        return LintingResult(
          success: false,
          issues: [
            LintIssue(
              severity: LintSeverity.error,
              message:
                  'lib directory not found - not a valid Dart/Flutter project',
              file: libPath,
              rule: 'project-structure',
            ),
          ],
          suggestions: [],
          totalFiles: 0,
          processedFiles: 0,
        );
      }

      // Get all Dart files in the project
      final dartFiles = await _getDartFiles(projectPath);
      var processedFiles = 0;

      // Use analyzer for static analysis
      final collection = AnalysisContextCollection(
        includedPaths: [projectPath],
        resourceProvider: PhysicalResourceProvider.INSTANCE,
      );

      for (final dartFile in dartFiles) {
        try {
          final context = collection.contextFor(dartFile.path);
          final result =
              await context.currentSession.getResolvedUnit(dartFile.path);

          if (result is ResolvedUnitResult) {
            // Analyze for Flutter-specific issues
            final fileIssues =
                _analyzeFlutterSpecificIssues(result, dartFile.path);
            issues.addAll(fileIssues.issues);
            suggestions.addAll(fileIssues.suggestions);
          }

          processedFiles++;
        } catch (e) {
          // Skip files that can't be analyzed
          issues.add(LintIssue(
            severity: LintSeverity.warning,
            message: 'Failed to analyze file: $e',
            file: dartFile.path,
            rule: 'analysis-error',
          ),);
        }
      }

      return LintingResult(
        success: true,
        issues: issues,
        suggestions: suggestions,
        totalFiles: dartFiles.length,
        processedFiles: processedFiles,
      );
    } catch (e) {
      return LintingResult(
        success: false,
        issues: [
          LintIssue(
            severity: LintSeverity.error,
            message: 'Linting failed: $e',
            file: projectPath,
            rule: 'linting-error',
          ),
        ],
        suggestions: [],
        totalFiles: 0,
        processedFiles: 0,
      );
    }
  }

  @override
  Future<AssetGenerationResult> generateAssetReferences(
      String projectPath,) async {
    try {
      final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
      if (!pubspecFile.existsSync()) {
        return const AssetGenerationResult(
          success: false,
          generatedFiles: [],
          assetCount: 0,
          errors: ['pubspec.yaml not found'],
        );
      }

      final pubspecContent = await pubspecFile.readAsString();
      final assets = _extractAssetsFromPubspec(pubspecContent);

      if (assets.isEmpty) {
        return const AssetGenerationResult(
          success: true,
          generatedFiles: [],
          assetCount: 0,
          errors: [],
        );
      }

      // Generate asset reference classes
      final generatedFiles = <String>[];
      final assetsByType = _groupAssetsByType(assets);

      for (final entry in assetsByType.entries) {
        final assetType = entry.key;
        final assetList = entry.value;

        final className = _generateAssetClassName(assetType);
        final classContent = _generateAssetClass(className, assetList);

        final outputPath = path.join(projectPath, 'lib', 'generated',
            'assets_${assetType.toLowerCase()}.dart',);
        final outputFile = File(outputPath);

        // Create directory if it doesn't exist
        await outputFile.parent.create(recursive: true);
        await outputFile.writeAsString(classContent);

        generatedFiles.add(outputPath);
      }

      // Generate main assets file that exports all asset classes
      final mainAssetsContent = _generateMainAssetsFile(assetsByType.keys);
      final mainAssetsPath =
          path.join(projectPath, 'lib', 'generated', 'assets.dart');
      final mainAssetsFile = File(mainAssetsPath);
      await mainAssetsFile.writeAsString(mainAssetsContent);
      generatedFiles.add(mainAssetsPath);

      return AssetGenerationResult(
        success: true,
        generatedFiles: generatedFiles,
        assetCount: assets.length,
        errors: [],
      );
    } catch (e) {
      return AssetGenerationResult(
        success: false,
        generatedFiles: [],
        assetCount: 0,
        errors: ['Asset generation failed: $e'],
      );
    }
  }

  @override
  Future<BuildValidationResult> validateBuildConfiguration(
      String projectPath,) async {
    final issues = <BuildIssue>[];
    final warnings = <BuildWarning>[];

    try {
      // Check if it's a Flutter project
      final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
      if (!pubspecFile.existsSync()) {
        return const BuildValidationResult(
          success: false,
          issues: [
            BuildIssue(
              platform: 'all',
              severity: BuildIssueSeverity.error,
              message: 'pubspec.yaml not found',
              fix: 'Create a valid pubspec.yaml file',
            ),
          ],
          warnings: [],
          validatedPlatforms: [],
        );
      }

      final pubspecContent = await pubspecFile.readAsString();
      final isFlutterProject = pubspecContent.contains('flutter:');

      if (!isFlutterProject) {
        warnings.add(const BuildWarning(
          platform: 'all',
          message: 'Not a Flutter project - some validations may not apply',
          suggestion:
              'Add flutter dependency if this should be a Flutter project',
        ),);
      }

      final validatedPlatforms = <String>[];

      // Validate Android configuration
      final androidValidation =
          await _validateAndroidConfiguration(projectPath);
      issues.addAll(androidValidation.issues);
      warnings.addAll(androidValidation.warnings);
      if (androidValidation.isConfigured) {
        validatedPlatforms.add('android');
      }

      // Validate iOS configuration
      final iosValidation = await _validateIosConfiguration(projectPath);
      issues.addAll(iosValidation.issues);
      warnings.addAll(iosValidation.warnings);
      if (iosValidation.isConfigured) {
        validatedPlatforms.add('ios');
      }

      // Validate Web configuration
      final webValidation = await _validateWebConfiguration(projectPath);
      issues.addAll(webValidation.issues);
      warnings.addAll(webValidation.warnings);
      if (webValidation.isConfigured) {
        validatedPlatforms.add('web');
      }

      // Validate general Flutter configuration
      final flutterValidation =
          await _validateFlutterConfiguration(projectPath, pubspecContent);
      issues.addAll(flutterValidation.issues);
      warnings.addAll(flutterValidation.warnings);

      return BuildValidationResult(
        success:
            issues.where((i) => i.severity == BuildIssueSeverity.error).isEmpty,
        issues: issues,
        warnings: warnings,
        validatedPlatforms: validatedPlatforms,
      );
    } catch (e) {
      return BuildValidationResult(
        success: false,
        issues: [
          BuildIssue(
            platform: 'all',
            severity: BuildIssueSeverity.error,
            message: 'Build validation failed: $e',
            fix: 'Check project structure and try again',
          ),
        ],
        warnings: [],
        validatedPlatforms: [],
      );
    }
  }

  @override
  Future<DependencyUpdateResult> analyzeDependencyUpdates(
      String projectPath,) async {
    try {
      final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
      if (!pubspecFile.existsSync()) {
        return const DependencyUpdateResult(
          success: false,
          availableUpdates: [],
          breakingChanges: [],
          migrationGuides: [],
          errors: ['pubspec.yaml not found'],
        );
      }

      final pubspecContent = await pubspecFile.readAsString();
      final dependencies = _parseDependencies(pubspecContent);

      final availableUpdates = <DependencyUpdate>[];
      final breakingChanges = <BreakingChange>[];
      final migrationGuides = <MigrationGuide>[];

      // Analyze each dependency for updates
      for (final dependency in dependencies) {
        final updateInfo = await _checkDependencyUpdate(dependency);
        if (updateInfo != null) {
          availableUpdates.add(updateInfo);

          // Check for breaking changes
          if (updateInfo.hasBreakingChanges) {
            final breakingChange =
                await _analyzeBreakingChanges(dependency, updateInfo);
            if (breakingChange != null) {
              breakingChanges.add(breakingChange);

              // Generate migration guide
              final migrationGuide =
                  _generateMigrationGuide(dependency, breakingChange);
              migrationGuides.add(migrationGuide);
            }
          }
        }
      }

      return DependencyUpdateResult(
        success: true,
        availableUpdates: availableUpdates,
        breakingChanges: breakingChanges,
        migrationGuides: migrationGuides,
        errors: [],
      );
    } catch (e) {
      return DependencyUpdateResult(
        success: false,
        availableUpdates: [],
        breakingChanges: [],
        migrationGuides: [],
        errors: ['Dependency analysis failed: $e'],
      );
    }
  }

  // Private helper methods

  Future<List<File>> _getDartFiles(String projectPath) async {
    final dartFiles = <File>[];
    final libDir = Directory(path.join(projectPath, 'lib'));

    if (libDir.existsSync()) {
      await for (final entity in libDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          dartFiles.add(entity);
        }
      }
    }

    return dartFiles;
  }

  _FlutterAnalysisResult _analyzeFlutterSpecificIssues(
      ResolvedUnitResult result, String filePath,) {
    final issues = <LintIssue>[];
    final suggestions = <LintSuggestion>[];

    // Check for common Flutter anti-patterns
    final source = result.content;

    // Check for missing const constructors
    if (source.contains('Widget') && !source.contains('const ')) {
      suggestions.add(LintSuggestion(
        rule: 'prefer-const-constructors',
        message: 'Consider using const constructors for better performance',
        file: filePath,
        fix: 'Add const keyword to widget constructors where possible',
      ),);
    }

    // Check for setState in initState
    if (source.contains('initState') && source.contains('setState')) {
      issues.add(LintIssue(
        severity: LintSeverity.warning,
        message: 'Avoid calling setState in initState',
        file: filePath,
        rule: 'no-setstate-in-initstate',
        line: _findLineNumber(source, 'setState'),
      ),);
    }

    // Check for missing dispose calls
    if (source.contains('Controller') && !source.contains('dispose')) {
      suggestions.add(LintSuggestion(
        rule: 'dispose-controllers',
        message: 'Controllers should be disposed to prevent memory leaks',
        file: filePath,
        fix: 'Override dispose() method and dispose controllers',
      ),);
    }

    // Check for hardcoded colors
    if (source.contains('Color(0x') || source.contains('Colors.')) {
      suggestions.add(LintSuggestion(
        rule: 'use-theme-colors',
        message: 'Consider using theme colors instead of hardcoded colors',
        file: filePath,
        fix: 'Use Theme.of(context).colorScheme or define colors in theme',
      ),);
    }

    return _FlutterAnalysisResult(issues: issues, suggestions: suggestions);
  }

  int? _findLineNumber(String content, String searchText) {
    final lines = content.split('\n');
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].contains(searchText)) {
        return i + 1;
      }
    }
    return null;
  }

  List<String> _extractAssetsFromPubspec(String pubspecContent) {
    final assets = <String>[];
    final lines = pubspecContent.split('\n');
    var inAssetsSection = false;

    for (final line in lines) {
      final trimmedLine = line.trim();

      if (trimmedLine == 'assets:') {
        inAssetsSection = true;
        continue;
      }

      if (inAssetsSection) {
        if (trimmedLine.startsWith('- ')) {
          final assetPath = trimmedLine.substring(2).trim();
          if (assetPath.isNotEmpty) {
            assets.add(assetPath);
          }
        } else if (!trimmedLine.startsWith('#') &&
            trimmedLine.isNotEmpty &&
            !line.startsWith('  ')) {
          // End of assets section
          inAssetsSection = false;
        }
      }
    }

    return assets;
  }

  Map<String, List<String>> _groupAssetsByType(List<String> assets) {
    final assetsByType = <String, List<String>>{};

    for (final asset in assets) {
      final extension = path.extension(asset).toLowerCase();
      String type;

      switch (extension) {
        case '.png':
        case '.jpg':
        case '.jpeg':
        case '.gif':
        case '.webp':
          type = 'Images';
          break;
        case '.svg':
          type = 'Vectors';
          break;
        case '.json':
          type = 'Data';
          break;
        case '.ttf':
        case '.otf':
          type = 'Fonts';
          break;
        default:
          type = 'Other';
      }

      assetsByType.putIfAbsent(type, () => []).add(asset);
    }

    return assetsByType;
  }

  String _generateAssetClassName(String assetType) => '${assetType}Assets';

  String _generateAssetClass(String className, List<String> assets) {
    final buffer = StringBuffer();
    buffer.writeln('/// Generated asset references for $className');
    buffer.writeln('class $className {');
    buffer.writeln('  const $className._();');
    buffer.writeln();

    for (final asset in assets) {
      final fieldName = _generateFieldName(asset);
      buffer.writeln('  /// Asset: $asset');
      buffer.writeln("  static const String $fieldName = '$asset';");
      buffer.writeln();
    }

    buffer.writeln('  /// All ${className.toLowerCase()} assets');
    buffer.writeln('  static const List<String> all = [');
    for (final asset in assets) {
      final fieldName = _generateFieldName(asset);
      buffer.writeln('    $fieldName,');
    }
    buffer.writeln('  ];');
    buffer.writeln('}');

    return buffer.toString();
  }

  String _generateFieldName(String assetPath) {
    final fileName = path.basenameWithoutExtension(assetPath);
    // Convert to camelCase and make it a valid Dart identifier
    return fileName
        .replaceAll(RegExp('[^a-zA-Z0-9_]'), '_')
        .replaceAll(RegExp('_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '')
        .toLowerCase();
  }

  String _generateMainAssetsFile(Iterable<String> assetTypes) {
    final buffer = StringBuffer();
    buffer.writeln('/// Generated asset references');
    buffer.writeln(
        '/// This file is automatically generated. Do not edit manually.',);
    buffer.writeln();

    for (final assetType in assetTypes) {
      buffer.writeln("export 'assets_${assetType.toLowerCase()}.dart';");
    }

    return buffer.toString();
  }

  Future<_PlatformValidationResult> _validateAndroidConfiguration(
      String projectPath,) async {
    final issues = <BuildIssue>[];
    final warnings = <BuildWarning>[];
    var isConfigured = false;

    final androidDir = Directory(path.join(projectPath, 'android'));
    if (!androidDir.existsSync()) {
      warnings.add(const BuildWarning(
        platform: 'android',
        message: 'Android platform not configured',
        suggestion: 'Run flutter create . to add Android support',
      ),);
      return _PlatformValidationResult(
          issues: issues, warnings: warnings, isConfigured: false,);
    }

    isConfigured = true;

    // Check build.gradle files
    final appBuildGradle =
        File(path.join(projectPath, 'android', 'app', 'build.gradle'));
    if (appBuildGradle.existsSync()) {
      final content = await appBuildGradle.readAsString();

      // Check for minimum SDK version
      if (!content.contains('minSdkVersion')) {
        issues.add(const BuildIssue(
          platform: 'android',
          severity: BuildIssueSeverity.warning,
          message: 'minSdkVersion not specified',
          fix: 'Add minSdkVersion in android/app/build.gradle',
        ),);
      }

      // Check for target SDK version
      if (!content.contains('targetSdkVersion')) {
        issues.add(const BuildIssue(
          platform: 'android',
          severity: BuildIssueSeverity.warning,
          message: 'targetSdkVersion not specified',
          fix: 'Add targetSdkVersion in android/app/build.gradle',
        ),);
      }
    }

    // Check AndroidManifest.xml
    final manifest = File(path.join(
        projectPath, 'android', 'app', 'src', 'main', 'AndroidManifest.xml',),);
    if (manifest.existsSync()) {
      final content = await manifest.readAsString();

      if (!content.contains('android:label')) {
        warnings.add(const BuildWarning(
          platform: 'android',
          message: 'App label not configured in AndroidManifest.xml',
          suggestion: 'Add android:label attribute to application tag',
        ),);
      }
    }

    return _PlatformValidationResult(
        issues: issues, warnings: warnings, isConfigured: isConfigured,);
  }

  Future<_PlatformValidationResult> _validateIosConfiguration(
      String projectPath,) async {
    final issues = <BuildIssue>[];
    final warnings = <BuildWarning>[];
    var isConfigured = false;

    final iosDir = Directory(path.join(projectPath, 'ios'));
    if (!iosDir.existsSync()) {
      warnings.add(const BuildWarning(
        platform: 'ios',
        message: 'iOS platform not configured',
        suggestion: 'Run flutter create . to add iOS support',
      ),);
      return _PlatformValidationResult(
          issues: issues, warnings: warnings, isConfigured: false,);
    }

    isConfigured = true;

    // Check Info.plist
    final infoPlist =
        File(path.join(projectPath, 'ios', 'Runner', 'Info.plist'));
    if (infoPlist.existsSync()) {
      final content = await infoPlist.readAsString();

      if (!content.contains('CFBundleDisplayName')) {
        warnings.add(const BuildWarning(
          platform: 'ios',
          message: 'App display name not configured in Info.plist',
          suggestion: 'Add CFBundleDisplayName key to Info.plist',
        ),);
      }

      if (!content.contains('CFBundleVersion')) {
        issues.add(const BuildIssue(
          platform: 'ios',
          severity: BuildIssueSeverity.warning,
          message: 'Bundle version not configured',
          fix: 'Add CFBundleVersion key to Info.plist',
        ),);
      }
    }

    return _PlatformValidationResult(
        issues: issues, warnings: warnings, isConfigured: isConfigured,);
  }

  Future<_PlatformValidationResult> _validateWebConfiguration(
      String projectPath,) async {
    final issues = <BuildIssue>[];
    final warnings = <BuildWarning>[];
    var isConfigured = false;

    final webDir = Directory(path.join(projectPath, 'web'));
    if (!webDir.existsSync()) {
      warnings.add(const BuildWarning(
        platform: 'web',
        message: 'Web platform not configured',
        suggestion: 'Run flutter create . to add web support',
      ),);
      return _PlatformValidationResult(
          issues: issues, warnings: warnings, isConfigured: false,);
    }

    isConfigured = true;

    // Check index.html
    final indexHtml = File(path.join(projectPath, 'web', 'index.html'));
    if (indexHtml.existsSync()) {
      final content = await indexHtml.readAsString();

      if (!content.contains('<title>')) {
        warnings.add(const BuildWarning(
          platform: 'web',
          message: 'Page title not configured in index.html',
          suggestion: 'Add <title> tag to web/index.html',
        ),);
      }

      if (!content.contains('manifest.json')) {
        warnings.add(const BuildWarning(
          platform: 'web',
          message: 'Web app manifest not linked',
          suggestion: 'Add manifest.json link to index.html for PWA support',
        ),);
      }
    }

    return _PlatformValidationResult(
        issues: issues, warnings: warnings, isConfigured: isConfigured,);
  }

  Future<_FlutterConfigValidationResult> _validateFlutterConfiguration(
      String projectPath, String pubspecContent,) async {
    final issues = <BuildIssue>[];
    final warnings = <BuildWarning>[];

    // Check Flutter SDK constraints
    if (!pubspecContent.contains('environment:')) {
      issues.add(const BuildIssue(
        platform: 'flutter',
        severity: BuildIssueSeverity.warning,
        message: 'Flutter SDK version constraint not specified',
        fix:
            'Add environment section with flutter version constraint in pubspec.yaml',
      ),);
    }

    // Check for flutter_lints
    if (!pubspecContent.contains('flutter_lints')) {
      warnings.add(const BuildWarning(
        platform: 'flutter',
        message: 'flutter_lints not configured',
        suggestion:
            'Add flutter_lints to dev_dependencies for better code quality',
      ),);
    }

    return _FlutterConfigValidationResult(issues: issues, warnings: warnings);
  }

  List<DependencyInfo> _parseDependencies(String pubspecContent) {
    final dependencies = <DependencyInfo>[];
    final lines = pubspecContent.split('\n');
    String? currentSection;

    for (final line in lines) {
      final trimmedLine = line.trim();

      if (trimmedLine == 'dependencies:') {
        currentSection = 'dependencies';
        continue;
      } else if (trimmedLine == 'dev_dependencies:') {
        currentSection = 'dev_dependencies';
        continue;
      } else if (trimmedLine.endsWith(':') && !line.startsWith('  ')) {
        currentSection = null;
        continue;
      }

      if (currentSection != null &&
          line.startsWith('  ') &&
          line.contains(':')) {
        final parts = line.split(':');
        if (parts.length >= 2) {
          final name = parts[0].trim();
          final constraint = parts.sublist(1).join(':').trim();

          if (name.isNotEmpty && !name.startsWith('#')) {
            dependencies.add(DependencyInfo(
              name: name,
              currentVersion: constraint,
              isDev: currentSection == 'dev_dependencies',
            ),);
          }
        }
      }
    }

    return dependencies;
  }

  Future<DependencyUpdate?> _checkDependencyUpdate(
      DependencyInfo dependency,) async {
    // This is a simplified implementation
    // In a real implementation, you would query pub.dev API or use pub deps command

    // Simulate checking for updates
    final hasUpdate = dependency.name.hashCode % 3 ==
        0; // Simulate some dependencies having updates

    if (!hasUpdate) return null;

    final currentVersion =
        dependency.currentVersion.replaceAll(RegExp('[^0-9.]'), '');
    final latestVersion = _simulateLatestVersion(currentVersion);

    return DependencyUpdate(
      name: dependency.name,
      currentVersion: currentVersion,
      latestVersion: latestVersion,
      hasBreakingChanges:
          _simulateBreakingChanges(currentVersion, latestVersion),
      updateType: _determineUpdateType(currentVersion, latestVersion),
    );
  }

  String _simulateLatestVersion(String currentVersion) {
    // Simple simulation - increment patch version
    final parts = currentVersion.split('.');
    if (parts.length >= 3) {
      final patch = int.tryParse(parts[2]) ?? 0;
      return '${parts[0]}.${parts[1]}.${patch + 1}';
    }
    return currentVersion;
  }

  bool _simulateBreakingChanges(String currentVersion, String latestVersion) {
    final currentParts = currentVersion.split('.');
    final latestParts = latestVersion.split('.');

    if (currentParts.length >= 2 && latestParts.length >= 2) {
      final currentMajor = int.tryParse(currentParts[0]) ?? 0;
      final latestMajor = int.tryParse(latestParts[0]) ?? 0;
      return latestMajor > currentMajor;
    }

    return false;
  }

  UpdateType _determineUpdateType(String currentVersion, String latestVersion) {
    final currentParts = currentVersion.split('.');
    final latestParts = latestVersion.split('.');

    if (currentParts.length >= 3 && latestParts.length >= 3) {
      final currentMajor = int.tryParse(currentParts[0]) ?? 0;
      final latestMajor = int.tryParse(latestParts[0]) ?? 0;
      final currentMinor = int.tryParse(currentParts[1]) ?? 0;
      final latestMinor = int.tryParse(latestParts[1]) ?? 0;

      if (latestMajor > currentMajor) return UpdateType.major;
      if (latestMinor > currentMinor) return UpdateType.minor;
      return UpdateType.patch;
    }

    return UpdateType.patch;
  }

  Future<BreakingChange?> _analyzeBreakingChanges(
      DependencyInfo dependency, DependencyUpdate update,) async {
    // Simulate breaking change analysis
    if (!update.hasBreakingChanges) return null;

    return BreakingChange(
      dependency: dependency.name,
      fromVersion: update.currentVersion,
      toVersion: update.latestVersion,
      changes: [
        'API method signatures have changed',
        'Deprecated methods have been removed',
        'Configuration format has been updated',
      ],
      impact: BreakingChangeImpact.medium,
    );
  }

  MigrationGuide _generateMigrationGuide(
      DependencyInfo dependency, BreakingChange breakingChange,) => MigrationGuide(
      dependency: dependency.name,
      fromVersion: breakingChange.fromVersion,
      toVersion: breakingChange.toVersion,
      steps: [
        'Update pubspec.yaml with new version constraint',
        'Run flutter pub get to fetch the new version',
        'Update import statements if package structure changed',
        'Replace deprecated API calls with new equivalents',
        'Test your application thoroughly',
      ],
      codeExamples: [
        const CodeExample(
          description: 'Update method call',
          before: 'oldMethod(param1, param2)',
          after: 'newMethod(param1: param1, param2: param2)',
        ),
      ],
      estimatedEffort: MigrationEffort.medium,
    );
}

// Result classes and supporting types

/// Result of Flutter-specific linting analysis.
class LintingResult {

  /// Creates a new linting result.
  const LintingResult({
    required this.success,
    required this.issues,
    required this.suggestions,
    required this.totalFiles,
    required this.processedFiles,
  });
  /// Whether the linting completed successfully.
  final bool success;

  /// List of issues found during linting.
  final List<LintIssue> issues;

  /// List of suggestions for improvement.
  final List<LintSuggestion> suggestions;

  /// Total number of files in the project.
  final int totalFiles;

  /// Number of files successfully processed.
  final int processedFiles;

  /// Whether there are any critical issues.
  bool get hasCriticalIssues =>
      issues.any((issue) => issue.severity == LintSeverity.error);

  /// Number of issues by severity.
  Map<LintSeverity, int> get issuesBySeverity {
    final counts = <LintSeverity, int>{};
    for (final issue in issues) {
      counts[issue.severity] = (counts[issue.severity] ?? 0) + 1;
    }
    return counts;
  }
}

/// A linting issue found in the code.
class LintIssue {

  /// Creates a new lint issue.
  const LintIssue({
    required this.severity,
    required this.message,
    required this.file,
    this.line,
    this.column,
    required this.rule,
  });
  /// Severity of the issue.
  final LintSeverity severity;

  /// Description of the issue.
  final String message;

  /// File where the issue was found.
  final String file;

  /// Line number where the issue occurs (if available).
  final int? line;

  /// Column number where the issue occurs (if available).
  final int? column;

  /// Linting rule that triggered this issue.
  final String rule;
}

/// A suggestion for code improvement.
class LintSuggestion {

  /// Creates a new lint suggestion.
  const LintSuggestion({
    required this.rule,
    required this.message,
    required this.file,
    required this.fix,
  });
  /// Linting rule that generated this suggestion.
  final String rule;

  /// Description of the suggestion.
  final String message;

  /// File where the suggestion applies.
  final String file;

  /// Suggested fix or improvement.
  final String fix;
}

/// Severity levels for linting issues.
enum LintSeverity {
  /// Informational message.
  info,

  /// Warning that should be addressed.
  warning,

  /// Error that must be fixed.
  error,
}

/// Result of asset reference generation.
class AssetGenerationResult {

  /// Creates a new asset generation result.
  const AssetGenerationResult({
    required this.success,
    required this.generatedFiles,
    required this.assetCount,
    required this.errors,
  });
  /// Whether the generation completed successfully.
  final bool success;

  /// List of generated files.
  final List<String> generatedFiles;

  /// Number of assets processed.
  final int assetCount;

  /// Any errors that occurred during generation.
  final List<String> errors;
}

/// Result of build configuration validation.
class BuildValidationResult {

  /// Creates a new build validation result.
  const BuildValidationResult({
    required this.success,
    required this.issues,
    required this.warnings,
    required this.validatedPlatforms,
  });
  /// Whether the validation passed without critical issues.
  final bool success;

  /// List of build issues found.
  final List<BuildIssue> issues;

  /// List of build warnings.
  final List<BuildWarning> warnings;

  /// List of platforms that were validated.
  final List<String> validatedPlatforms;

  /// Whether there are any critical build issues.
  bool get hasCriticalIssues =>
      issues.any((issue) => issue.severity == BuildIssueSeverity.error);
}

/// A build configuration issue.
class BuildIssue {

  /// Creates a new build issue.
  const BuildIssue({
    required this.platform,
    required this.severity,
    required this.message,
    required this.fix,
  });
  /// Platform where the issue was found.
  final String platform;

  /// Severity of the issue.
  final BuildIssueSeverity severity;

  /// Description of the issue.
  final String message;

  /// Suggested fix for the issue.
  final String fix;
}

/// A build configuration warning.
class BuildWarning {

  /// Creates a new build warning.
  const BuildWarning({
    required this.platform,
    required this.message,
    required this.suggestion,
  });
  /// Platform where the warning applies.
  final String platform;

  /// Description of the warning.
  final String message;

  /// Suggested improvement.
  final String suggestion;
}

/// Severity levels for build issues.
enum BuildIssueSeverity {
  /// Warning that should be addressed.
  warning,

  /// Error that must be fixed.
  error,
}

/// Result of dependency update analysis.
class DependencyUpdateResult {

  /// Creates a new dependency update result.
  const DependencyUpdateResult({
    required this.success,
    required this.availableUpdates,
    required this.breakingChanges,
    required this.migrationGuides,
    required this.errors,
  });
  /// Whether the analysis completed successfully.
  final bool success;

  /// List of available dependency updates.
  final List<DependencyUpdate> availableUpdates;

  /// List of breaking changes in updates.
  final List<BreakingChange> breakingChanges;

  /// List of migration guides for breaking changes.
  final List<MigrationGuide> migrationGuides;

  /// Any errors that occurred during analysis.
  final List<String> errors;

  /// Whether there are any updates with breaking changes.
  bool get hasBreakingChanges => breakingChanges.isNotEmpty;

  /// Number of available updates by type.
  Map<UpdateType, int> get updatesByType {
    final counts = <UpdateType, int>{};
    for (final update in availableUpdates) {
      counts[update.updateType] = (counts[update.updateType] ?? 0) + 1;
    }
    return counts;
  }
}

/// Information about a dependency update.
class DependencyUpdate {

  /// Creates a new dependency update.
  const DependencyUpdate({
    required this.name,
    required this.currentVersion,
    required this.latestVersion,
    required this.hasBreakingChanges,
    required this.updateType,
  });
  /// Name of the dependency.
  final String name;

  /// Current version.
  final String currentVersion;

  /// Latest available version.
  final String latestVersion;

  /// Whether the update includes breaking changes.
  final bool hasBreakingChanges;

  /// Type of update (major, minor, patch).
  final UpdateType updateType;
}

/// Information about breaking changes in a dependency update.
class BreakingChange {

  /// Creates a new breaking change.
  const BreakingChange({
    required this.dependency,
    required this.fromVersion,
    required this.toVersion,
    required this.changes,
    required this.impact,
  });
  /// Name of the dependency.
  final String dependency;

  /// Version being updated from.
  final String fromVersion;

  /// Version being updated to.
  final String toVersion;

  /// List of breaking changes.
  final List<String> changes;

  /// Impact level of the breaking changes.
  final BreakingChangeImpact impact;
}

/// Migration guide for handling breaking changes.
class MigrationGuide {

  /// Creates a new migration guide.
  const MigrationGuide({
    required this.dependency,
    required this.fromVersion,
    required this.toVersion,
    required this.steps,
    required this.codeExamples,
    required this.estimatedEffort,
  });
  /// Name of the dependency.
  final String dependency;

  /// Version being migrated from.
  final String fromVersion;

  /// Version being migrated to.
  final String toVersion;

  /// Step-by-step migration instructions.
  final List<String> steps;

  /// Code examples showing before/after.
  final List<CodeExample> codeExamples;

  /// Estimated effort required for migration.
  final MigrationEffort estimatedEffort;
}

/// A code example showing before and after migration.
class CodeExample {

  /// Creates a new code example.
  const CodeExample({
    required this.description,
    required this.before,
    required this.after,
  });
  /// Description of what the example shows.
  final String description;

  /// Code before migration.
  final String before;

  /// Code after migration.
  final String after;
}

/// Types of dependency updates.
enum UpdateType {
  /// Major version update (breaking changes expected).
  major,

  /// Minor version update (new features, backward compatible).
  minor,

  /// Patch version update (bug fixes, backward compatible).
  patch,
}

/// Impact levels for breaking changes.
enum BreakingChangeImpact {
  /// Low impact - minimal code changes required.
  low,

  /// Medium impact - moderate code changes required.
  medium,

  /// High impact - significant code changes required.
  high,
}

/// Effort levels for migration.
enum MigrationEffort {
  /// Minimal effort - quick fixes.
  minimal,

  /// Low effort - simple changes.
  low,

  /// Medium effort - moderate refactoring.
  medium,

  /// High effort - significant refactoring.
  high,
}

// Private helper classes

class _FlutterAnalysisResult {

  const _FlutterAnalysisResult({
    required this.issues,
    required this.suggestions,
  });
  final List<LintIssue> issues;
  final List<LintSuggestion> suggestions;
}

class _PlatformValidationResult {

  const _PlatformValidationResult({
    required this.issues,
    required this.warnings,
    required this.isConfigured,
  });
  final List<BuildIssue> issues;
  final List<BuildWarning> warnings;
  final bool isConfigured;
}

class _FlutterConfigValidationResult {

  const _FlutterConfigValidationResult({
    required this.issues,
    required this.warnings,
  });
  final List<BuildIssue> issues;
  final List<BuildWarning> warnings;
}

/// Information about a dependency in pubspec.yaml.
class DependencyInfo {

  /// Creates a new dependency info.
  const DependencyInfo({
    required this.name,
    required this.currentVersion,
    required this.isDev,
  });
  /// Name of the dependency.
  final String name;

  /// Current version constraint.
  final String currentVersion;

  /// Whether this is a dev dependency.
  final bool isDev;
}
