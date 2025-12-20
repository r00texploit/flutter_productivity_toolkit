import 'dart:async';
import 'dart:io';


import 'pub_optimizer.dart';
import 'pub_optimizer_impl.dart';

/// Comprehensive publication utilities for streamlining the pub.dev publishing process.
///
/// Provides high-level utilities that combine multiple optimization and validation
/// steps into convenient workflows for package developers.
class PublicationUtilities {

  /// Creates a new instance of publication utilities.
  const PublicationUtilities({PubOptimizer? optimizer})
      : _optimizer = optimizer ?? const PubOptimizerImpl();
  final PubOptimizer _optimizer;

  /// Performs a complete pre-publication workflow.
  ///
  /// This is a comprehensive utility that:
  /// 1. Analyzes the package for issues
  /// 2. Performs pre-flight checks
  /// 3. Generates optimization recommendations
  /// 4. Optionally applies automatic fixes
  /// 5. Generates a final publication report
  ///
  /// Returns a [PublicationWorkflowResult] with all analysis results
  /// and recommendations for the developer.
  Future<PublicationWorkflowResult> runCompleteWorkflow(
    String packagePath, {
    bool applyAutomaticFixes = false,
    bool generateDetailedReport = true,
  }) async {
    final stopwatch = Stopwatch()..start();
    final steps = <WorkflowStep>[];
    final errors = <String>[];

    try {
      // Check if package directory exists first
      if (!Directory(packagePath).existsSync()) {
        errors.add('Package directory does not exist: $packagePath');
        stopwatch.stop();
        return PublicationWorkflowResult(
          success: false,
          packageAnalysis: null,
          documentationAnalysis: null,
          exampleValidation: null,
          dependencyAnalysis: null,
          preflightReport: null,
          optimizationResult: null,
          detailedReport: null,
          workflowSteps: steps,
          totalDuration: stopwatch.elapsed,
          errors: errors,
        );
      }

      // Step 1: Package Analysis
      steps.add(WorkflowStep(
        name: 'Package Analysis',
        status: WorkflowStepStatus.running,
        startTime: DateTime.now(),
      ),);

      final packageAnalysis = await _optimizer.analyzePackage(packagePath);

      steps.last = steps.last.copyWith(
        status: WorkflowStepStatus.completed,
        endTime: DateTime.now(),
        result: 'Quality Score: ${packageAnalysis.qualityScore}/100',
      );

      // Step 2: Documentation Analysis
      steps.add(WorkflowStep(
        name: 'Documentation Analysis',
        status: WorkflowStepStatus.running,
        startTime: DateTime.now(),
      ),);

      final documentationAnalysis =
          await _optimizer.analyzeDocumentation(packagePath);

      steps.last = steps.last.copyWith(
        status: WorkflowStepStatus.completed,
        endTime: DateTime.now(),
        result:
            'Coverage: ${documentationAnalysis.coveragePercentage.toStringAsFixed(1)}%',
      );

      // Step 3: Example Validation
      steps.add(WorkflowStep(
        name: 'Example Validation',
        status: WorkflowStepStatus.running,
        startTime: DateTime.now(),
      ),);

      final exampleValidation = await _optimizer.validateExamples(packagePath);

      steps.last = steps.last.copyWith(
        status: WorkflowStepStatus.completed,
        endTime: DateTime.now(),
        result:
            'Working: ${exampleValidation.workingExamples}, Broken: ${exampleValidation.brokenExamples}',
      );

      // Step 4: Dependency Analysis
      steps.add(WorkflowStep(
        name: 'Dependency Analysis',
        status: WorkflowStepStatus.running,
        startTime: DateTime.now(),
      ),);

      final dependencyAnalysis =
          await _optimizer.analyzeDependencies(packagePath);

      steps.last = steps.last.copyWith(
        status: WorkflowStepStatus.completed,
        endTime: DateTime.now(),
        result:
            'Dependencies: ${dependencyAnalysis.directDependencies}, Conflicts: ${dependencyAnalysis.conflicts.length}',
      );

      // Step 5: Pre-flight Checks
      steps.add(WorkflowStep(
        name: 'Pre-flight Checks',
        status: WorkflowStepStatus.running,
        startTime: DateTime.now(),
      ),);

      final preflightReport =
          await _optimizer.performPreflightChecks(packagePath);

      steps.last = steps.last.copyWith(
        status: preflightReport.readyForPublication
            ? WorkflowStepStatus.completed
            : WorkflowStepStatus.failed,
        endTime: DateTime.now(),
        result: preflightReport.readyForPublication
            ? 'Ready for publication'
            : '${preflightReport.criticalIssues.length} critical issues found',
      );

      // Step 6: Apply Automatic Fixes (if requested)
      OptimizationResult? optimizationResult;
      if (applyAutomaticFixes) {
        steps.add(WorkflowStep(
          name: 'Automatic Optimization',
          status: WorkflowStepStatus.running,
          startTime: DateTime.now(),
        ),);

        optimizationResult = await _optimizer.optimizePackage(
          packagePath,
          dryRun: false,
        );

        steps.last = steps.last.copyWith(
          status: optimizationResult.success
              ? WorkflowStepStatus.completed
              : WorkflowStepStatus.failed,
          endTime: DateTime.now(),
          result: optimizationResult.success
              ? '${optimizationResult.changes.length} optimizations applied'
              : 'Optimization failed: ${optimizationResult.errors.join(', ')}',
        );

        if (!optimizationResult.success) {
          errors.addAll(optimizationResult.errors);
        }
      }

      // Step 7: Generate Detailed Report (if requested)
      OptimizationReport? detailedReport;
      if (generateDetailedReport) {
        steps.add(WorkflowStep(
          name: 'Report Generation',
          status: WorkflowStepStatus.running,
          startTime: DateTime.now(),
        ),);

        detailedReport =
            await _optimizer.generateOptimizationReport(packagePath);

        steps.last = steps.last.copyWith(
          status: WorkflowStepStatus.completed,
          endTime: DateTime.now(),
          result:
              '${detailedReport.recommendations.length} recommendations generated',
        );
      }

      stopwatch.stop();

      return PublicationWorkflowResult(
        success: errors.isEmpty && preflightReport.readyForPublication,
        packageAnalysis: packageAnalysis,
        documentationAnalysis: documentationAnalysis,
        exampleValidation: exampleValidation,
        dependencyAnalysis: dependencyAnalysis,
        preflightReport: preflightReport,
        optimizationResult: optimizationResult,
        detailedReport: detailedReport,
        workflowSteps: steps,
        totalDuration: stopwatch.elapsed,
        errors: errors,
      );
    } catch (e) {
      stopwatch.stop();
      errors.add('Workflow failed: $e');

      // Mark current step as failed if it exists
      if (steps.isNotEmpty && steps.last.status == WorkflowStepStatus.running) {
        steps.last = steps.last.copyWith(
          status: WorkflowStepStatus.failed,
          endTime: DateTime.now(),
          result: 'Failed: $e',
        );
      }

      return PublicationWorkflowResult(
        success: false,
        packageAnalysis: null,
        documentationAnalysis: null,
        exampleValidation: null,
        dependencyAnalysis: null,
        preflightReport: null,
        optimizationResult: null,
        detailedReport: null,
        workflowSteps: steps,
        totalDuration: stopwatch.elapsed,
        errors: errors,
      );
    }
  }

