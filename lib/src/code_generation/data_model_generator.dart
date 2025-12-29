import 'package:analyzer/dart/element/element2.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import '../annotations/generate_model.dart';

/// Builder factory for data model generation.
Builder dataModelGenerator(BuilderOptions options) =>
    SharedPartBuilder([DataModelGenerator()], 'model');

/// Generator for data model code from @GenerateModel annotations.
class DataModelGenerator extends GeneratorForAnnotation<GenerateModel> {
  @override
  dynamic generateForAnnotatedElement(
    Element2 element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement2) {
      throw InvalidGenerationSourceError(
        'GenerateModel can only be applied to classes.',
        element: element,
      );
    }

    final className = element.displayName;
    final generateSerialization =
        annotation.read('generateSerialization').boolValue;
    final generateEquality = annotation.read('generateEquality').boolValue;
    final generateCopyWith = annotation.read('generateCopyWith').boolValue;
    final generateToString = annotation.read('generateToString').boolValue;
    final keyTransform = _parseKeyTransform(annotation.read('keyTransform'));
    final includeNullValues = annotation.read('includeNullValues').boolValue;

    return _generateDataModel(
      className: className,
      classElement: element,
      generateSerialization: generateSerialization,
      generateEquality: generateEquality,
      generateCopyWith: generateCopyWith,
      generateToString: generateToString,
      keyTransform: keyTransform,
      includeNullValues: includeNullValues,
    );
  }

  KeyTransform _parseKeyTransform(ConstantReader reader) {
    if (reader.isNull) {
      return KeyTransform.none;
    }

    final index = reader.read('index').intValue;
    return KeyTransform.values[index];
  }

  String _generateDataModel({
    required String className,
    required ClassElement2 classElement,
    required bool generateSerialization,
    required bool generateEquality,
    required bool generateCopyWith,
    required bool generateToString,
    required KeyTransform keyTransform,
    required bool includeNullValues,
  }) {
    final fields = _getSerializableFields(classElement);

    return '''
// Generated data model extensions for $className
extension ${className}Extensions on $className {
  ${generateSerialization ? _generateSerializationMethods(fields, keyTransform, includeNullValues) : ''}
  
  ${generateCopyWith ? _generateCopyWithMethod(fields, className) : ''}
  
  ${generateToString ? _generateToStringMethod(fields, className) : ''}
}

${generateEquality ? _generateEqualityMethods(fields, className) : ''}

${generateSerialization ? _generateFromJsonConstructor(fields, className, keyTransform) : ''}
''';
  }

  List<FieldElement2> _getSerializableFields(ClassElement2 classElement) =>
      classElement.fields2
          .where((field) => !field.isStatic && !field.isSynthetic)
          .where((field) => !_hasJsonIgnore(field))
          .toList();

  bool _hasJsonIgnore(FieldElement2 field) =>
      false; // For now, assume no JsonIgnore annotations

  String _getJsonKey(FieldElement2 field, KeyTransform keyTransform) =>
      _transformKey(field.displayName, keyTransform);

  String _transformKey(String key, KeyTransform transform) {
    switch (transform) {
      case KeyTransform.snakeCase:
        return _toSnakeCase(key);
      case KeyTransform.camelCase:
        return _toCamelCase(key);
      case KeyTransform.pascalCase:
        return _toPascalCase(key);
      case KeyTransform.kebabCase:
        return _toKebabCase(key);
      case KeyTransform.none:
        return key;
    }
  }

  String _toSnakeCase(String input) => input
      .replaceAllMapped(
        RegExp('[A-Z]'),
        (match) => '_${match.group(0)!.toLowerCase()}',
      )
      .replaceFirst(RegExp('^_'), '');

  String _toCamelCase(String input) {
    if (input.isEmpty) {
      return input;
    }
    return input[0].toLowerCase() + input.substring(1);
  }

  String _toPascalCase(String input) {
    if (input.isEmpty) {
      return input;
    }
    return input[0].toUpperCase() + input.substring(1);
  }

  String _toKebabCase(String input) => input
      .replaceAllMapped(
        RegExp('[A-Z]'),
        (match) => '-${match.group(0)!.toLowerCase()}',
      )
      .replaceFirst(RegExp('^-'), '');

  String _generateSerializationMethods(
    List<FieldElement2> fields,
    KeyTransform keyTransform,
    bool includeNullValues,
  ) =>
      '''
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    ${fields.map((field) {
        final jsonKey = _getJsonKey(field, keyTransform);
        final fieldName = field.displayName;

        if (includeNullValues) {
          return "json['$jsonKey'] = $fieldName;";
        } else {
          return '''
    if ($fieldName != null) {
      json['$jsonKey'] = $fieldName;
    }''';
        }
      }).join('\n    ')}
    return json;
  }
''';

  String _generateFromJsonConstructor(
    List<FieldElement2> fields,
    String className,
    KeyTransform keyTransform,
  ) =>
      '''
// Factory constructor for JSON deserialization
extension ${className}FromJson on $className {
  static $className fromJson(Map<String, dynamic> json) {
    return $className(
      ${fields.map((field) {
        final jsonKey = _getJsonKey(field, keyTransform);
        final fieldName = field.displayName;
        final fieldType = field.type.getDisplayString();

        return "$fieldName: json['$jsonKey'] as $fieldType,";
      }).join('\n      ')}
    );
  }
}
''';

  String _generateCopyWithMethod(
    List<FieldElement2> fields,
    String className,
  ) =>
      '''
  $className copyWith({
    ${fields.map((field) {
        final fieldType = field.type.getDisplayString();
        final fieldName = field.displayName;
        return '$fieldType? $fieldName,';
      }).join('\n    ')}
  }) {
    return $className(
      ${fields.map((field) {
        final fieldName = field.displayName;
        return '$fieldName: $fieldName ?? this.$fieldName,';
      }).join('\n      ')}
    );
  }
''';

  String _generateToStringMethod(List<FieldElement2> fields, String className) {
    final fieldStrings = fields.map((field) {
      final fieldName = field.displayName;
      return '$fieldName: \$fieldName';
    }).join(', ');

    return '''
  @override
  String toString() {
    return '$className($fieldStrings)';
  }
''';
  }

  String _generateEqualityMethods(
    List<FieldElement2> fields,
    String className,
  ) =>
      '''
// Equality and hashCode for $className
extension ${className}Equality on $className {
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! $className) return false;
    
    return ${fields.map((field) {
        final fieldName = field.displayName;
        return 'other.$fieldName == $fieldName';
      }).join(' &&\n           ')};
  }

  @override
  int get hashCode {
    return Object.hash(
      ${fields.map((field) => field.displayName).join(',\n      ')},
    );
  }
}
''';
}
