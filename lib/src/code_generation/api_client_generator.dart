import 'dart:async';
import 'dart:convert';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

/// Builder factory for API client generation.
Builder apiClientGenerator(BuilderOptions options) =>
    SharedPartBuilder([ApiClientGenerator()], 'api');

/// Generator for API client code from OpenAPI specifications.
class ApiClientGenerator extends Generator {
  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    // Look for OpenAPI specification files
    final openApiFiles = await _findOpenApiFiles(buildStep);

    if (openApiFiles.isEmpty) {
      return '// No OpenAPI specifications found';
    }

    final generatedClients = <String>[];

    for (final specFile in openApiFiles) {
      try {
        final spec = await _parseOpenApiSpec(specFile, buildStep);
        final client = _generateApiClient(spec);
        generatedClients.add(client);
      } catch (e) {
        log.warning('Failed to generate API client from $specFile: $e');
      }
    }

    return generatedClients.join('\n\n');
  }

  Future<List<String>> _findOpenApiFiles(BuildStep buildStep) async {
    final files = <String>[];

    // Common OpenAPI file patterns
    final patterns = [
      'api/openapi.json',
      'api/swagger.json',
      'openapi.json',
      'swagger.json',
    ];

    for (final pattern in patterns) {
      final assetId = AssetId(buildStep.inputId.package, pattern);
      if (await buildStep.canRead(assetId)) {
        files.add(pattern);
      }
    }

    return files;
  }

  Future<SimpleApiSpec> _parseOpenApiSpec(
      String filePath, BuildStep buildStep,) async {
    final assetId = AssetId(buildStep.inputId.package, filePath);
    final content = await buildStep.readAsString(assetId);

    final json = jsonDecode(content) as Map<String, dynamic>;
    return SimpleApiSpec.fromJson(json);
  }

  String _generateApiClient(SimpleApiSpec spec) {
    final className = _getClientClassName(spec.title);

    return '''
// Generated API client for ${spec.title}
class $className {
  $className({
    required this.baseUrl,
    this.defaultHeaders = const {},
  });

  final String baseUrl;
  final Map<String, String> defaultHeaders;

  ${_generateEndpointMethods(spec.endpoints)}

  ${_generateRequestMethod()}
}

${_generateExceptionClasses()}
''';
  }

  String _getClientClassName(String title) => '${title
            .replaceAll(RegExp('[^a-zA-Z0-9]'), ' ')
            .split(' ')
            .where((word) => word.isNotEmpty)
            .map((word) =>
                word[0].toUpperCase() + word.substring(1).toLowerCase(),)
            .join()}Client';

  String _generateEndpointMethods(List<ApiEndpoint> endpoints) => endpoints.map((endpoint) {
      final methodName = _getMethodName(endpoint.method, endpoint.path);
      final returnType = endpoint.responseType ?? 'Map<String, dynamic>';

      return '''
  /// ${endpoint.description ?? 'Generated method for ${endpoint.method} ${endpoint.path}'}
  Future<$returnType> $methodName() async {
    final url = '\$baseUrl${endpoint.path}';
    
    final response = await _request(
      method: '${endpoint.method}',
      url: url,
      headers: defaultHeaders,
    );

    return jsonDecode(response.body) as $returnType;
  }''';
    }).join('\n\n');

  String _getMethodName(String httpMethod, String path) {
    // Generate method name from HTTP method and path
    final pathParts = path
        .split('/')
        .where((part) => part.isNotEmpty && !part.startsWith('{'))
        .map(_toPascalCase)
        .join();

    return _toCamelCase(httpMethod.toLowerCase() + pathParts);
  }

  String _generateRequestMethod() => '''
  Future<HttpResponse> _request({
    required String method,
    required String url,
    Map<String, String>? headers,
  }) async {
    // In a real implementation, this would use http package or similar
    // For now, this is a placeholder
    throw UnimplementedError('HTTP client not implemented');
  }''';

  String _generateExceptionClasses() => r'''
class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.message,
  });

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class HttpResponse {
  const HttpResponse({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final String body;
}''';

  String _toCamelCase(String input) {
    if (input.isEmpty) return input;
    return input[0].toLowerCase() + input.substring(1);
  }

  String _toPascalCase(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }
}

// Simplified OpenAPI specification classes
class SimpleApiSpec {
  const SimpleApiSpec({
    required this.title,
    required this.endpoints,
  });

  factory SimpleApiSpec.fromJson(Map<String, dynamic> json) {
    final info = json['info'] as Map<String, dynamic>? ?? {};
    final title = info['title'] as String? ?? 'API';

    final paths = json['paths'] as Map<String, dynamic>? ?? {};
    final endpoints = <ApiEndpoint>[];

    for (final pathEntry in paths.entries) {
      final path = pathEntry.key;
      final pathData = pathEntry.value as Map<String, dynamic>;

      for (final methodEntry in pathData.entries) {
        final method = methodEntry.key.toUpperCase();
        final methodData = methodEntry.value as Map<String, dynamic>;

        endpoints.add(ApiEndpoint(
          method: method,
          path: path,
          description: methodData['summary'] as String?,
          responseType: 'Map<String, dynamic>',
        ),);
      }
    }

    return SimpleApiSpec(
      title: title,
      endpoints: endpoints,
    );
  }

  final String title;
  final List<ApiEndpoint> endpoints;
}

class ApiEndpoint {
  const ApiEndpoint({
    required this.method,
    required this.path,
    this.description,
    this.responseType,
  });

  final String method;
  final String path;
  final String? description;
  final String? responseType;
}