  /// Validates package readiness for publication with a simple pass/fail result.
  ///
  /// This is a lightweight utility that quickly checks if a package meets
  /// the minimum requirements for publication to pub.dev.
  ///
  /// Returns `true` if the package is ready for publication, `false` otherwise.
  Future<bool> isPackageReadyForPublication(String packagePath) async {
    try {
      final report = await _optimizer.performPreflightChecks(packagePath);
      return report.readyForPublication;
    } catch (e) {
      return false;
    }
  }

  /// Generates a publication checklist for manual review.
  ///
  /// Creates a comprehensive checklist that developers can use to manually
  /// verify their package before publication. Includes both automated checks
  /// and manual verification items.
  Future<PublicationChecklist> generatePublicationChecklist(
    String packagePath,
  ) async {
    final packageAnalysis = await _optimizer.analyzePackage(packagePath);
    final documentationAnalysis =
        await _optimizer.analyzeDocumentation(packagePath);
    final exampleValidation = await _optimizer.validateExamples(packagePath);
    final dependencyAnalysis =
        await _optimizer.analyzeDependencies(packagePath);

    final items = <ChecklistItem>[];

    // Package metadata checks
    items.add(ChecklistItem(
      category: ChecklistCategory.metadata,
      description:
          'Package has required metadata fields (name, description, version)',
      status: packageAnalysis.pubspecAnalysis.hasRequiredFields
          ? ChecklistStatus.passed
          : ChecklistStatus.failed,
      isAutomated: true,
    ),);

    items.add(ChecklistItem(
      category: ChecklistCategory.metadata,
      description: 'Package description is descriptive and informative',
      status: packageAnalysis.pubspecAnalysis.descriptionScore >= 80
          ? ChecklistStatus.passed
          : ChecklistStatus.failed,
      isAutomated: true,
    ),);

    items.add(ChecklistItem(
      category: ChecklistCategory.metadata,
      description: 'Package has valid homepage URL',
      status: packageAnalysis.pubspecAnalysis.hasValidHomepage
          ? ChecklistStatus.passed
          : ChecklistStatus.failed,
      isAutomated: true,
    ),);

    items.add(ChecklistItem(
      category: ChecklistCategory.metadata,
      description: 'Package has valid repository URL',
      status: packageAnalysis.pubspecAnalysis.hasValidRepository
          ? ChecklistStatus.passed
          : ChecklistStatus.failed,
      isAutomated: true,
    ),);

    // Documentation checks
    items.add(ChecklistItem(
      category: ChecklistCategory.documentation,
      description: 'README.md file exists and is comprehensive',
      status: packageAnalysis.readmeAnalysis.exists
          ? ChecklistStatus.passed
          : ChecklistStatus.failed,
      isAutomated: true,
    ),);

    items.add(ChecklistItem(
      category: ChecklistCategory.documentation,
      description: 'API documentation coverage is above 80%',
      status: documentationAnalysis.coveragePercentage >= 80.0
          ? ChecklistStatus.passed
          : ChecklistStatus.failed,
      isAutomated: true,
    ),);

    items.add(ChecklistItem(
      category: ChecklistCategory.documentation,
      description: 'CHANGELOG.md follows standard format',
      status: packageAnalysis.changelogAnalysis.followsStandardFormat
          ? ChecklistStatus.passed
          : ChecklistStatus.failed,
      isAutomated: true,
    ),);

    // License checks
    items.add(ChecklistItem(
      category: ChecklistCategory.legal,
      description: 'LICENSE file exists with OSI-approved license',
      status: packageAnalysis.licenseAnalysis.exists &&
              packageAnalysis.licenseAnalysis.isOsiApproved
          ? ChecklistStatus.passed
          : ChecklistStatus.failed,
      isAutomated: true,
    ),);

    // Example checks
    items.add(ChecklistItem(
      category: ChecklistCategory.examples,
      description: 'All public APIs have working examples',
      status: exampleValidation.allApisHaveExamples
          ? ChecklistStatus.passed
          : ChecklistStatus.failed,
      isAutomated: true,
    ),);

    items.add(ChecklistItem(
      category: ChecklistCategory.examples,
      description: 'Example code compiles and runs without errors',
      status: exampleValidation.brokenExamples == 0
          ? ChecklistStatus.passed
          : ChecklistStatus.failed,
      isAutomated: true,
    ),);

    // Dependency checks
    items.add(ChecklistItem(
      category: ChecklistCategory.dependencies,
      description: 'No dependency conflicts detected',
      status: dependencyAnalysis.conflicts.isEmpty
          ? ChecklistStatus.passed
          : ChecklistStatus.failed,
      isAutomated: true,
    ),);

    items.add(ChecklistItem(
      category: ChecklistCategory.dependencies,
      description: 'No security vulnerabilities in dependencies',
      status: dependencyAnalysis.vulnerabilities.isEmpty
          ? ChecklistStatus.passed
          : ChecklistStatus.failed,
      isAutomated: true,
    ),);

    // Manual verification items
    items.add(const ChecklistItem(
      category: ChecklistCategory.testing,
      description: 'All tests pass on supported platforms',
      status: ChecklistStatus.manual,
      isAutomated: false,
    ),);

    items.add(const ChecklistItem(
      category: ChecklistCategory.testing,
      description: 'Package has been tested with example applications',
      status: ChecklistStatus.manual,
      isAutomated: false,
    ),);

    items.add(const ChecklistItem(
      category: ChecklistCategory.quality,
      description: 'Code follows Dart/Flutter style guidelines',
      status: ChecklistStatus.manual,
      isAutomated: false,
    ),);

    items.add(const ChecklistItem(
      category: ChecklistCategory.quality,
      description: 'Breaking changes are documented in CHANGELOG',
      status: ChecklistStatus.manual,
      isAutomated: false,
    ),);

    items.add(const ChecklistItem(
      category: ChecklistCategory.legal,
      description: 'All third-party code is properly attributed',
      status: ChecklistStatus.manual,
      isAutomated: false,
    ),);

    final passedItems =
        items.where((item) => item.status == ChecklistStatus.passed).length;
    final failedItems =
        items.where((item) => item.status == ChecklistStatus.failed).length;
    final manualItems =
        items.where((item) => item.status == ChecklistStatus.manual).length;

    return PublicationChecklist(
      items: items,
      totalItems: items.length,
      passedItems: passedItems,
      failedItems: failedItems,
      manualItems: manualItems,
      overallStatus: failedItems == 0
          ? (manualItems == 0 ? ChecklistStatus.passed : ChecklistStatus.manual)
          : ChecklistStatus.failed,
    );
  }

