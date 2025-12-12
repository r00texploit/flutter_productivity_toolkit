/// Annotation for generating data model classes with serialization.
///
/// When applied to a class, this annotation triggers the generation
/// of serialization methods, equality operators, and copy methods.
class GenerateModel {
  /// Whether to generate JSON serialization methods.
  final bool generateSerialization;

  /// Whether to generate equality and hashCode methods.
  final bool generateEquality;

  /// Whether to generate copyWith method.
  final bool generateCopyWith;

  /// Whether to generate toString method.
  final bool generateToString;

  /// Custom serialization key transformation.
  final KeyTransform keyTransform;

  /// Whether to include null values in serialization.
  final bool includeNullValues;

  /// Creates a new GenerateModel annotation.
  const GenerateModel({
    this.generateSerialization = true,
    this.generateEquality = true,
    this.generateCopyWith = true,
    this.generateToString = true,
    this.keyTransform = KeyTransform.none,
    this.includeNullValues = false,
  });
}

/// Annotation for customizing field serialization.
///
/// Used to specify custom serialization behavior for individual fields.
class JsonField {
  /// The JSON key name for this field.
  final String? name;

  /// Whether to include this field in serialization.
  final bool include;

  /// Custom serialization function name.
  final String? serializer;

  /// Custom deserialization function name.
  final String? deserializer;

  /// Default value to use if the field is missing during deserialization.
  final dynamic defaultValue;

  /// Creates a new JsonField annotation.
  const JsonField({
    this.name,
    this.include = true,
    this.serializer,
    this.deserializer,
    this.defaultValue,
  });
}

/// Annotation for marking fields that should be ignored during serialization.
class JsonIgnore {
  /// Whether to ignore during serialization.
  final bool serialize;

  /// Whether to ignore during deserialization.
  final bool deserialize;

  /// Creates a new JsonIgnore annotation.
  const JsonIgnore({
    this.serialize = true,
    this.deserialize = true,
  });
}

/// Annotation for defining custom validation rules.
///
/// Used to generate validation methods for model fields.
class Validate {
  /// Validation rules to apply to this field.
  final List<ValidationRule> rules;

  /// Custom validation function name.
  final String? customValidator;

  /// Creates a new Validate annotation.
  const Validate({
    required this.rules,
    this.customValidator,
  });
}

/// Key transformation options for JSON serialization.
enum KeyTransform {
  /// No transformation (keep original field names).
  none,

  /// Transform to snake_case.
  snakeCase,

  /// Transform to camelCase.
  camelCase,

  /// Transform to PascalCase.
  pascalCase,

  /// Transform to kebab-case.
  kebabCase,
}

/// Validation rules that can be applied to model fields.
enum ValidationRule {
  /// Field is required (not null).
  required,

  /// String field has minimum length.
  minLength,

  /// String field has maximum length.
  maxLength,

  /// Numeric field has minimum value.
  min,

  /// Numeric field has maximum value.
  max,

  /// String field matches email pattern.
  email,

  /// String field matches URL pattern.
  url,

  /// String field matches custom pattern.
  pattern,

  /// List field has minimum number of items.
  minItems,

  /// List field has maximum number of items.
  maxItems,
}
