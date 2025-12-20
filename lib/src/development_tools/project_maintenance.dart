import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

/// Project maintenance utilities for Flutter/Dart projects.
///
/// Provides tools for managing import statement consistency, file organization
/// optimization, and project structure validation to maintain clean and
/// organized codebases.
abstract class ProjectMaintenance {
  /// Manages import statement consistency across the project.
  ///
  /// Analyzes and standardizes import statements, removes unused imports,
  /// sorts imports according to Dart conventions, and ensures consistent
  /// import organization throughout the project.
  Future<ImportManagementResult> manageImportConsistency(String projectPath);

  /// Optimizes file organization within the project.
  ///
  /// Analyzes project structure and suggests improvements for better
  /// organization, including file placement, directory structure, and
  /// naming conventions.
  Future<FileOrganizationResult> optimizeFileOrganization(String projectPath);

  /// Validates project structure against best practices.
  ///
  /// Checks that the project follows recommended Flutter/Dart project
  /// structure conventions and identifies areas for improvement.
  Future<ProjectStructureResult> validateProjectStructure(String projectPath);
}

/// Concrete implementation of [ProjectMaintenance].
class ProjectMaintenanceImpl implements ProjectMaintenance {
  /// Creates a new project maintenance implementation.
  const ProjectMaintenanceImpl();

  @override
  Future<ImportManagementResult> manageImportConsistency(
      String projectPath,) async {
    final issues = <ImportIssue>[];
    final fixes = <ImportFix>[];
    final statistics = <String, int>{};

    try {
      // Check if project directory exists
      if (!Directory(projectPath).existsSync()) {
        return ImportManagementResult(
          success: false,
          issues: [
            ImportIssue(
              file: projectPath,
              type: ImportIssueType.projectNotFound,
              message: 'Project directory does not exist',
              line: 0,
            ),
          ],
          fixes: [],
          statistics: {},
          processedFiles: 0,
        );
      }

      final dartFiles = await _getDartFiles(projectPath);
      var processedFiles = 0;
      var totalImports = 0;
      var unusedImports = 0;
      var unsortedFiles = 0;

      for (final file in dartFiles) {
        try {
          final content = await file.readAsString();
          final analysis = _analyzeImports(content, file.path);

          issues.addAll(analysis.issues);
          fixes.addAll(analysis.fixes);
          totalImports += analysis.importCount;
          unusedImports += analysis.unusedImports;

          if (analysis.needsSorting) {
            unsortedFiles++;
          }

          processedFiles++;
        } catch (e) {
          issues.add(ImportIssue(
            file: file.path,
            type: ImportIssueType.analysisError,
            message: 'Failed to analyze file: $e',
            line: 0,
          ),);
        }
      }

      statistics['totalFiles'] = processedFiles;
      statistics['totalImports'] = totalImports;
      statistics['unusedImports'] = unusedImports;
      statistics['unsortedFiles'] = unsortedFiles;

      return ImportManagementResult(
        success: true,
        issues: issues,
        fixes: fixes,
        statistics: statistics,
        processedFiles: processedFiles,
      );
    } catch (e) {
      return ImportManagementResult(
        success: false,
        issues: [
          ImportIssue(
            file: projectPath,
            type: ImportIssueType.analysisError,
            message: 'Import analysis failed: $e',
            line: 0,
          ),
        ],
        fixes: [],
        statistics: {},
        processedFiles: 0,
      );
    }
  }

  @override
  Future<FileOrganizationResult> optimizeFileOrganization(
      String projectPath,) async {
    final suggestions = <OrganizationSuggestion>[];
    final issues = <OrganizationIssue>[];
    final metrics = <String, dynamic>{};

    try {
      // Check if project directory exists
      if (!Directory(projectPath).existsSync()) {
        return FileOrganizationResult(
          success: false,
          suggestions: [],
          issues: [
            OrganizationIssue(
              type: OrganizationIssueType.projectNotFound,
              message: 'Project directory does not exist',
              path: projectPath,
              severity: OrganizationSeverity.error,
            ),
          ],
          metrics: {},
        );
      }

      // Analyze lib directory structure
      final libDir = Directory(path.join(projectPath, 'lib'));
      if (libDir.existsSync()) {
        final libAnalysis = await _analyzeLibraryStructure(libDir);
        suggestions.addAll(libAnalysis.suggestions);
        issues.addAll(libAnalysis.issues);
        metrics.addAll(libAnalysis.metrics);
      }

      // Analyze test directory structure
      final testDir = Directory(path.join(projectPath, 'test'));
      if (testDir.existsSync()) {
        final testAnalysis = await _analyzeTestStructure(testDir, libDir);
        suggestions.addAll(testAnalysis.suggestions);
        issues.addAll(testAnalysis.issues);
      }

      // Analyze asset organization
      final assetAnalysis = await _analyzeAssetOrganization(projectPath);
      suggestions.addAll(assetAnalysis.suggestions);
      issues.addAll(assetAnalysis.issues);

      // Check for common organizational anti-patterns
      final antiPatterns = await _detectOrganizationalAntiPatterns(projectPath);
      suggestions.addAll(antiPatterns.suggestions);
      issues.addAll(antiPatterns.issues);

      return FileOrganizationResult(
        success: true,
        suggestions: suggestions,
        issues: issues,
        metrics: metrics,
      );
    } catch (e) {
      return FileOrganizationResult(
        success: false,
        suggestions: [],
        issues: [
          OrganizationIssue(
            type: OrganizationIssueType.analysisError,
            message: 'File organization analysis failed: $e',
            path: projectPath,
            severity: OrganizationSeverity.error,
          ),
        ],
        metrics: {},
      );
    }
  }