  /// Estimates the pub.dev score for a package before publication.
  ///
  /// Provides developers with an estimate of what their pub.dev score
  /// might be after publication, helping them optimize before publishing.
  Future<PubScoreEstimate> estimatePubScore(String packagePath) async {
    final packageAnalysis = await _optimizer.analyzePackage(packagePath);
    final documentationAnalysis =
        await _optimizer.analyzeDocumentation(packagePath);
    final exampleValidation = await _optimizer.validateExamples(packagePath);
    final dependencyAnalysis =
        await _optimizer.analyzeDependencies(packagePath);

    // Calculate component scores based on pub.dev scoring criteria
    final likesScore = _estimateLikesScore(packageAnalysis);
    final pubPointsScore = _estimatePubPointsScore(
      packageAnalysis,
      documentationAnalysis,
      exampleValidation,
      dependencyAnalysis,
    );
    final popularityScore = _estimatePopularityScore(packageAnalysis);

    final overallScore =
        ((likesScore + pubPointsScore + popularityScore) / 3).round();

    return PubScoreEstimate(
      overallScore: overallScore,
      likesScore: likesScore,
      pubPointsScore: pubPointsScore,
      popularityScore: popularityScore,
      confidence: _calculateConfidence(packageAnalysis),
      recommendations: _generateScoreRecommendations(
        packageAnalysis,
        documentationAnalysis,
        exampleValidation,
        dependencyAnalysis,
      ),
    );
  }

