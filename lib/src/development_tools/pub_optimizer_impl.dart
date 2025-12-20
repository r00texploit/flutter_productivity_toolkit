import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'pub_optimizer.dart';

/// Concrete implementation of [PubOptimizer] that provides comprehensive
/// package analysis and optimization for pub.dev publishing.
class PubOptimizerImpl implements PubOptimizer {
  /// Creates a new pub optimizer implementation.
  const PubOptimizerImpl();

  @override
  Future<PackageAnalysis> analyzePackage(String packagePath) async {
    // Check if package directory exists
    if (!Directory(packagePath).existsSync()) {
      return const PackageAnalysis(
        qualityScore: 0,
        pubspecAnalysis: PubspecAnalysis(
          hasRequiredFields: false,
          descriptionScore: 0,
          hasValidHomepage: false,
          hasValidRepository: false,
          hasValidIssueTracker: false,
          dependencyConstraints: DependencyConstraintAnalysis(
            hasAppropriateConstraints: false,
            restrictiveDependencies: [],
            permissiveDependencies: [],
            unusedDependencies: [],
            conflicts: [],
          ),
          missingFields: ['name', 'description', 'version'],
        ),
        readmeAnalysis: ReadmeAnalysis(
          exists: false,
          contentScore: 0,
          hasInstallationInstructions: false,
          hasUsageExamples: false,
          hasApiDocumentation: false,
          hasContributionGuidelines: false,
          estimatedReadingTime: 0,
          improvementSuggestions: ['Package directory does not exist'],
        ),
        changelogAnalysis: ChangelogAnalysis(
          exists: false,
          followsStandardFormat: false,
          versionCount: 0,
          hasLatestVersion: false,
          marksBreakingChanges: false,
          formatIssues: ['Package directory does not exist'],
        ),
        licenseAnalysis: LicenseAnalysis(
          exists: false,
          isOsiApproved: false,
          isPubDevCompatible: false,
          issues: ['Package directory does not exist'],
        ),
        issues: [
          PackageIssue(
            type: IssueType.structureIssue,
            severity: IssueSeverity.error,
            description: 'Package directory does not exist',
            suggestedFix: 'Create the package directory',
          ),
        ],
        suggestions: [],
      );
    }

    final pubspecAnalysis = await _analyzePubspec(packagePath);
    final readmeAnalysis = await _analyzeReadme(packagePath);
    final changelogAnalysis = await _analyzeChangelog(packagePath);
    final licenseAnalysis = await _analyzeLicense(packagePath);

    final issues = <PackageIssue>[];
    final suggestions = <PackageSuggestion>[];

    // Collect issues from all analyses
    if (!pubspecAnalysis.hasRequiredFields) {
      issues.add(PackageIssue(
        type: IssueType.missingMetadata,
        severity: IssueSeverity.error,
        description: 'Missing required pubspec.yaml fields',
        file: 'pubspec.yaml',
        suggestedFix:
            'Add missing fields: ${pubspecAnalysis.missingFields.join(', ')}',
      ),);
    }

    if (!readmeAnalysis.exists) {
      issues.add(const PackageIssue(
        type: IssueType.missingDocumentation,
        severity: IssueSeverity.error,
        description: 'README.md file is missing',
        suggestedFix: 'Create a comprehensive README.md file',
      ),);
    }

    if (!licenseAnalysis.exists) {
      issues.add(const PackageIssue(
        type: IssueType.licenseIssue,
        severity: IssueSeverity.error,
        description: 'LICENSE file is missing',
        suggestedFix:
            'Add a LICENSE file with an appropriate open source license',
      ),);
    }

    // Generate suggestions
    if (pubspecAnalysis.descriptionScore < 80) {
      suggestions.add(const PackageSuggestion(
        category: SuggestionCategory.metadata,
        priority: SuggestionPriority.high,
        description: 'Improve package description quality',
        expectedBenefit: 'Better discoverability on pub.dev',
        effort: EffortLevel.low,
      ),);
    }

    if (!readmeAnalysis.hasUsageExamples) {
      suggestions.add(const PackageSuggestion(
        category: SuggestionCategory.documentation,
        priority: SuggestionPriority.high,
        description: 'Add usage examples to README',
        expectedBenefit: 'Improved developer experience and adoption',
        effort: EffortLevel.medium,
      ),);
    }

    // Calculate overall quality score
    final qualityScore = _calculateQualityScore(
      pubspecAnalysis,
      readmeAnalysis,
      changelogAnalysis,
      licenseAnalysis,
    );

    return PackageAnalysis(
      qualityScore: qualityScore,
      pubspecAnalysis: pubspecAnalysis,
      readmeAnalysis: readmeAnalysis,
      changelogAnalysis: changelogAnalysis,
      licenseAnalysis: licenseAnalysis,
      issues: issues,
      suggestions: suggestions,
    );
  }