  @override
  Future<ProjectStructureResult> validateProjectStructure(
      String projectPath,) async {
    final validations = <StructureValidation>[];
    final recommendations = <StructureRecommendation>[];
    final score = <String, int>{};

    try {
      // Check if project directory exists
      if (!Directory(projectPath).existsSync()) {
        return const ProjectStructureResult(
          success: false,
          overallScore: 0,
          validations: [
            StructureValidation(
              category: 'project',
              name: 'Project Directory',
              passed: false,
              message: 'Project directory does not exist',
              importance: ValidationImportance.critical,
            ),
          ],
          recommendations: [],
          categoryScores: {},
        );
      }

      // Validate core project structure
      final coreValidation = await _validateCoreStructure(projectPath);
      validations.addAll(coreValidation.validations);
      recommendations.addAll(coreValidation.recommendations);
      score['core'] = coreValidation.score;

      // Validate Flutter-specific structure
      final flutterValidation = await _validateFlutterStructure(projectPath);
      validations.addAll(flutterValidation.validations);
      recommendations.addAll(flutterValidation.recommendations);
      score['flutter'] = flutterValidation.score;

      // Validate package structure (if it's a package)
      final packageValidation = await _validatePackageStructure(projectPath);
      validations.addAll(packageValidation.validations);
      recommendations.addAll(packageValidation.recommendations);
      score['package'] = packageValidation.score;

      // Validate testing structure
      final testingValidation = await _validateTestingStructure(projectPath);
      validations.addAll(testingValidation.validations);
      recommendations.addAll(testingValidation.recommendations);
      score['testing'] = testingValidation.score;

      // Validate documentation structure
      final docsValidation = await _validateDocumentationStructure(projectPath);
      validations.addAll(docsValidation.validations);
      recommendations.addAll(docsValidation.recommendations);
      score['documentation'] = docsValidation.score;

      // Calculate overall score
      final totalScore = score.values.fold(0, (sum, value) => sum + value);
      final maxScore = score.length * 100;
      final overallScore =
          maxScore > 0 ? (totalScore / maxScore * 100).round() : 0;

      return ProjectStructureResult(
        success: true,
        overallScore: overallScore,
        validations: validations,
        recommendations: recommendations,
        categoryScores: score,
      );
    } catch (e) {
      return ProjectStructureResult(
        success: false,
        overallScore: 0,
        validations: [
          StructureValidation(
            category: 'error',
            name: 'Analysis Error',
            passed: false,
            message: 'Project structure validation failed: $e',
            importance: ValidationImportance.critical,
          ),
        ],
        recommendations: [],
        categoryScores: {},
      );
    }
  }

  // Private helper methods

  Future<List<File>> _getDartFiles(String projectPath) async {
    final dartFiles = <File>[];
    final libDir = Directory(path.join(projectPath, 'lib'));
    final testDir = Directory(path.join(projectPath, 'test'));

    for (final dir in [libDir, testDir]) {
      if (dir.existsSync()) {
        await for (final entity in dir.list(recursive: true)) {
          if (entity is File && entity.path.endsWith('.dart')) {
            dartFiles.add(entity);
          }
        }
      }
    }

    return dartFiles;
  }

  _ImportAnalysisResult _analyzeImports(String content, String filePath) {
    final issues = <ImportIssue>[];
    final fixes = <ImportFix>[];
    final lines = content.split('\n');

    final imports = <_ImportInfo>[];
    final usedIdentifiers = <String>{};
    var needsSorting = false;
    var importCount = 0;
    var unusedImports = 0;

    // Extract imports and analyze usage
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.startsWith('import ')) {
        importCount++;
        final importInfo = _parseImportLine(line, i + 1);
        if (importInfo != null) {
          imports.add(importInfo);
        }
      }

