import 'dart:io';

import 'package:flutter_dev_toolkit/src/development_tools/pub_optimizer.dart';
import 'package:flutter_dev_toolkit/src/development_tools/pub_optimizer_impl.dart';
import 'package:flutter_dev_toolkit/src/development_tools/publication_utilities.dart';

/// Example demonstrating the pub.dev optimization tools.
///
/// This example shows how to use the Flutter Dev Toolkit's pub optimizer
/// to analyze and optimize a Flutter package for publication to pub.dev.
Future<void> main() async {
  print('🚀 Flutter Dev Toolkit - Pub Optimizer Example\n');

  // Initialize the pub optimizer
  const optimizer = PubOptimizerImpl();
  const publicationUtils = PublicationUtilities();

  // Use current directory as the package to analyze
  final packagePath = Directory.current.path;
  print('📦 Analyzing package at: $packagePath\n');

  try {
    // Step 1: Run complete publication workflow
    print('🔍 Running complete publication workflow...');
    final workflowResult = await publicationUtils.runCompleteWorkflow(
      packagePath,
    );

    print(
        '✅ Workflow completed in ${workflowResult.totalDuration.inMilliseconds}ms\n',);

    // Step 2: Display package analysis results
    if (workflowResult.packageAnalysis != null) {
      final analysis = workflowResult.packageAnalysis!;
      print('📊 Package Analysis Results:');
      print('   Quality Score: ${analysis.qualityScore}/100');
      print('   Issues Found: ${analysis.issues.length}');
      print('   Suggestions: ${analysis.suggestions.length}');
      print('   Meets Basic Requirements: ${analysis.meetsBasicRequirements}');
      print('');

      // Show critical issues
      final criticalIssues = analysis.issues
          .where((issue) => issue.severity == IssueSeverity.error)
          .toList();
      if (criticalIssues.isNotEmpty) {
        print('🚨 Critical Issues:');
        for (final issue in criticalIssues) {
          print('   • ${issue.description}');
          if (issue.suggestedFix != null) {
            print('     Fix: ${issue.suggestedFix}');
          }
        }
        print('');
      }

      // Show top suggestions
      if (analysis.suggestions.isNotEmpty) {
        print('💡 Top Suggestions:');
        final topSuggestions = analysis.suggestions.take(3);
        for (final suggestion in topSuggestions) {
          print('   • ${suggestion.description}');
          print('     Benefit: ${suggestion.expectedBenefit}');
          print('     Effort: ${suggestion.effort.name}');
        }
        print('');
      }
    }

    // Step 3: Display documentation analysis
    if (workflowResult.documentationAnalysis != null) {
      final docAnalysis = workflowResult.documentationAnalysis!;
      print('📚 Documentation Analysis:');
      print(
          '   Coverage: ${docAnalysis.coveragePercentage.toStringAsFixed(1)}%',);
      print('   Undocumented APIs: ${docAnalysis.undocumentedApis}');
      print('   Meets Standards: ${docAnalysis.meetsStandards}');
      print('');
    }

    // Step 4: Display example validation
    if (workflowResult.exampleValidation != null) {
      final exampleValidation = workflowResult.exampleValidation!;
      print('🎯 Example Validation:');
      print('   Working Examples: ${exampleValidation.workingExamples}');
      print('   Broken Examples: ${exampleValidation.brokenExamples}');
      print(
          '   All APIs Have Examples: ${exampleValidation.allApisHaveExamples}',);
      print('');
    }

    // Step 5: Display publication readiness
    if (workflowResult.preflightReport != null) {
      final report = workflowResult.preflightReport!;
      print('🚀 Publication Readiness:');
      print(
          '   Ready for Publication: ${report.readyForPublication ? "✅ Yes" : "❌ No"}',);
      print('   Readiness Score: ${report.readinessScore}/100');
      print('   Estimated pub.dev Score: ${report.estimatedPubScore}/100');
      print('');

      if (report.criticalIssues.isNotEmpty) {
        print('🔧 Issues to Fix Before Publication:');
        for (final issue in report.criticalIssues) {
          print('   • ${issue.issue}');
        }
        print('');
      }
    }

    // Step 6: Generate publication checklist
    print('📋 Generating publication checklist...');
    final checklist =
        await publicationUtils.generatePublicationChecklist(packagePath);

    print('📋 Publication Checklist:');
    print('   Total Items: ${checklist.totalItems}');
    print('   Passed: ${checklist.passedItems}');
    print('   Failed: ${checklist.failedItems}');
    print('   Manual Review: ${checklist.manualItems}');
    print(
        '   Completion: ${checklist.completionPercentage.toStringAsFixed(1)}%',);
    print('');

    // Show failed items
    final failedItems = checklist.items
        .where((item) => item.status == ChecklistStatus.failed)
        .toList();
    if (failedItems.isNotEmpty) {
      print('❌ Failed Checklist Items:');
      for (final item in failedItems) {
        print('   • ${item.description}');
      }
      print('');
    }

    // Step 7: Estimate pub.dev score
    print('🎯 Estimating pub.dev score...');
    final scoreEstimate = await publicationUtils.estimatePubScore(packagePath);

    print('🎯 Estimated pub.dev Score:');
    print('   Overall Score: ${scoreEstimate.overallScore}/100');
    print('   Likes Score: ${scoreEstimate.likesScore}/100');
    print('   Pub Points: ${scoreEstimate.pubPointsScore}/100');
    print('   Popularity: ${scoreEstimate.popularityScore}/100');
    print(
        '   Confidence: ${(scoreEstimate.confidence * 100).toStringAsFixed(1)}%',);
    print('');

    if (scoreEstimate.recommendations.isNotEmpty) {
      print('🎯 Score Improvement Recommendations:');
      for (final recommendation in scoreEstimate.recommendations) {
        print('   • $recommendation');
      }
      print('');
    }

    // Step 8: Show workflow steps
    print('⚙️ Workflow Steps:');
    for (final step in workflowResult.workflowSteps) {
      final statusIcon = switch (step.status) {
        WorkflowStepStatus.completed => '✅',
        WorkflowStepStatus.failed => '❌',
        WorkflowStepStatus.running => '🔄',
        WorkflowStepStatus.pending => '⏳',
      };
      final duration = step.duration?.inMilliseconds ?? 0;
      print('   $statusIcon ${step.name} (${duration}ms)');
      if (step.result != null) {
        print('      Result: ${step.result}');
      }
    }
    print('');

    // Step 9: Generate summary report
    print('📄 Generating publication summary...');
    final summary =
        await publicationUtils.generatePublicationSummary(packagePath);

    // Save summary to file
    final summaryFile = File('publication_summary.md');
    await summaryFile.writeAsString(summary);
    print('📄 Publication summary saved to: ${summaryFile.path}');
    print('');

    // Final recommendations
    print('🎉 Analysis Complete!');
    print('');
    if (workflowResult.success) {
      print('✅ Your package is ready for publication!');
      print('   You can now run: dart pub publish');
    } else {
      print('⚠️  Your package needs some improvements before publication.');
      print(
          '   Please address the issues listed above and run the analysis again.',);
    }
  } catch (e) {
    print('❌ Error during analysis: $e');
    exit(1);
  }
}