  /// Creates a publication summary report for sharing with team members.
  ///
  /// Generates a concise, human-readable report that can be shared with
  /// team members or stakeholders to communicate publication readiness.
  Future<String> generatePublicationSummary(String packagePath) async {
    final workflowResult = await runCompleteWorkflow(
      packagePath,
      generateDetailedReport: false,
    );

    final buffer = StringBuffer();
    buffer.writeln('# Publication Summary Report');
    buffer.writeln();
    buffer.writeln('**Package Path:** $packagePath');
    buffer.writeln('**Generated:** ${DateTime.now().toIso8601String()}');
    buffer.writeln(
        '**Overall Status:** ${workflowResult.success ? "✅ Ready" : "❌ Not Ready"}',);
    buffer.writeln();

    if (workflowResult.packageAnalysis != null) {
      buffer.writeln('## Package Quality');
      buffer.writeln(
          '- **Quality Score:** ${workflowResult.packageAnalysis!.qualityScore}/100',);
      buffer.writeln(
          '- **Critical Issues:** ${workflowResult.packageAnalysis!.issues.where((i) => i.severity == IssueSeverity.error).length}',);
      buffer.writeln(
          '- **Suggestions:** ${workflowResult.packageAnalysis!.suggestions.length}',);
      buffer.writeln();
    }

    if (workflowResult.documentationAnalysis != null) {
      buffer.writeln('## Documentation');
      buffer.writeln(
          '- **Coverage:** ${workflowResult.documentationAnalysis!.coveragePercentage.toStringAsFixed(1)}%',);
      buffer.writeln(
          '- **Undocumented APIs:** ${workflowResult.documentationAnalysis!.undocumentedApis}',);
      buffer.writeln();
    }

    if (workflowResult.exampleValidation != null) {
      buffer.writeln('## Examples');
      buffer.writeln(
          '- **Working Examples:** ${workflowResult.exampleValidation!.workingExamples}',);
      buffer.writeln(
          '- **Broken Examples:** ${workflowResult.exampleValidation!.brokenExamples}',);
      buffer.writeln();
    }

    if (workflowResult.preflightReport != null) {
      buffer.writeln('## Publication Readiness');
      buffer.writeln(
          '- **Ready for Publication:** ${workflowResult.preflightReport!.readyForPublication ? "Yes" : "No"}',);
      buffer.writeln(
          '- **Estimated pub.dev Score:** ${workflowResult.preflightReport!.estimatedPubScore}/100',);
      buffer.writeln();

      if (workflowResult.preflightReport!.criticalIssues.isNotEmpty) {
        buffer.writeln('### Critical Issues to Fix:');
        for (final issue in workflowResult.preflightReport!.criticalIssues) {
          buffer.writeln('- ${issue.issue}');
        }
        buffer.writeln();
      }
    }

    buffer.writeln('## Workflow Steps');
    for (final step in workflowResult.workflowSteps) {
      final statusIcon = switch (step.status) {
        WorkflowStepStatus.completed => '✅',
        WorkflowStepStatus.failed => '❌',
        WorkflowStepStatus.running => '🔄',
        WorkflowStepStatus.pending => '⏳',
      };
      buffer
          .writeln('- $statusIcon ${step.name}: ${step.result ?? "No result"}');
    }

    buffer.writeln();
    buffer.writeln(
        '**Total Processing Time:** ${workflowResult.totalDuration.inMilliseconds}ms',);

    return buffer.toString();
  }