      // Simple usage detection (this could be more sophisticated)
      if (!line.startsWith('import ') &&
          !line.startsWith('//') &&
          !line.startsWith('/*')) {
        final words = line.split(RegExp(r'\W+'));
        usedIdentifiers.addAll(words.where((w) => w.isNotEmpty));
      }
    }

    // Check import sorting
    if (imports.length > 1) {
      final sortedImports = List<_ImportInfo>.from(imports)
        ..sort(_compareImports);

      for (var i = 0; i < imports.length; i++) {
        if (imports[i].uri != sortedImports[i].uri) {
          needsSorting = true;
          break;
        }
      }
    }

    // Check for unused imports
    for (final import in imports) {
      if (import.showClause != null) {
        // Check if any shown identifiers are used
        final shownIdentifiers =
            import.showClause!.split(',').map((s) => s.trim());
        final usedFromImport =
            shownIdentifiers.where(usedIdentifiers.contains);

        if (usedFromImport.isEmpty) {
          unusedImports++;
          issues.add(ImportIssue(
            file: filePath,
            type: ImportIssueType.unusedImport,
            message: 'Unused import: ${import.uri}',
            line: import.lineNumber,
            importUri: import.uri,
          ),);

          fixes.add(ImportFix(
            file: filePath,
            type: ImportFixType.removeUnused,
            description: 'Remove unused import',
            line: import.lineNumber,
            originalLine: import.originalLine,
          ),);
        }
      }
    }

    // Check for duplicate imports
    final seenUris = <String>{};
    for (final import in imports) {
      if (seenUris.contains(import.uri)) {
        issues.add(ImportIssue(
          file: filePath,
          type: ImportIssueType.duplicateImport,
          message: 'Duplicate import: ${import.uri}',
          line: import.lineNumber,
          importUri: import.uri,
        ),);

        fixes.add(ImportFix(
          file: filePath,
          type: ImportFixType.removeDuplicate,
          description: 'Remove duplicate import',
          line: import.lineNumber,
          originalLine: import.originalLine,
        ),);
      } else {
        seenUris.add(import.uri);
      }
    }

    // Suggest sorting if needed
    if (needsSorting) {
      issues.add(ImportIssue(
        file: filePath,
        type: ImportIssueType.unsortedImports,
        message: 'Imports are not sorted according to Dart conventions',
        line: imports.first.lineNumber,
      ),);

      fixes.add(ImportFix(
        file: filePath,
        type: ImportFixType.sortImports,
        description: 'Sort imports according to Dart conventions',
        line: imports.first.lineNumber,
      ),);
    }

    return _ImportAnalysisResult(
      issues: issues,
      fixes: fixes,
      importCount: importCount,
      unusedImports: unusedImports,
      needsSorting: needsSorting,
    );
  }

  _ImportInfo? _parseImportLine(String line, int lineNumber) {
    final importRegex = RegExp(
        r'''import\s+['"]([^'"]+)['"](?:\s+as\s+(\w+))?(?:\s+show\s+([^;]+))?(?:\s+hide\s+([^;]+))?;?''',);
    final match = importRegex.firstMatch(line);

    if (match != null) {
      return _ImportInfo(
        uri: match.group(1)!,
        alias: match.group(2),
        showClause: match.group(3),
        hideClause: match.group(4),
        lineNumber: lineNumber,
        originalLine: line,
      );
    }

    return null;
  }

  int _compareImports(_ImportInfo a, _ImportInfo b) {
    // Dart import sorting rules:
    // 1. dart: imports first
    // 2. package: imports second
    // 3. relative imports last
    // Within each group, sort alphabetically

    final aCategory = _getImportCategory(a.uri);
    final bCategory = _getImportCategory(b.uri);

    if (aCategory != bCategory) {
      return aCategory.compareTo(bCategory);
    }

    return a.uri.compareTo(b.uri);
  }

  int _getImportCategory(String uri) {
    if (uri.startsWith('dart:')) return 0;
    if (uri.startsWith('package:')) return 1;
    return 2; // relative imports
  }

  Future<_LibraryAnalysisResult> _analyzeLibraryStructure(
      Directory libDir,) async {
    final suggestions = <OrganizationSuggestion>[];
    final issues = <OrganizationIssue>[];
    final metrics = <String, dynamic>{};

    var totalFiles = 0;
    var dartFiles = 0;
    final directories = <String>[];
    final filesByDepth = <int, int>{};

    await for (final entity in libDir.list(recursive: true)) {
      totalFiles++;

      if (entity is File) {
        if (entity.path.endsWith('.dart')) {
          dartFiles++;
        }

        final relativePath = path.relative(entity.path, from: libDir.path);
        final depth = relativePath.split(path.separator).length - 1;
        filesByDepth[depth] = (filesByDepth[depth] ?? 0) + 1;
      } else if (entity is Directory) {
        final dirName = path.basename(entity.path);
        directories.add(dirName);
      }
    }

    metrics['totalFiles'] = totalFiles;
    metrics['dartFiles'] = dartFiles;
    metrics['directories'] = directories.length;
    metrics['maxDepth'] = filesByDepth.keys.isNotEmpty
        ? filesByDepth.keys.reduce((a, b) => a > b ? a : b)
        : 0;

    // Check for recommended directory structure
    final recommendedDirs = [
      'src',
      'models',
      'services',
      'widgets',
      'screens',
      'utils',
    ];
    final missingDirs =
        recommendedDirs.where((dir) => !directories.contains(dir)).toList();

    if (missingDirs.isNotEmpty && dartFiles > 10) {
      suggestions.add(OrganizationSuggestion(
        type: OrganizationSuggestionType.createDirectories,
        message: 'Consider organizing code into subdirectories',
        details: 'Missing recommended directories: ${missingDirs.join(', ')}',
        path: libDir.path,
        priority: OrganizationPriority.medium,
      ),);
    }

    // Check for files directly in lib root
    final rootFiles = await libDir
        .list()
        .where((entity) =>
            entity is File &&
            entity.path.endsWith('.dart') &&
            path.basename(entity.path) != '${path.basename(libDir.path)}.dart',)
        .length;

    if (rootFiles > 3) {
      issues.add(OrganizationIssue(
        type: OrganizationIssueType.tooManyRootFiles,
        message: 'Too many files in lib root directory',
        path: libDir.path,
        severity: OrganizationSeverity.warning,
      ),);

      suggestions.add(OrganizationSuggestion(
        type: OrganizationSuggestionType.moveFiles,
        message: 'Move implementation files to src/ directory',
        details: 'Keep only the main library file in lib root',
        path: libDir.path,
        priority: OrganizationPriority.high,
      ),);
    }

    // Check directory depth
    final maxDepth = metrics['maxDepth'] as int;
    if (maxDepth > 4) {
      issues.add(OrganizationIssue(
        type: OrganizationIssueType.deepNesting,
        message: 'Directory structure is too deeply nested',
        path: libDir.path,
        severity: OrganizationSeverity.warning,
      ),);
    }

    return _LibraryAnalysisResult(
      suggestions: suggestions,
      issues: issues,
      metrics: metrics,
    );
  }

  Future<_TestAnalysisResult> _analyzeTestStructure(
      Directory testDir, Directory libDir,) async {
    final suggestions = <OrganizationSuggestion>[];
    final issues = <OrganizationIssue>[];

    // Check if test structure mirrors lib structure
    final libFiles = <String>[];
    final testFiles = <String>[];

    await for (final entity in libDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final relativePath = path.relative(entity.path, from: libDir.path);
        libFiles.add(relativePath);
      }
    }

    await for (final entity in testDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('_test.dart')) {
        final relativePath = path.relative(entity.path, from: testDir.path);
        testFiles.add(relativePath);
      }
    }

    // Check for missing test files
    final missingTests = <String>[];
    for (final libFile in libFiles) {
      final expectedTestFile = libFile.replaceAll('.dart', '_test.dart');
      if (!testFiles.any((testFile) => testFile.endsWith(expectedTestFile))) {
        missingTests.add(libFile);
      }
    }

    if (missingTests.isNotEmpty &&
        missingTests.length > libFiles.length * 0.5) {
      suggestions.add(OrganizationSuggestion(
        type: OrganizationSuggestionType.addTests,
        message: 'Consider adding more test files',
        details: 'Many library files lack corresponding test files',
        path: testDir.path,
        priority: OrganizationPriority.medium,
      ),);
    }

    return _TestAnalysisResult(
      suggestions: suggestions,
      issues: issues,
    );
  }

  Future<_AssetAnalysisResult> _analyzeAssetOrganization(
      String projectPath,) async {
    final suggestions = <OrganizationSuggestion>[];
    final issues = <OrganizationIssue>[];

    final assetsDir = Directory(path.join(projectPath, 'assets'));
    if (!assetsDir.existsSync()) {
      return _AssetAnalysisResult(suggestions: suggestions, issues: issues);
    }

    final assetFiles = <String>[];
    await for (final entity in assetsDir.list(recursive: true)) {
      if (entity is File) {
        assetFiles.add(entity.path);
      }
    }

    // Check for asset organization by type
    final imageExtensions = {'.png', '.jpg', '.jpeg', '.gif', '.webp', '.svg'};
    final images = assetFiles
        .where((file) =>
            imageExtensions.contains(path.extension(file).toLowerCase()),)
        .toList();

    // Suggest organizing images into subdirectories
    if (images.length > 5) {
      final imagesInRoot =
          images.where((img) => path.dirname(img) == assetsDir.path).length;

      if (imagesInRoot > 3) {
        suggestions.add(OrganizationSuggestion(
          type: OrganizationSuggestionType.organizeAssets,
          message: 'Organize images into subdirectories',
          details: 'Consider creating images/, icons/, etc. subdirectories',
          path: assetsDir.path,
          priority: OrganizationPriority.low,
        ),);
      }
    }

    return _AssetAnalysisResult(suggestions: suggestions, issues: issues);
  }

  Future<_AntiPatternAnalysisResult> _detectOrganizationalAntiPatterns(
      String projectPath,) async {
    final suggestions = <OrganizationSuggestion>[];
    final issues = <OrganizationIssue>[];

    // Check for god files (files with too many lines)
    final dartFiles = await _getDartFiles(projectPath);
    for (final file in dartFiles) {
      try {
        final content = await file.readAsString();
        final lineCount = content.split('\n').length;

        if (lineCount > 500) {
          issues.add(OrganizationIssue(
            type: OrganizationIssueType.godFile,
            message: 'File is too large ($lineCount lines)',
            path: file.path,
            severity: OrganizationSeverity.warning,
          ),);

          suggestions.add(OrganizationSuggestion(
            type: OrganizationSuggestionType.splitFile,
            message: 'Consider splitting large file into smaller modules',
            details: 'Files over 500 lines are harder to maintain',
            path: file.path,
            priority: OrganizationPriority.medium,
          ),);
        }
      } catch (e) {
        // Skip files that can't be read
      }
    }

    return _AntiPatternAnalysisResult(suggestions: suggestions, issues: issues);
  }

  Future<_StructureValidationResult> _validateCoreStructure(
      String projectPath,) async {
    final validations = <StructureValidation>[];
    final recommendations = <StructureRecommendation>[];
    var score = 0;

    // Check for pubspec.yaml
    final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
    if (pubspecFile.existsSync()) {
      validations.add(const StructureValidation(
        category: 'core',
        name: 'pubspec.yaml',
        passed: true,
        message: 'pubspec.yaml file exists',
        importance: ValidationImportance.critical,
      ),);
      score += 25;
    } else {
      validations.add(const StructureValidation(
        category: 'core',
        name: 'pubspec.yaml',
        passed: false,
        message: 'pubspec.yaml file is missing',
        importance: ValidationImportance.critical,
      ),);
      recommendations.add(const StructureRecommendation(
        category: 'core',
        title: 'Create pubspec.yaml',
        description:
            'Add a pubspec.yaml file to define project dependencies and metadata',
        priority: RecommendationPriority.critical,
      ),);
    }

    // Check for lib directory
    final libDir = Directory(path.join(projectPath, 'lib'));
    if (libDir.existsSync()) {
      validations.add(const StructureValidation(
        category: 'core',
        name: 'lib directory',
        passed: true,
        message: 'lib directory exists',
        importance: ValidationImportance.critical,
      ),);
      score += 25;
    } else {
      validations.add(const StructureValidation(
        category: 'core',
        name: 'lib directory',
        passed: false,
        message: 'lib directory is missing',
        importance: ValidationImportance.critical,
      ),);
      recommendations.add(const StructureRecommendation(
        category: 'core',
        title: 'Create lib directory',
        description: 'Add a lib directory to contain your Dart source code',
        priority: RecommendationPriority.critical,
      ),);
    }

    // Check for README.md
    final readmeFile = File(path.join(projectPath, 'README.md'));
    if (readmeFile.existsSync()) {
      validations.add(const StructureValidation(
        category: 'core',
        name: 'README.md',
        passed: true,
        message: 'README.md file exists',
        importance: ValidationImportance.important,
      ),);
      score += 25;
    } else {
      validations.add(const StructureValidation(
        category: 'core',
        name: 'README.md',
        passed: false,
        message: 'README.md file is missing',
        importance: ValidationImportance.important,
      ),);
      recommendations.add(const StructureRecommendation(
        category: 'core',
        title: 'Add README.md',
        description: 'Create a README.md file to document your project',
        priority: RecommendationPriority.high,
      ),);
    }

    // Check for analysis_options.yaml
    final analysisOptionsFile =
        File(path.join(projectPath, 'analysis_options.yaml'));
    if (analysisOptionsFile.existsSync()) {
      validations.add(const StructureValidation(
        category: 'core',
        name: 'analysis_options.yaml',
        passed: true,
        message: 'analysis_options.yaml file exists',
        importance: ValidationImportance.recommended,
      ),);
      score += 25;
    } else {
      validations.add(const StructureValidation(
        category: 'core',
        name: 'analysis_options.yaml',
        passed: false,
        message: 'analysis_options.yaml file is missing',
        importance: ValidationImportance.recommended,
      ),);
      recommendations.add(const StructureRecommendation(
        category: 'core',
        title: 'Add analysis_options.yaml',
        description: 'Configure static analysis rules for better code quality',
        priority: RecommendationPriority.medium,
      ),);
    }

    return _StructureValidationResult(
      validations: validations,
      recommendations: recommendations,
      score: score,
    );
  }

  Future<_StructureValidationResult> _validateFlutterStructure(
      String projectPath,) async {
    final validations = <StructureValidation>[];
    final recommendations = <StructureRecommendation>[];
    var score = 0;

    // Check if it's a Flutter project
    final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
    var isFlutterProject = false;

    if (pubspecFile.existsSync()) {
      final content = await pubspecFile.readAsString();
      isFlutterProject = content.contains('flutter:');
    }

    if (!isFlutterProject) {
      // Not a Flutter project, give full score
      return const _StructureValidationResult(
        validations: [],
        recommendations: [],
        score: 100,
      );
    }

    // Check for platform directories
    final platforms = ['android', 'ios', 'web', 'windows', 'macos', 'linux'];
    var platformCount = 0;

    for (final platform in platforms) {
      final platformDir = Directory(path.join(projectPath, platform));
      if (platformDir.existsSync()) {
        platformCount++;
      }
    }

    if (platformCount > 0) {
      validations.add(StructureValidation(
        category: 'flutter',
        name: 'Platform support',
        passed: true,
        message: 'Platform directories found ($platformCount platforms)',
        importance: ValidationImportance.important,
      ),);
      score += 50;
    } else {
      validations.add(const StructureValidation(
        category: 'flutter',
        name: 'Platform support',
        passed: false,
        message: 'No platform directories found',
        importance: ValidationImportance.important,
      ),);
      recommendations.add(const StructureRecommendation(
        category: 'flutter',
        title: 'Add platform support',
        description: 'Run flutter create . to add platform-specific code',
        priority: RecommendationPriority.high,
      ),);
    }

    // Check for assets directory
    final assetsDir = Directory(path.join(projectPath, 'assets'));
    if (assetsDir.existsSync()) {
      validations.add(const StructureValidation(
        category: 'flutter',
        name: 'Assets directory',
        passed: true,
        message: 'Assets directory exists',
        importance: ValidationImportance.optional,
      ),);
      score += 25;
    }

    // Check for fonts directory
    final fontsDir = Directory(path.join(projectPath, 'fonts'));
    if (fontsDir.existsSync()) {
      validations.add(const StructureValidation(
        category: 'flutter',
        name: 'Fonts directory',
        passed: true,
        message: 'Fonts directory exists',
        importance: ValidationImportance.optional,
      ),);
      score += 25;
    }

    return _StructureValidationResult(
      validations: validations,
      recommendations: recommendations,
      score: score,
    );
  }

  Future<_StructureValidationResult> _validatePackageStructure(
      String projectPath,) async {
    final validations = <StructureValidation>[];
    final recommendations = <StructureRecommendation>[];
    var score = 0;

    // Check if it's a package (has a lib directory with a main library file)
    final libDir = Directory(path.join(projectPath, 'lib'));
    var isPackage = false;

    if (libDir.existsSync()) {
      final projectName = path.basename(projectPath);
      final mainLibFile =
          File(path.join(projectPath, 'lib', '$projectName.dart'));
      isPackage = mainLibFile.existsSync();
    }

    if (!isPackage) {
      // Not a package, give full score
      return const _StructureValidationResult(
        validations: [],
        recommendations: [],
        score: 100,
      );
    }

    // Check for example directory
    final exampleDir = Directory(path.join(projectPath, 'example'));
    if (exampleDir.existsSync()) {
      validations.add(const StructureValidation(
        category: 'package',
        name: 'Example directory',
        passed: true,
        message: 'Example directory exists',
        importance: ValidationImportance.important,
      ),);
      score += 50;
    } else {
      validations.add(const StructureValidation(
        category: 'package',
        name: 'Example directory',
        passed: false,
        message: 'Example directory is missing',
        importance: ValidationImportance.important,
      ),);
      recommendations.add(const StructureRecommendation(
        category: 'package',
        title: 'Add example directory',
        description: 'Create an example directory with usage examples',
        priority: RecommendationPriority.high,
      ),);
    }

    // Check for CHANGELOG.md
    final changelogFile = File(path.join(projectPath, 'CHANGELOG.md'));
    if (changelogFile.existsSync()) {
      validations.add(const StructureValidation(
        category: 'package',
        name: 'CHANGELOG.md',
        passed: true,
        message: 'CHANGELOG.md file exists',
        importance: ValidationImportance.important,
      ),);
      score += 50;
    } else {
      validations.add(const StructureValidation(
        category: 'package',
        name: 'CHANGELOG.md',
        passed: false,
        message: 'CHANGELOG.md file is missing',
        importance: ValidationImportance.important,
      ),);
      recommendations.add(const StructureRecommendation(
        category: 'package',
        title: 'Add CHANGELOG.md',
        description: 'Create a CHANGELOG.md file to document version changes',
        priority: RecommendationPriority.high,
      ),);
    }

    return _StructureValidationResult(
      validations: validations,
      recommendations: recommendations,
      score: score,
    );
  }

  Future<_StructureValidationResult> _validateTestingStructure(
      String projectPath,) async {
    final validations = <StructureValidation>[];
    final recommendations = <StructureRecommendation>[];
    var score = 0;

    // Check for test directory
    final testDir = Directory(path.join(projectPath, 'test'));
    if (testDir.existsSync()) {
      validations.add(const StructureValidation(
        category: 'testing',
        name: 'Test directory',
        passed: true,
        message: 'Test directory exists',
        importance: ValidationImportance.important,
      ),);
      score += 50;

      // Check for test files
      var testFileCount = 0;
      await for (final entity in testDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('_test.dart')) {
          testFileCount++;
        }
      }

      if (testFileCount > 0) {
        validations.add(StructureValidation(
          category: 'testing',
          name: 'Test files',
          passed: true,
          message: 'Test files found ($testFileCount files)',
          importance: ValidationImportance.important,
        ),);
        score += 50;
      } else {
        validations.add(const StructureValidation(
          category: 'testing',
          name: 'Test files',
          passed: false,
          message: 'No test files found',
          importance: ValidationImportance.important,
        ),);
        recommendations.add(const StructureRecommendation(
          category: 'testing',
          title: 'Add test files',
          description: 'Create test files to verify your code functionality',
          priority: RecommendationPriority.high,
        ),);
      }
    } else {
      validations.add(const StructureValidation(
        category: 'testing',
        name: 'Test directory',
        passed: false,
        message: 'Test directory is missing',
        importance: ValidationImportance.important,
      ),);
      recommendations.add(const StructureRecommendation(
        category: 'testing',
        title: 'Create test directory',
        description: 'Add a test directory to organize your test files',
        priority: RecommendationPriority.high,
      ),);
    }

    return _StructureValidationResult(
      validations: validations,
      recommendations: recommendations,
      score: score,
    );
  }

  Future<_StructureValidationResult> _validateDocumentationStructure(
      String projectPath,) async {
    final validations = <StructureValidation>[];
    final recommendations = <StructureRecommendation>[];
    var score = 0;

    // Check for LICENSE file
    final licenseFile = File(path.join(projectPath, 'LICENSE'));
    if (licenseFile.existsSync()) {
      validations.add(const StructureValidation(
        category: 'documentation',
        name: 'LICENSE file',
        passed: true,
        message: 'LICENSE file exists',
        importance: ValidationImportance.important,
      ),);
      score += 50;
    } else {
      validations.add(const StructureValidation(
        category: 'documentation',
        name: 'LICENSE file',
        passed: false,
        message: 'LICENSE file is missing',
        importance: ValidationImportance.important,
      ),);
      recommendations.add(const StructureRecommendation(
        category: 'documentation',
        title: 'Add LICENSE file',
        description:
            'Add a LICENSE file to specify how others can use your code',
        priority: RecommendationPriority.medium,
      ),);
    }

    // Check for doc directory
    final docDir = Directory(path.join(projectPath, 'doc'));
    if (docDir.existsSync()) {
      validations.add(const StructureValidation(
        category: 'documentation',
        name: 'Documentation directory',
        passed: true,
        message: 'Documentation directory exists',
        importance: ValidationImportance.optional,
      ),);
      score += 50;
    }

    return _StructureValidationResult(
      validations: validations,
      recommendations: recommendations,
      score: score,
    );
  }
}