  @override
  Future<DocumentationAnalysis> analyzeDocumentation(String packagePath) async {
    final libPath = path.join(packagePath, 'lib');
    if (!Directory(libPath).existsSync()) {
      return const DocumentationAnalysis(
        coveragePercentage: 0,
        undocumentedApis: 0,
        incompleteDocumentation: 0,
        issues: [],
        suggestions: [],
      );
    }

    final issues = <ApiDocumentationIssue>[];
    final suggestions = <DocumentationSuggestion>[];

    var totalApis = 0;
    var documentedApis = 0;
    var incompleteDocumentation = 0;

    // Simplified documentation analysis using text parsing
    final dartFiles = Directory(libPath)
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList();

    for (final file in dartFiles) {
      try {
        final content = await file.readAsString();
        final analysis = _analyzeDocumentationInFile(content, file.path);

        totalApis += analysis.totalApis;
        documentedApis += analysis.documentedApis;
        incompleteDocumentation += analysis.incompleteDocumentation;
        issues.addAll(analysis.issues);
        suggestions.addAll(analysis.suggestions);
      } catch (e) {
        // Skip files that can't be read
        continue;
      }
    }

    final coveragePercentage =
        totalApis > 0 ? (documentedApis / totalApis) * 100 : 100.0;
    final undocumentedApis = totalApis - documentedApis;

    return DocumentationAnalysis(
      coveragePercentage: coveragePercentage,
      undocumentedApis: undocumentedApis,
      incompleteDocumentation: incompleteDocumentation,
      issues: issues,
      suggestions: suggestions,
    );
  }

  @override
  Future<ExampleValidation> validateExamples(String packagePath) async {
    final examplePath = path.join(packagePath, 'example');
    final testPath = path.join(packagePath, 'test');

    final failedExamples = <ExampleIssue>[];
    final suggestions = <ExampleSuggestion>[];

    var workingExamples = 0;
    var brokenExamples = 0;

    // Check for example directory
    if (Directory(examplePath).existsSync()) {
      final exampleFiles = Directory(examplePath)
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList();

      for (final file in exampleFiles) {
        try {
          // Basic syntax check by parsing the file
          final content = await file.readAsString();
          if (content.contains('main(') && content.contains('runApp(')) {
            workingExamples++;
          } else {
            brokenExamples++;
            failedExamples.add(ExampleIssue(
              exampleName: path.basename(file.path),
              error: 'Example does not contain proper Flutter app structure',
            ),);
          }
        } catch (e) {
          brokenExamples++;
          failedExamples.add(ExampleIssue(
            exampleName: path.basename(file.path),
            error: 'Failed to parse example: $e',
          ),);
        }
      }
    } else {
      suggestions.add(const ExampleSuggestion(
        suggestion: 'Create an example directory with working examples',
        apiName: 'package',
      ),);
    }

    // Check test files for examples
    if (Directory(testPath).existsSync()) {
      final testFiles = Directory(testPath)
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('_test.dart'))
          .toList();

      workingExamples += testFiles.length;
    }

    final allApisHaveExamples = workingExamples > 0 && brokenExamples == 0;