  // Private helper methods for score estimation

  int _estimateLikesScore(PackageAnalysis analysis) {
    // Likes are primarily driven by package quality and usefulness
    // This is a rough estimation based on quality indicators
    var score = analysis.qualityScore;

    // Bonus for comprehensive documentation
    if (analysis.readmeAnalysis.hasUsageExamples) score += 5;
    if (analysis.readmeAnalysis.hasApiDocumentation) score += 5;

    // Bonus for proper licensing
    if (analysis.licenseAnalysis.isOsiApproved) score += 5;

    return score.clamp(0, 100);
  }

  int _estimatePubPointsScore(
    PackageAnalysis packageAnalysis,
    DocumentationAnalysis documentationAnalysis,
    ExampleValidation exampleValidation,
    DependencyAnalysis dependencyAnalysis,
  ) {
    var score = 0;

    // Follow Dart file conventions (10 points)
    score += packageAnalysis.pubspecAnalysis.hasRequiredFields ? 10 : 0;

    // Provide documentation (10 points)
    score += documentationAnalysis.coveragePercentage >= 80
        ? 10
        : (documentationAnalysis.coveragePercentage * 0.125).round();

    // Platform support (20 points) - assume full support for estimation
    score += 20;

    // Pass static analysis (30 points) - estimate based on quality
    score += (packageAnalysis.qualityScore * 0.3).round();

    // Support up-to-date dependencies (10 points)
    score += dependencyAnalysis.conflicts.isEmpty ? 10 : 5;

    // Support null safety (20 points) - assume supported for modern packages
    score += 20;

    return score.clamp(0, 100);
  }