// Result classes and supporting types

/// Result of import management analysis.
class ImportManagementResult {

  /// Creates a new import management result.
  const ImportManagementResult({
    required this.success,
    required this.issues,
    required this.fixes,
    required this.statistics,
    required this.processedFiles,
  });
  /// Whether the analysis completed successfully.
  final bool success;

  /// List of import issues found.
  final List<ImportIssue> issues;

  /// List of suggested fixes.
  final List<ImportFix> fixes;

  /// Statistics about imports in the project.
  final Map<String, int> statistics;

  /// Number of files processed.
  final int processedFiles;

  /// Whether there are any import issues.
  bool get hasIssues => issues.isNotEmpty;

  /// Number of issues by type.
  Map<ImportIssueType, int> get issuesByType {
    final counts = <ImportIssueType, int>{};
    for (final issue in issues) {
      counts[issue.type] = (counts[issue.type] ?? 0) + 1;
    }
    return counts;
  }
}

/// An issue with import statements.
class ImportIssue {

  /// Creates a new import issue.
  const ImportIssue({
    required this.file,
    required this.type,
    required this.message,
    required this.line,
    this.importUri,
  });
  /// File where the issue was found.
  final String file;

  /// Type of import issue.
  final ImportIssueType type;

  /// Description of the issue.
  final String message;

