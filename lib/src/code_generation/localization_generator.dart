import 'dart:async';
import 'dart:convert';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

/// Builder factory for localization code generation.
Builder localizationGenerator(BuilderOptions options) =>
    SharedPartBuilder([LocalizationGenerator()], 'l10n');

/// Generator for localization code from translation files.
class LocalizationGenerator extends Generator {
  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    // Look for translation files
    final translationFiles = await _findTranslationFiles(buildStep);

    if (translationFiles.isEmpty) {
      return '// No translation files found';
    }

    try {
      final translations =
          await _parseTranslationFiles(translationFiles, buildStep);
      return _generateLocalizationCode(translations);
    } on Exception catch (e) {
      log.warning('Failed to generate localization code: $e');
      return '// Error generating localization code: $e';
    }
  }

  Future<List<String>> _findTranslationFiles(BuildStep buildStep) async {
    final files = <String>[];

    // Common translation file patterns
    final patterns = [
      'lib/l10n/app_en.arb',
      'lib/l10n/app_es.arb',
      'lib/l10n/app_fr.arb',
      'lib/l10n/app_de.arb',
      'assets/l10n/en.json',
      'assets/l10n/es.json',
      'assets/l10n/fr.json',
      'assets/translations/en.json',
      'assets/translations/es.json',
      'i18n/en.json',
      'i18n/es.json',
    ];

    for (final pattern in patterns) {
      final assetId = AssetId(buildStep.inputId.package, pattern);
      if (await buildStep.canRead(assetId)) {
        files.add(pattern);
      }
    }

    // Also scan for any .arb or .json files in common directories
    await _scanForTranslationFiles(buildStep, 'lib/l10n', files);
    await _scanForTranslationFiles(buildStep, 'assets/l10n', files);
    await _scanForTranslationFiles(buildStep, 'assets/translations', files);

    return files;
  }

  Future<void> _scanForTranslationFiles(
    BuildStep buildStep,
    String directory,
    List<String> files,
  ) async {
    // In a real implementation, this would scan the directory
    // For now, we'll rely on the predefined patterns
  }

  Future<TranslationData> _parseTranslationFiles(
    List<String> files,
    BuildStep buildStep,
  ) async {
    final translations = <String, Map<String, TranslationEntry>>{};
    String? defaultLocale;

    for (final file in files) {
      final locale = _extractLocaleFromFilename(file);
      if (locale == null) {
        continue;
      }

      final assetId = AssetId(buildStep.inputId.package, file);
      final content = await buildStep.readAsString(assetId);

      Map<String, dynamic> data;
      if (file.endsWith('.arb')) {
        data = jsonDecode(content) as Map<String, dynamic>;
      } else if (file.endsWith('.json')) {
        data = jsonDecode(content) as Map<String, dynamic>;
      } else {
        continue;
      }

      final localeTranslations = <String, TranslationEntry>{};

      for (final entry in data.entries) {
        final key = entry.key;
        final value = entry.value;

        // Skip metadata entries in ARB files
        if (key.startsWith('@')) {
          continue;
        }

        if (value is String) {
          localeTranslations[key] = TranslationEntry(
            key: key,
            value: value,
            description: _getDescription(data, key),
            placeholders: _extractPlaceholders(value),
          );
        }
      }

      translations[locale] = localeTranslations;

      // Set default locale (usually 'en' or the first one found)
      if (defaultLocale == null || locale == 'en') {
        defaultLocale = locale;
      }
    }

    return TranslationData(
      translations: translations,
      defaultLocale: defaultLocale ?? 'en',
    );
  }

  String? _extractLocaleFromFilename(String filename) {
    // Extract locale from patterns like:
    // - app_en.arb -> en
    // - en.json -> en
    // - app_es_ES.arb -> es_ES

    final basename = filename.split('/').last;

    // Pattern: app_locale.extension
    final appPattern = RegExp(r'app_([a-z]{2}(?:_[A-Z]{2})?)\.');
    final appMatch = appPattern.firstMatch(basename);
    if (appMatch != null) {
      return appMatch.group(1);
    }

    // Pattern: locale.extension
    final localePattern = RegExp(r'^([a-z]{2}(?:_[A-Z]{2})?)\.');
    final localeMatch = localePattern.firstMatch(basename);
    if (localeMatch != null) {
      return localeMatch.group(1);
    }

    return null;
  }

  String? _getDescription(Map<String, dynamic> data, String key) {
    final metaKey = '@$key';
    if (data.containsKey(metaKey)) {
      final meta = data[metaKey];
      if (meta is Map && meta.containsKey('description')) {
        return meta['description'] as String?;
      }
    }
    return null;
  }

  List<String> _extractPlaceholders(String value) {
    final placeholders = <String>[];
    final regex = RegExp(r'\{(\w+)\}');

    for (final match in regex.allMatches(value)) {
      final placeholder = match.group(1);
      if (placeholder != null && !placeholders.contains(placeholder)) {
        placeholders.add(placeholder);
      }
    }

    return placeholders;
  }

  String _generateLocalizationCode(TranslationData data) {
    final defaultTranslations = data.translations[data.defaultLocale] ?? {};

    return '''
// Generated localization code
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Localization delegate for the application.
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ${_generateSupportedLocales(data.translations.keys)};
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(
      AppLocalizations(locale),
    );
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

/// Main localization class providing access to translated strings.
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  /// Get the current localization instance from context.
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  /// Supported locales for this application.
  static const List<Locale> supportedLocales = [
    ${data.translations.keys.map(_generateLocaleConstant).join(',\n    ')}
  ];

  ${_generateTranslationMethods(defaultTranslations)}

  ${_generateLocaleSpecificMethods(data)}
}

${_generateTranslationExtensions(defaultTranslations)}

${_generateTranslationKeys(defaultTranslations)}
''';
  }

  String _generateSupportedLocales(Iterable<String> locales) {
    final checks = locales.map((locale) {
      if (locale.contains('_')) {
        final parts = locale.split('_');
        return "locale.languageCode == '${parts[0]}' && locale.countryCode == '${parts[1]}'";
      } else {
        return "locale.languageCode == '$locale'";
      }
    });

    return checks.join(' || ');
  }

  String _generateLocaleConstant(String locale) {
    if (locale.contains('_')) {
      final parts = locale.split('_');
      return "Locale('${parts[0]}', '${parts[1]}')";
    } else {
      return "Locale('$locale')";
    }
  }

  String _generateTranslationMethods(
    Map<String, TranslationEntry> translations,
  ) =>
      translations.values.map(_generateTranslationMethod).join('\n\n');

  String _generateTranslationMethod(TranslationEntry entry) {
    final methodName = _toValidMethodName(entry.key);
    final parameters = entry.placeholders.map((p) => 'String $p').join(', ');
    final parameterSubstitution = entry.placeholders.isEmpty
        ? 'translation'
        : entry.placeholders.fold(
            'translation',
            (result, placeholder) =>
                "$result.replaceAll('{$placeholder}', $placeholder)",
          );

    return '''
  /// ${entry.description ?? 'Translation for ${entry.key}'}
  String $methodName(${parameters.isNotEmpty ? parameters : ''}) {
    final translation = _getTranslation('${entry.key}');
    ${entry.placeholders.isEmpty ? 'return translation;' : 'return $parameterSubstitution;'}
  }''';
  }

  String _toValidMethodName(String key) {
    // Convert keys like 'hello_world' or 'hello.world' to 'helloWorld'
    return key
        .replaceAll(RegExp('[^a-zA-Z0-9]'), '_')
        .split('_')
        .asMap()
        .entries
        .map((entry) {
      final index = entry.key;
      final word = entry.value;
      if (index == 0) return word.toLowerCase();
      return word.isEmpty
          ? ''
          : word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join();
  }

  String _generateLocaleSpecificMethods(TranslationData data) => '''
  String _getTranslation(String key) {
    final translations = _getTranslationsForLocale(locale);
    return translations[key] ?? key;
  }

  Map<String, String> _getTranslationsForLocale(Locale locale) {
    final localeKey = locale.countryCode != null 
        ? '\${locale.languageCode}_\${locale.countryCode}'
        : locale.languageCode;
    
    return _allTranslations[localeKey] ?? _allTranslations['${data.defaultLocale}'] ?? {};
  }

  static const Map<String, Map<String, String>> _allTranslations = {
    ${data.translations.entries.map((entry) {
        final locale = entry.key;
        final translations = entry.value;
        final translationMap = translations.entries
            .map((t) => "'${t.key}': '${_escapeString(t.value.value)}'")
            .join(',\n      ');

        return "'$locale': {\n      $translationMap\n    }";
      }).join(',\n    ')}
  };''';

  String _generateTranslationExtensions(
    Map<String, TranslationEntry> translations,
  ) =>
      '''
/// Extension on BuildContext for convenient access to translations.
extension AppLocalizationsExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
  
  ${translations.values.map((entry) {
        final methodName = _toValidMethodName(entry.key);
        final parameters =
            entry.placeholders.map((p) => 'String $p').join(', ');

        return '''
  /// ${entry.description ?? 'Translation for ${entry.key}'}
  String get$methodName(${parameters.isNotEmpty ? parameters : ''}) => l10n.$methodName(${entry.placeholders.join(', ')});''';
      }).join('\n\n  ')}
}''';

  String _generateTranslationKeys(Map<String, TranslationEntry> translations) =>
      '''
/// Translation keys for type-safe access.
class TranslationKeys {
  TranslationKeys._();
  
  ${translations.keys.map((key) {
        final constantName =
            key.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '_');
        return "static const String $constantName = '$key';";
      }).join('\n  ')}
}''';

  String _escapeString(String input) => input
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\r')
      .replaceAll('\t', r'\t');
}

/// Represents translation data for all locales.
class TranslationData {
  const TranslationData({
    required this.translations,
    required this.defaultLocale,
  });

  /// Map of locale codes to their translation entries.
  final Map<String, Map<String, TranslationEntry>> translations;

  /// The default locale code.
  final String defaultLocale;
}

/// Represents a single translation entry.
class TranslationEntry {
  const TranslationEntry({
    required this.key,
    required this.value,
    this.description,
    this.placeholders = const [],
  });

  /// The translation key.
  final String key;

  /// The translated text value.
  final String value;

  /// Optional description of the translation.
  final String? description;

  /// List of placeholder names in the translation.
  final List<String> placeholders;

  @override
  String toString() => 'TranslationEntry(key: $key, value: $value)';
}

/// Utility class for managing translation files.
class TranslationFileManager {
  /// Validates that all translation files have the same keys.
  static List<String> validateTranslationConsistency(
    Map<String, Map<String, TranslationEntry>> translations,
  ) {
    final errors = <String>[];

    if (translations.isEmpty) return errors;

    final referenceKeys = translations.values.first.keys.toSet();

    for (final entry in translations.entries) {
      final locale = entry.key;
      final localeKeys = entry.value.keys.toSet();

      final missingKeys = referenceKeys.difference(localeKeys);
      final extraKeys = localeKeys.difference(referenceKeys);

      if (missingKeys.isNotEmpty) {
        errors.add('Locale $locale is missing keys: ${missingKeys.join(', ')}');
      }

      if (extraKeys.isNotEmpty) {
        errors.add('Locale $locale has extra keys: ${extraKeys.join(', ')}');
      }
    }

    return errors;
  }

  /// Extracts all translation keys from source code.
  static Set<String> extractKeysFromSource(String sourceCode) {
    final keys = <String>[];

    // Look for patterns like context.l10n.someMethod() or AppLocalizations.of(context).someMethod()
    final patterns = [
      RegExp(r'\.l10n\.(\w+)\('),
      RegExp(r'AppLocalizations\.of\([^)]+\)\.(\w+)\('),
      RegExp(r'TranslationKeys\.(\w+)'),
    ];

    for (final pattern in patterns) {
      for (final match in pattern.allMatches(sourceCode)) {
        final key = match.group(1);
        if (key != null) {
          keys.add(key);
        }
      }
    }

    return keys.toSet();
  }

  /// Generates a template translation file with all required keys.
  static String generateTranslationTemplate(
    Set<String> keys,
    String locale,
  ) {
    final entries =
        keys.map((key) => '"$key": "TODO: Translate $key"').join(',\n  ');

    return '''
{
  "@@locale": "$locale",
  $entries
}''';
  }
}