  int _estimatePopularityScore(PackageAnalysis analysis) {
    // Popularity is hard to estimate without actual usage data
    // Base it on package quality as a proxy
    return (analysis.qualityScore * 0.7).round().clamp(0, 100);
  }

  double _calculateConfidence(PackageAnalysis analysis) {
    // Higher confidence for packages with more complete metadata
    var confidence = 0.5; // Base confidence

    if (analysis.pubspecAnalysis.hasRequiredFields) confidence += 0.2;
    if (analysis.readmeAnalysis.exists) confidence += 0.1;
    if (analysis.changelogAnalysis.exists) confidence += 0.1;
    if (analysis.licenseAnalysis.exists) confidence += 0.1;

    return confidence.clamp(0.0, 1.0);
  }

  List<String> _generateScoreRecommendations(
    PackageAnalysis packageAnalysis,
    DocumentationAnalysis documentationAnalysis,
    ExampleValidation exampleValidation,
    DependencyAnalysis dependencyAnalysis,
  ) {
    final recommendations = <String>[];

    if (packageAnalysis.pubspecAnalysis.descriptionScore < 80) {
      recommendations.add(
          'Improve package description to be more descriptive and informative',);
    }

    if (documentationAnalysis.coveragePercentage < 90) {
      recommendations.add(
          'Increase API documentation coverage to 90%+ for better pub points',);
    }

    if (!exampleValidation.allApisHaveExamples) {
      recommendations.add('Add working examples for all public APIs');
    }

    if (dependencyAnalysis.conflicts.isNotEmpty) {
      recommendations
          .add('Resolve dependency conflicts to improve compatibility');
    }

    if (!packageAnalysis.readmeAnalysis.hasUsageExamples) {
      recommendations.add('Add comprehensive usage examples to README');
    }

    return recommendations;
  }
}

/// Result of running the complete publication workflow.
class PublicationWorkflowResult {

  /// Creates a new publication workflow result.
  const PublicationWorkflowResult({
    required this.success,
    required this.packageAnalysis,
    required this.documentationAnalysis,
    required this.exampleValidation,
    required this.dependencyAnalysis,
    required this.preflightReport,
    required this.optimizationResult,
    required this.detailedReport,
    required this.workflowSteps,
    required this.totalDuration,
    required this.errors,
  });
  /// Whether the workflow completed successfully.
  final bool success;

  /// Package analysis results.
  final PackageAnalysis? packageAnalysis;

  /// Documentation analysis results.
  final DocumentationAnalysis? documentationAnalysis;

  /// Example validation results.
  final ExampleValidation? exampleValidation;

  /// Dependency analysis results.
  final DependencyAnalysis? dependencyAnalysis;

  /// Pre-flight check results.
  final PublicationReport? preflightReport;

  /// Optimization results (if automatic fixes were applied).
  final OptimizationResult? optimizationResult;

  /// Detailed optimization report (if requested).
  final OptimizationReport? detailedReport;

  /// List of workflow steps and their status.
  final List<WorkflowStep> workflowSteps;

  /// Total time taken to complete the workflow.
  final Duration totalDuration;