  /// Line number where the issue occurs.
  final int line;

  /// Import URI (if applicable).
  final String? importUri;
}

/// A suggested fix for import issues.
class ImportFix {

  /// Creates a new import fix.
  const ImportFix({
    required this.file,
    required this.type,
    required this.description,
    required this.line,
    this.originalLine,
    this.replacementLine,
  });
  /// File where the fix should be applied.
  final String file;

  /// Type of fix.
  final ImportFixType type;

  /// Description of the fix.
  final String description;

  /// Line number where the fix should be applied.
  final int line;

  /// Original line content (if applicable).
  final String? originalLine;

  /// Replacement line content (if applicable).
  final String? replacementLine;
}

/// Types of import issues.
enum ImportIssueType {
  /// Import is not used in the file.
  unusedImport,

  /// Import is duplicated.
  duplicateImport,

  /// Imports are not sorted properly.
  unsortedImports,

  /// Project directory not found.
  projectNotFound,

  /// Analysis error occurred.
  analysisError,
}

/// Types of import fixes.
enum ImportFixType {
  /// Remove unused import.
  removeUnused,

  /// Remove duplicate import.
  removeDuplicate,

  /// Sort imports properly.
  sortImports,

  /// Add missing import.
  addMissing,
}

/// Result of file organization analysis.
class FileOrganizationResult {