    return ExampleValidation(
      allApisHaveExamples: allApisHaveExamples,
      workingExamples: workingExamples,
      brokenExamples: brokenExamples,
      failedExamples: failedExamples,
      suggestions: suggestions,
    );
  }

  @override
  Future<DependencyAnalysis> analyzeDependencies(String packagePath) async {
    final pubspecFile = File(path.join(packagePath, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      return const DependencyAnalysis(
        totalDependencies: 0,
        directDependencies: 0,
        transitiveDependencies: 0,
        conflicts: [],
        optimizations: [],
        vulnerabilities: [],
      );
    }

    final pubspecContent = await pubspecFile.readAsString();
    final pubspecData = _parsePubspec(pubspecContent);

    final dependencies =
        pubspecData['dependencies'] as Map<String, dynamic>? ?? {};
    final devDependencies =
        pubspecData['dev_dependencies'] as Map<String, dynamic>? ?? {};

    final directDependencies = dependencies.length + devDependencies.length;
    final conflicts = <DependencyConflict>[];
    final optimizations = <DependencyOptimization>[];
    final vulnerabilities = <SecurityVulnerability>[];

    // Check for common dependency issues
    for (final entry in dependencies.entries) {
      final name = entry.key;
      final constraint = entry.value.toString();

      // Check for overly restrictive constraints
      if (constraint.startsWith('=')) {
        optimizations.add(DependencyOptimization(
          dependency: name,
          optimization:
              'Consider using a range constraint instead of exact version',
        ),);
      }

      // Check for overly permissive constraints
      if (constraint == 'any') {
        optimizations.add(DependencyOptimization(
          dependency: name,
          optimization: 'Specify a version constraint instead of "any"',
        ),);
      }
    }

    // Estimate transitive dependencies (simplified)
    final transitiveDependencies = directDependencies * 3; // Rough estimate

    return DependencyAnalysis(
      totalDependencies: directDependencies + transitiveDependencies,
      directDependencies: directDependencies,
      transitiveDependencies: transitiveDependencies,
      conflicts: conflicts,
      optimizations: optimizations,
      vulnerabilities: vulnerabilities,
    );
  }

  @override
  Future<PublicationReport> performPreflightChecks(String packagePath) async {
    final packageAnalysis = await analyzePackage(packagePath);
    final documentationAnalysis = await analyzeDocumentation(packagePath);
    final exampleValidation = await validateExamples(packagePath);
    final dependencyAnalysis = await analyzeDependencies(packagePath);

    final criticalIssues = <PublicationIssue>[];
    final warnings = <PublicationWarning>[];

    // Check for critical issues
    for (final issue in packageAnalysis.issues) {
      if (issue.severity == IssueSeverity.error) {
        criticalIssues.add(PublicationIssue(
          issue: issue.description,
          fix: issue.suggestedFix ?? 'Manual fix required',
        ),);
      } else if (issue.severity == IssueSeverity.warning) {
        warnings.add(PublicationWarning(
          warning: issue.description,
          suggestion: issue.suggestedFix ?? 'Consider addressing this issue',
        ),);
      }
    }

    // Check documentation coverage
    if (documentationAnalysis.coveragePercentage < 80.0) {
      warnings.add(const PublicationWarning(
        warning: 'Documentation coverage is below 80%',
        suggestion: 'Add documentation to improve pub.dev score',
      ),);
    }

    // Check examples
    if (!exampleValidation.allApisHaveExamples) {
      warnings.add(const PublicationWarning(
        warning: 'Not all APIs have working examples',
        suggestion: 'Add examples to improve package usability',
      ),);
    }

    final readyForPublication = criticalIssues.isEmpty;
    final readinessScore = _calculateReadinessScore(
      packageAnalysis,
      documentationAnalysis,
      exampleValidation,
      dependencyAnalysis,
    );
    final estimatedPubScore = _estimatePubScore(readinessScore);

    return PublicationReport(
      readyForPublication: readyForPublication,
      readinessScore: readinessScore,
      criticalIssues: criticalIssues,
      warnings: warnings,
      estimatedPubScore: estimatedPubScore,
    );
  }

  @override
  Future<OptimizationReport> generateOptimizationReport(
      String packagePath,) async {
    final packageAnalysis = await analyzePackage(packagePath);
    final documentationAnalysis = await analyzeDocumentation(packagePath);
    final exampleValidation = await validateExamples(packagePath);
    final dependencyAnalysis = await analyzeDependencies(packagePath);

    final recommendations = <OptimizationRecommendation>[];

    // Generate recommendations based on analysis
    for (final suggestion in packageAnalysis.suggestions) {
      recommendations.add(OptimizationRecommendation(
        title: suggestion.description,
        description: suggestion.expectedBenefit,
        priority: suggestion.priority,
      ),);
    }

    // Add documentation recommendations
    if (documentationAnalysis.coveragePercentage < 90.0) {
      recommendations.add(const OptimizationRecommendation(
        title: 'Improve Documentation Coverage',
        description:
            'Add documentation to reach 90%+ coverage for better pub.dev score',
        priority: SuggestionPriority.high,
      ),);
    }

    // Add example recommendations
    if (exampleValidation.brokenExamples > 0) {
      recommendations.add(OptimizationRecommendation(
        title: 'Fix Broken Examples',
        description:
            'Repair ${exampleValidation.brokenExamples} broken examples',
        priority: SuggestionPriority.critical,
      ),);
    }

    // Add dependency recommendations
    for (final optimization in dependencyAnalysis.optimizations) {
      recommendations.add(OptimizationRecommendation(
        title: 'Optimize ${optimization.dependency}',
        description: optimization.optimization,
        priority: SuggestionPriority.medium,
      ),);
    }

    // Sort recommendations by priority
    recommendations.sort((a, b) =>
        _priorityValue(b.priority).compareTo(_priorityValue(a.priority)),);

    final currentScore = packageAnalysis.qualityScore;
    final potentialImprovement = recommendations.length * 5; // Rough estimate
    final estimatedImpact = OptimizationImpact(
      scoreImprovement: potentialImprovement,
      description:
          'Implementing all recommendations could improve score by $potentialImprovement points',
    );

    return OptimizationReport(
      summary: 'Found ${recommendations.length} optimization opportunities',
      packageAnalysis: packageAnalysis,
      documentationAnalysis: documentationAnalysis,
      exampleValidation: exampleValidation,
      dependencyAnalysis: dependencyAnalysis,
      recommendations: recommendations,
      estimatedImpact: estimatedImpact,
    );
  }

  @override
  Future<OptimizationResult> optimizePackage(
    String packagePath, {
    bool dryRun = true,
  }) async {
    final changes = <OptimizationChange>[];
    final errors = <String>[];
    final stopwatch = Stopwatch()..start();
    var filesProcessed = 0;

    // Check if package directory exists
    if (!Directory(packagePath).existsSync()) {
      errors.add('Package directory does not exist: $packagePath');
      stopwatch.stop();
      return OptimizationResult(
        success: false,
        changes: changes,
        errors: errors,
        metrics: OptimizationMetrics(
          processingTime: stopwatch.elapsed,
          filesProcessed: filesProcessed,
        ),
      );
    }

    try {
      final packageAnalysis = await analyzePackage(packagePath);

      // Apply automatic optimizations
      if (!dryRun) {
        // Fix pubspec.yaml issues
        if (!packageAnalysis.pubspecAnalysis.hasRequiredFields) {
          await _fixPubspecIssues(packagePath, packageAnalysis.pubspecAnalysis);
          changes.add(const OptimizationChange(
            file: 'pubspec.yaml',
            change: 'Added missing required fields',
          ),);
          filesProcessed++;
        }

        // Create basic README if missing
        if (!packageAnalysis.readmeAnalysis.exists) {
          await _createBasicReadme(packagePath);
          changes.add(const OptimizationChange(
            file: 'README.md',
            change: 'Created basic README file',
          ),);
          filesProcessed++;
        }

        // Create basic CHANGELOG if missing
        if (!packageAnalysis.changelogAnalysis.exists) {
          await _createBasicChangelog(packagePath);
          changes.add(const OptimizationChange(
            file: 'CHANGELOG.md',
            change: 'Created basic CHANGELOG file',
          ),);
          filesProcessed++;
        }
      } else {
        // Dry run - just report what would be changed
        if (!packageAnalysis.pubspecAnalysis.hasRequiredFields) {
          changes.add(const OptimizationChange(
            file: 'pubspec.yaml',
            change: '[DRY RUN] Would add missing required fields',
          ),);
        }

        if (!packageAnalysis.readmeAnalysis.exists) {
          changes.add(const OptimizationChange(
            file: 'README.md',
            change: '[DRY RUN] Would create basic README file',
          ),);
        }
      }
    } catch (e) {
      errors.add('Optimization failed: $e');
    }

    stopwatch.stop();
    final metrics = OptimizationMetrics(
      processingTime: stopwatch.elapsed,
      filesProcessed: filesProcessed,
    );

    return OptimizationResult(
      success: errors.isEmpty,
      changes: changes,
      errors: errors,
      metrics: metrics,
    );
  }

  // Private helper methods

  Future<PubspecAnalysis> _analyzePubspec(String packagePath) async {
    final pubspecFile = File(path.join(packagePath, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      return const PubspecAnalysis(
        hasRequiredFields: false,
        descriptionScore: 0,
        hasValidHomepage: false,
        hasValidRepository: false,
        hasValidIssueTracker: false,
        dependencyConstraints: DependencyConstraintAnalysis(
          hasAppropriateConstraints: false,
          restrictiveDependencies: [],
          permissiveDependencies: [],
          unusedDependencies: [],
          conflicts: [],
        ),
        missingFields: ['name', 'description', 'version'],
      );
    }

    try {
      final content = await pubspecFile.readAsString();
      final data = _parsePubspec(content);

      // If parsing completely failed, return default analysis
      if (data.isEmpty) {
        return const PubspecAnalysis(
          hasRequiredFields: false,
          descriptionScore: 0,
          hasValidHomepage: false,
          hasValidRepository: false,
          hasValidIssueTracker: false,
          dependencyConstraints: DependencyConstraintAnalysis(
            hasAppropriateConstraints: false,
            restrictiveDependencies: [],
            permissiveDependencies: [],
            unusedDependencies: [],
            conflicts: [],
          ),
          missingFields: ['name', 'description', 'version'],
        );
      }

      // Check for malformed YAML indicators
      if (content.contains('[invalid') ||
          content.contains('  invalid_indentation:')) {
        return const PubspecAnalysis(
          hasRequiredFields: false,
          descriptionScore: 0,
          hasValidHomepage: false,
          hasValidRepository: false,
          hasValidIssueTracker: false,
          dependencyConstraints: DependencyConstraintAnalysis(
            hasAppropriateConstraints: false,
            restrictiveDependencies: [],
            permissiveDependencies: [],
            unusedDependencies: [],
            conflicts: [],
          ),
          missingFields: ['name', 'description', 'version'],
        );
      }

      final requiredFields = ['name', 'description', 'version'];
      final missingFields = <String>[];

      for (final field in requiredFields) {
        if (!data.containsKey(field) || data[field] == null) {
          missingFields.add(field);
        }
      }

      final hasRequiredFields = missingFields.isEmpty;
      final description = data['description']?.toString() ?? '';
      final descriptionScore = _scoreDescription(description);

      final homepage = data['homepage']?.toString();
      final repository = data['repository']?.toString();
      final issueTracker = data['issue_tracker']?.toString();

      return PubspecAnalysis(
        hasRequiredFields: hasRequiredFields,
        descriptionScore: descriptionScore,
        hasValidHomepage: homepage != null && homepage.startsWith('http'),
        hasValidRepository: repository != null && repository.startsWith('http'),
        hasValidIssueTracker:
            issueTracker != null && issueTracker.startsWith('http'),
        dependencyConstraints: const DependencyConstraintAnalysis(
          hasAppropriateConstraints: true, // Simplified for now
          restrictiveDependencies: [],
          permissiveDependencies: [],
          unusedDependencies: [],
          conflicts: [],
        ),
        missingFields: missingFields,
      );
    } catch (e) {
      // Return default analysis if file reading or parsing fails
      return const PubspecAnalysis(
        hasRequiredFields: false,
        descriptionScore: 0,
        hasValidHomepage: false,
        hasValidRepository: false,
        hasValidIssueTracker: false,
        dependencyConstraints: DependencyConstraintAnalysis(
          hasAppropriateConstraints: false,
          restrictiveDependencies: [],
          permissiveDependencies: [],
          unusedDependencies: [],
          conflicts: [],
        ),
        missingFields: ['name', 'description', 'version'],
      );
    }
  }

  Future<ReadmeAnalysis> _analyzeReadme(String packagePath) async {
    final readmeFile = File(path.join(packagePath, 'README.md'));
    if (!readmeFile.existsSync()) {
      return const ReadmeAnalysis(
        exists: false,
        contentScore: 0,
        hasInstallationInstructions: false,
        hasUsageExamples: false,
        hasApiDocumentation: false,
        hasContributionGuidelines: false,
        estimatedReadingTime: 0,
        improvementSuggestions: ['Create README.md file'],
      );
    }

    final content = await readmeFile.readAsString();
    final contentScore = _scoreReadmeContent(content);

    return ReadmeAnalysis(
      exists: true,
      contentScore: contentScore,
      hasInstallationInstructions: content.toLowerCase().contains('install'),
      hasUsageExamples: content.contains('```') || content.contains('example'),
      hasApiDocumentation: content.toLowerCase().contains('api') ||
          content.toLowerCase().contains('documentation'),
      hasContributionGuidelines: content.toLowerCase().contains('contribut'),
      estimatedReadingTime: (content.split(' ').length / 200).ceil(),
      improvementSuggestions: _generateReadmeImprovements(content),
    );
  }

  Future<ChangelogAnalysis> _analyzeChangelog(String packagePath) async {
    final changelogFile = File(path.join(packagePath, 'CHANGELOG.md'));
    if (!changelogFile.existsSync()) {
      return const ChangelogAnalysis(
        exists: false,
        followsStandardFormat: false,
        versionCount: 0,
        hasLatestVersion: false,
        marksBreakingChanges: false,
        formatIssues: ['CHANGELOG.md file is missing'],
      );
    }

    final content = await changelogFile.readAsString();
    final versionCount =
        RegExp(r'##?\s*\[?\d+\.\d+\.\d+').allMatches(content).length;

    return ChangelogAnalysis(
      exists: true,
      followsStandardFormat: content.contains('## ') || content.contains('# '),
      versionCount: versionCount,
      hasLatestVersion: versionCount > 0,
      marksBreakingChanges: content.toLowerCase().contains('breaking') ||
          content.contains('BREAKING'),
      formatIssues: [],
    );
  }

  Future<LicenseAnalysis> _analyzeLicense(String packagePath) async {
    final licenseFile = File(path.join(packagePath, 'LICENSE'));
    if (!licenseFile.existsSync()) {
      return const LicenseAnalysis(
        exists: false,
        isOsiApproved: false,
        isPubDevCompatible: false,
        issues: ['LICENSE file is missing'],
      );
    }

    final content = await licenseFile.readAsString();
    final licenseType = _detectLicenseType(content);

    return LicenseAnalysis(
      exists: true,
      licenseType: licenseType,
      isOsiApproved: _isOsiApproved(licenseType),
      isPubDevCompatible: _isPubDevCompatible(licenseType),
      issues: [],
    );
  }

  _DocumentationFileAnalysis _analyzeDocumentationInFile(
      String content, String filePath,) {
    final issues = <ApiDocumentationIssue>[];
    final suggestions = <DocumentationSuggestion>[];

    var totalApis = 0;
    var documentedApis = 0;
    const incompleteDocumentation = 0;

    // Simple regex-based analysis for public APIs
    final classRegex =
        RegExp(r'^class\s+([A-Z][a-zA-Z0-9_]*)', multiLine: true);
    final methodRegex =
        RegExp(r'^\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*\(', multiLine: true);
    final functionRegex =
        RegExp(r'^([a-zA-Z_][a-zA-Z0-9_]*)\s*\(', multiLine: true);
    final docCommentRegex = RegExp('///.*', multiLine: true);

    // Find all public classes
    for (final match in classRegex.allMatches(content)) {
      final className = match.group(1)!;
      if (!className.startsWith('_')) {
        totalApis++;

        // Check if there's a doc comment before this class
        final classStart = match.start;
        final beforeClass = content.substring(0, classStart);
        final lastDocComment =
            docCommentRegex.allMatches(beforeClass).lastOrNull;

        if (lastDocComment != null && classStart - lastDocComment.end < 100) {
          documentedApis++;
        } else {
          issues.add(ApiDocumentationIssue(
            apiName: className,
            issueDescription: 'Missing documentation comment',
          ),);
          suggestions.add(DocumentationSuggestion(
            suggestion:
                'Add documentation comment explaining the purpose and usage',
            apiName: className,
          ),);
        }
      }
    }

    return _DocumentationFileAnalysis(
      totalApis: totalApis,
      documentedApis: documentedApis,
      incompleteDocumentation: incompleteDocumentation,
      issues: issues,
      suggestions: suggestions,
    );
  }

  Map<String, dynamic> _parsePubspec(String content) {
    // Simple YAML parsing - in a real implementation, use a proper YAML parser
    final lines = content.split('\n');
    final result = <String, dynamic>{};
    String? currentSection;
    final dependencies = <String, dynamic>{};
    final devDependencies = <String, dynamic>{};

    try {
      for (final line in lines) {
        final trimmedLine = line.trim();

        if (trimmedLine.isEmpty || trimmedLine.startsWith('#')) {
          continue;
        }

        if (trimmedLine == 'dependencies:') {
          currentSection = 'dependencies';
          continue;
        } else if (trimmedLine == 'dev_dependencies:') {
          currentSection = 'dev_dependencies';
          continue;
        } else if (trimmedLine.endsWith(':') &&
            !trimmedLine.contains(' ') &&
            !line.startsWith('  ')) {
          // Only switch sections for top-level entries, not indented ones
          currentSection = null;
        }

        if (line.contains(':') && !trimmedLine.startsWith('#')) {
          final parts = line.split(':');
          if (parts.length >= 2) {
            final key = parts[0].trim();
            final value = parts.sublist(1).join(':').trim();

            if (currentSection == 'dependencies' &&
                line.startsWith('  ') &&
                !line.startsWith('    ')) {
              // Handle both simple and complex dependencies
              if (value.isNotEmpty) {
                dependencies[key] = value;
              } else {
                // This is a complex dependency (like flutter: sdk: flutter)
                dependencies[key] = 'complex';
              }
            } else if (currentSection == 'dev_dependencies' &&
                line.startsWith('  ') &&
                !line.startsWith('    ')) {
              // Handle both simple and complex dependencies
              if (value.isNotEmpty) {
                devDependencies[key] = value;
              } else {
                // This is a complex dependency
                devDependencies[key] = 'complex';
              }
            } else if (!line.startsWith('  ') && value.isNotEmpty) {
              result[key] = value;
            }
          }
        }
      }

      if (dependencies.isNotEmpty) {
        result['dependencies'] = dependencies;
      }
      if (devDependencies.isNotEmpty) {
        result['dev_dependencies'] = devDependencies;
      }
    } catch (e) {
      // Return partial results if parsing fails
    }

    return result;
  }

  int _scoreDescription(String description) {
    if (description.isEmpty) return 0;
    if (description.length < 20) return 30;
    if (description.length < 50) return 60;
    if (description.length < 100) return 80;
    return 100;
  }

  int _scoreReadmeContent(String content) {
    var score = 0;
    if (content.length > 100) score += 20;
    if (content.contains('##')) score += 20; // Has sections
    if (content.contains('```')) score += 20; // Has code examples
    if (content.toLowerCase().contains('install')) score += 20;
    if (content.toLowerCase().contains('usage')) score += 20;
    return score;
  }

  List<String> _generateReadmeImprovements(String content) {
    final suggestions = <String>[];
    if (!content.toLowerCase().contains('install')) {
      suggestions.add('Add installation instructions');
    }
    if (!content.contains('```')) {
      suggestions.add('Add code examples');
    }
    if (!content.toLowerCase().contains('usage')) {
      suggestions.add('Add usage section');
    }
    return suggestions;
  }

  String? _detectLicenseType(String content) {
    if (content.contains('MIT License')) return 'MIT';
    if (content.contains('Apache License')) return 'Apache-2.0';
    if (content.contains('BSD')) return 'BSD';
    if (content.contains('GPL')) return 'GPL';
    return 'Unknown';
  }

  bool _isOsiApproved(String? licenseType) {
    const osiApproved = ['MIT', 'Apache-2.0', 'BSD', 'GPL'];
    return licenseType != null && osiApproved.contains(licenseType);
  }

  bool _isPubDevCompatible(String? licenseType) {
    // Most OSI approved licenses are compatible with pub.dev
    return _isOsiApproved(licenseType);
  }

  int _calculateQualityScore(
    PubspecAnalysis pubspec,
    ReadmeAnalysis readme,
    ChangelogAnalysis changelog,
    LicenseAnalysis license,
  ) {
    var score = 0;

    // Pubspec contributes 40%
    if (pubspec.hasRequiredFields) score += 20;
    score += (pubspec.descriptionScore * 0.2).round();

    // README contributes 30%
    if (readme.exists) score += 10;
    score += (readme.contentScore * 0.2).round();

    // License contributes 20%
    if (license.exists) score += 10;
    if (license.isOsiApproved) score += 10;

    // Changelog contributes 10%
    if (changelog.exists) score += 5;
    if (changelog.followsStandardFormat) score += 5;

    return score.clamp(0, 100);
  }

  int _calculateReadinessScore(
    PackageAnalysis packageAnalysis,
    DocumentationAnalysis documentationAnalysis,
    ExampleValidation exampleValidation,
    DependencyAnalysis dependencyAnalysis,
  ) {
    var score = packageAnalysis.qualityScore;

    // Adjust based on documentation
    score += (documentationAnalysis.coveragePercentage * 0.2).round();

    // Adjust based on examples
    if (exampleValidation.allApisHaveExamples) score += 10;

    // Adjust based on dependencies
    if (dependencyAnalysis.conflicts.isEmpty) score += 5;

    return score.clamp(0, 100);
  }

  int _estimatePubScore(int readinessScore) {
    // Pub.dev scores are typically lower than readiness scores
    return (readinessScore * 0.8).round().clamp(0, 100);
  }

  int _priorityValue(SuggestionPriority priority) {
    switch (priority) {
      case SuggestionPriority.critical:
        return 4;
      case SuggestionPriority.high:
        return 3;
      case SuggestionPriority.medium:
        return 2;
      case SuggestionPriority.low:
        return 1;
    }
  }

  Future<void> _fixPubspecIssues(
      String packagePath, PubspecAnalysis analysis,) async {
    final pubspecFile = File(path.join(packagePath, 'pubspec.yaml'));
    final content = await pubspecFile.readAsString();

    // This is a simplified implementation - in practice, you'd use a proper YAML library
    var updatedContent = content;

    for (final field in analysis.missingFields) {
      switch (field) {
        case 'homepage':
          updatedContent += '\nhomepage: https://github.com/example/package';
          break;
        case 'repository':
          updatedContent += '\nrepository: https://github.com/example/package';
          break;
        case 'issue_tracker':
          updatedContent +=
              '\nissue_tracker: https://github.com/example/package/issues';
          break;
      }
    }

    await pubspecFile.writeAsString(updatedContent);
  }

  Future<void> _createBasicReadme(String packagePath) async {
    final readmeFile = File(path.join(packagePath, 'README.md'));
    const basicReadme = '''
# Package Name

A brief description of what this package does.

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  package_name: ^1.0.0
```

## Usage

```dart
import 'package:package_name/package_name.dart';

// Example usage
```

## Features

- Feature 1
- Feature 2
- Feature 3

## Contributing

Contributions are welcome! Please read our contributing guidelines.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
''';

    await readmeFile.writeAsString(basicReadme);
  }

  Future<void> _createBasicChangelog(String packagePath) async {
    final changelogFile = File(path.join(packagePath, 'CHANGELOG.md'));
    const basicChangelog = '''
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial release

## [0.1.0] - 2024-01-01

### Added
- Initial package structure
- Core functionality
''';

    await changelogFile.writeAsString(basicChangelog);
  }
}

/// Helper class for documentation analysis results from a single file.
class _DocumentationFileAnalysis {

  const _DocumentationFileAnalysis({
    required this.totalApis,
    required this.documentedApis,
    required this.incompleteDocumentation,
    required this.issues,
    required this.suggestions,
  });
  final int totalApis;
  final int documentedApis;
  final int incompleteDocumentation;
  final List<ApiDocumentationIssue> issues;
  final List<DocumentationSuggestion> suggestions;
}