  /// Any errors that occurred during the workflow.
  final List<String> errors;
}

/// Represents a single step in the publication workflow.
class WorkflowStep {

  /// Creates a new workflow step.
  const WorkflowStep({
    required this.name,
    required this.status,
    this.startTime,
    this.endTime,
    this.result,
  });
  /// Name of the workflow step.
  final String name;

  /// Current status of the step.
  final WorkflowStepStatus status;

  /// When the step started.
  final DateTime? startTime;

  /// When the step completed.
  final DateTime? endTime;

  /// Result or output of the step.
  final String? result;

  /// Creates a copy of this step with updated values.
  WorkflowStep copyWith({
    String? name,
    WorkflowStepStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    String? result,
  }) => WorkflowStep(
      name: name ?? this.name,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      result: result ?? this.result,
    );

  /// Duration of the step (if completed).
  Duration? get duration {
    if (startTime != null && endTime != null) {
      return endTime!.difference(startTime!);
    }
    return null;
  }
}

/// Status of a workflow step.
enum WorkflowStepStatus {
  /// Step is waiting to be executed.
  pending,

  /// Step is currently running.
  running,

  /// Step completed successfully.
  completed,

  /// Step failed with an error.
  failed,
}

/// A comprehensive checklist for package publication readiness.
class PublicationChecklist {

  /// Creates a new publication checklist.
  const PublicationChecklist({
    required this.items,
    required this.totalItems,
    required this.passedItems,
    required this.failedItems,
    required this.manualItems,
    required this.overallStatus,
  });
  /// List of checklist items.
  final List<ChecklistItem> items;

  /// Total number of checklist items.
  final int totalItems;

  /// Number of items that passed automated checks.
  final int passedItems;

  /// Number of items that failed automated checks.
  final int failedItems;

  /// Number of items requiring manual verification.
  final int manualItems;

  /// Overall checklist status.
  final ChecklistStatus overallStatus;

  /// Completion percentage (excluding manual items).
  double get completionPercentage {
    final automatedItems = totalItems - manualItems;
    if (automatedItems == 0) return 100;
    return (passedItems / automatedItems) * 100.0;
  }
}

/// A single item in the publication checklist.
class ChecklistItem {

  /// Creates a new checklist item.
  const ChecklistItem({
    required this.category,
    required this.description,
    required this.status,
    required this.isAutomated,
  });
  /// Category of the checklist item.
  final ChecklistCategory category;

  /// Description of what needs to be checked.
  final String description;

  /// Current status of the item.
  final ChecklistStatus status;

  /// Whether this item can be checked automatically.
  final bool isAutomated;
}

/// Categories for checklist items.
enum ChecklistCategory {
  /// Package metadata and configuration.
  metadata,

  /// Documentation and API docs.
  documentation,

  /// Examples and sample code.
  examples,

  /// Dependencies and version constraints.
  dependencies,

  /// Testing and quality assurance.
  testing,

  /// Code quality and style.
  quality,

  /// Legal and licensing.
  legal,
}

/// Status of a checklist item.
enum ChecklistStatus {
  /// Item passed automated checks.
  passed,

  /// Item failed automated checks.
  failed,

  /// Item requires manual verification.
  manual,
}

/// Estimated pub.dev score for a package.
class PubScoreEstimate {

  /// Creates a new pub score estimate.
  const PubScoreEstimate({
    required this.overallScore,
    required this.likesScore,
    required this.pubPointsScore,
    required this.popularityScore,
    required this.confidence,
    required this.recommendations,
  });
  /// Overall estimated score (0-100).
  final int overallScore;

  /// Estimated likes score component.
  final int likesScore;

  /// Estimated pub points score component.
  final int pubPointsScore;

  /// Estimated popularity score component.
  final int popularityScore;

  /// Confidence level of the estimate (0.0-1.0).
  final double confidence;

  /// Recommendations for improving the score.
  final List<String> recommendations;
}