  /// Creates a new file organization result.
  const FileOrganizationResult({
    required this.success,
    required this.suggestions,
    required this.issues,
    required this.metrics,
  });
  /// Whether the analysis completed successfully.
  final bool success;

  /// List of organization suggestions.
  final List<OrganizationSuggestion> suggestions;

  /// List of organization issues.
  final List<OrganizationIssue> issues;

  /// Organization metrics.
  final Map<String, dynamic> metrics;

  /// Whether there are any organization issues.
  bool get hasIssues => issues.isNotEmpty;

  /// Number of suggestions by priority.
  Map<OrganizationPriority, int> get suggestionsByPriority {
    final counts = <OrganizationPriority, int>{};
    for (final suggestion in suggestions) {
      counts[suggestion.priority] = (counts[suggestion.priority] ?? 0) + 1;
    }
    return counts;
  }
}

/// A suggestion for improving file organization.
class OrganizationSuggestion {

  /// Creates a new organization suggestion.
  const OrganizationSuggestion({
    required this.type,
    required this.message,
    required this.details,
    required this.path,
    required this.priority,
  });
  /// Type of suggestion.
  final OrganizationSuggestionType type;

  /// Description of the suggestion.
  final String message;

  /// Additional details about the suggestion.
  final String details;

  /// Path where the suggestion applies.
  final String path;

  /// Priority of the suggestion.
  final OrganizationPriority priority;
}

/// An issue with file organization.
class OrganizationIssue {

  /// Creates a new organization issue.
  const OrganizationIssue({
    required this.type,
    required this.message,
    required this.path,
    required this.severity,
  });
  /// Type of organization issue.
  final OrganizationIssueType type;

  /// Description of the issue.
  final String message;

  /// Path where the issue was found.
  final String path;

  /// Severity of the issue.
  final OrganizationSeverity severity;
}

/// Types of organization suggestions.
enum OrganizationSuggestionType {
  /// Create new directories.
  createDirectories,

  /// Move files to better locations.
  moveFiles,

  /// Organize assets by type.
  organizeAssets,

  /// Add missing test files.
  addTests,

  /// Split large files.
  splitFile,
}

/// Types of organization issues.
enum OrganizationIssueType {
  /// Too many files in root directory.
  tooManyRootFiles,

  /// Directory structure is too deeply nested.
  deepNesting,

  /// File is too large (god file).
  godFile,

  /// Project directory not found.
  projectNotFound,

  /// Analysis error occurred.
  analysisError,
}

/// Priority levels for organization suggestions.
enum OrganizationPriority {
  /// Low priority suggestion.
  low,

  /// Medium priority suggestion.
  medium,

  /// High priority suggestion.
  high,
}

/// Severity levels for organization issues.
enum OrganizationSeverity {
  /// Warning that should be addressed.
  warning,

  /// Error that must be fixed.
  error,
}

/// Result of project structure validation.
class ProjectStructureResult {

  /// Creates a new project structure result.
  const ProjectStructureResult({
    required this.success,
    required this.overallScore,
    required this.validations,
    required this.recommendations,
    required this.categoryScores,
  });
  /// Whether the validation completed successfully.
  final bool success;

  /// Overall structure score (0-100).
  final int overallScore;

  /// List of structure validations.
  final List<StructureValidation> validations;

  /// List of structure recommendations.
  final List<StructureRecommendation> recommendations;

  /// Scores by category.
  final Map<String, int> categoryScores;

  /// Whether the project structure is considered good.
  bool get hasGoodStructure => overallScore >= 80;

  /// Number of passed validations.
  int get passedValidations => validations.where((v) => v.passed).length;

  /// Number of failed validations.
  int get failedValidations => validations.where((v) => !v.passed).length;
}

/// A structure validation check.
class StructureValidation {

  /// Creates a new structure validation.
  const StructureValidation({
    required this.category,
    required this.name,
    required this.passed,
    required this.message,
    required this.importance,
  });
  /// Category of the validation.
  final String category;

  /// Name of the validation.
  final String name;

  /// Whether the validation passed.
  final bool passed;

  /// Description of the validation result.
  final String message;

  /// Importance level of this validation.
  final ValidationImportance importance;
}

/// A recommendation for improving project structure.
class StructureRecommendation {

  /// Creates a new structure recommendation.
  const StructureRecommendation({
    required this.category,
    required this.title,
    required this.description,
    required this.priority,
  });
  /// Category of the recommendation.
  final String category;

  /// Title of the recommendation.
  final String title;

  /// Detailed description of the recommendation.
  final String description;

  /// Priority of the recommendation.
  final RecommendationPriority priority;
}

/// Importance levels for validations.
enum ValidationImportance {
  /// Critical for project functionality.
  critical,

  /// Important for best practices.
  important,

  /// Recommended but not required.
  recommended,

  /// Optional enhancement.
  optional,
}

/// Priority levels for recommendations.
enum RecommendationPriority {
  /// Critical issue that must be addressed.
  critical,

  /// High priority recommendation.
  high,

  /// Medium priority recommendation.
  medium,

  /// Low priority recommendation.
  low,
}

// Private helper classes

class _ImportInfo {

  const _ImportInfo({
    required this.uri,
    this.alias,
    this.showClause,
    this.hideClause,
    required this.lineNumber,
    required this.originalLine,
  });
  final String uri;
  final String? alias;
  final String? showClause;
  final String? hideClause;
  final int lineNumber;
  final String originalLine;
}

class _ImportAnalysisResult {

  const _ImportAnalysisResult({
    required this.issues,
    required this.fixes,
    required this.importCount,
    required this.unusedImports,
    required this.needsSorting,
  });
  final List<ImportIssue> issues;
  final List<ImportFix> fixes;
  final int importCount;
  final int unusedImports;
  final bool needsSorting;
}

class _LibraryAnalysisResult {

  const _LibraryAnalysisResult({
    required this.suggestions,
    required this.issues,
    required this.metrics,
  });
  final List<OrganizationSuggestion> suggestions;
  final List<OrganizationIssue> issues;
  final Map<String, dynamic> metrics;
}

class _TestAnalysisResult {

  const _TestAnalysisResult({
    required this.suggestions,
    required this.issues,
  });
  final List<OrganizationSuggestion> suggestions;
  final List<OrganizationIssue> issues;
}

class _AssetAnalysisResult {

  const _AssetAnalysisResult({
    required this.suggestions,
    required this.issues,
  });
  final List<OrganizationSuggestion> suggestions;
  final List<OrganizationIssue> issues;
}

class _AntiPatternAnalysisResult {

  const _AntiPatternAnalysisResult({
    required this.suggestions,
    required this.issues,
  });
  final List<OrganizationSuggestion> suggestions;
  final List<OrganizationIssue> issues;
}

class _StructureValidationResult {

  const _StructureValidationResult({
    required this.validations,
    required this.recommendations,
    required this.score,
  });
  final List<StructureValidation> validations;
  final List<StructureRecommendation> recommendations;
  final int score;
}
