import 'package:analyzer/dart/element/element2.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import '../annotations/generate_route.dart';

/// Builder factory for route generation.
Builder routeGenerator(BuilderOptions options) =>
    SharedPartBuilder([RouteGenerator()], 'routes');

/// Generator for route definitions from @GenerateRoute annotations.
class RouteGenerator extends GeneratorForAnnotation<GenerateRoute> {
  final List<RouteDefinition> _routes = [];

  @override
  dynamic generateForAnnotatedElement(
    Element2 element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! MethodElement2 && element is! ClassElement2) {
      throw InvalidGenerationSourceError(
        'GenerateRoute can only be applied to methods or classes.',
        element: element,
      );
    }

    final path = annotation.read('path').stringValue;
    final requiresAuth = annotation.read('requiresAuth').boolValue;
    final methods = annotation
        .read('methods')
        .listValue
        .map((e) => e.toStringValue()!)
        .toList();
    final enableDeepLinking = annotation.read('enableDeepLinking').boolValue;
    final transition = annotation.read('transition').isNull
        ? null
        : annotation.read('transition').stringValue;

    final routeDef = RouteDefinition(
      path: path,
      element: element,
      requiresAuth: requiresAuth,
      methods: methods,
      enableDeepLinking: enableDeepLinking,
      transition: transition,
    );

    _routes.add(routeDef);

    return _generateRouteDefinition(routeDef);
  }

  String _generateRouteDefinition(RouteDefinition route) {
    final routeName = _getRouteName(route.path);
    final parameterType = _getParameterType(route);
    final returnType = _getReturnType(route);

    return '''
// Generated route definition for ${route.path}
class ${routeName}Route {
  static const String path = '${route.path}';
  static const bool requiresAuth = ${route.requiresAuth};
  static const List<String> methods = ${route.methods};
  static const bool enableDeepLinking = ${route.enableDeepLinking};
  ${route.transition != null ? "static const String transition = '${route.transition}';" : ''}

  ${_generateNavigationMethod(route, parameterType, returnType)}

  ${_generateParameterValidation(route)}

  ${route.enableDeepLinking ? _generateDeepLinkHandler(route) : ''}
}

${_generateRouteExtension(route, routeName, parameterType, returnType)}
''';
  }

  String _getRouteName(String path) =>
      // Convert path like '/user/:id/profile' to 'UserProfile'
      path
          .split('/')
          .where((segment) => segment.isNotEmpty && !segment.startsWith(':'))
          .map((segment) => segment[0].toUpperCase() + segment.substring(1))
          .join();

  String _getParameterType(RouteDefinition route) {
    final params = _extractParameters(route.path);
    if (params.isEmpty) return 'void';

    if (params.length == 1) {
      return _getParameterDartType(params.first);
    }

    // Generate a parameter class for multiple parameters
    final className = '${_getRouteName(route.path)}Params';
    return className;
  }

  String _getReturnType(RouteDefinition route) =>
      // For now, assume all routes return dynamic
      // In a real implementation, this would be inferred from the method signature
      'dynamic';

  List<String> _extractParameters(String path) => RegExp(r':(\w+)')
      .allMatches(path)
      .map((match) => match.group(1)!)
      .toList();

  String _getParameterDartType(String paramName) =>
      // Simple heuristic for parameter types
      paramName.toLowerCase().contains('id') ? 'int' : 'String';

  String _generateNavigationMethod(
    RouteDefinition route,
    String paramType,
    String returnType,
  ) {
    final params = _extractParameters(route.path);

    if (params.isEmpty) {
      return '''
  static Future<$returnType?> navigate() async {
    return await RouteBuilder.instance.navigate<void, $returnType>(path);
  }
''';
    }

    if (params.length == 1) {
      return '''
  static Future<$returnType?> navigate($paramType ${params.first}) async {
    final pathWithParams = path.replaceAll(':${params.first}', \${params.first}.toString());
    return await RouteBuilder.instance.navigate<$paramType, $returnType>(pathWithParams, params: ${params.first});
  }
''';
    }

    // Multiple parameters
    final paramClass = _getParameterType(route);
    return '''
  static Future<$returnType?> navigate($paramClass params) async {
    var pathWithParams = path;
    ${params.map((p) => "pathWithParams = pathWithParams.replaceAll(':$p', params.$p.toString());").join('\n    ')}
    return await RouteBuilder.instance.navigate<$paramClass, $returnType>(pathWithParams, params: params);
  }
''';
  }

  String _generateParameterValidation(RouteDefinition route) {
    final params = _extractParameters(route.path);
    if (params.isEmpty) return '';

    return '''
  static bool validateParameters(Map<String, dynamic> params) {
    ${params.map(
              (p) => '''
    if (!params.containsKey('$p')) return false;
    if (params['$p'] == null) return false;
    ''',
            ).join('\n    ')}
    return true;
  }
''';
  }

  String _generateDeepLinkHandler(RouteDefinition route) => '''
  static Map<String, dynamic>? parseDeepLink(String url) {
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;
    final routeSegments = path.split('/').where((s) => s.isNotEmpty).toList();
    
    if (pathSegments.length != routeSegments.length) return null;
    
    final params = <String, dynamic>{};
    for (int i = 0; i < routeSegments.length; i++) {
      final routeSegment = routeSegments[i];
      if (routeSegment.startsWith(':')) {
        final paramName = routeSegment.substring(1);
        params[paramName] = pathSegments[i];
      } else if (routeSegment != pathSegments[i]) {
        return null; // Path doesn't match
      }
    }
    
    // Add query parameters
    params.addAll(uri.queryParameters);
    
    return params;
  }
''';

  String _generateRouteExtension(
    RouteDefinition route,
    String routeName,
    String paramType,
    String returnType,
  ) =>
      '''
// Extension for convenient route access
extension ${routeName}Navigation on RouteBuilder {
  Future<$returnType?> navigateTo$routeName(${paramType != 'void' ? '$paramType params' : ''}) {
    return ${routeName}Route.navigate(${paramType != 'void' ? 'params' : ''});
  }
}
''';
}

/// Represents a route definition extracted from annotations.
class RouteDefinition {
  /// Creates a new route definition.
  const RouteDefinition({
    required this.path,
    required this.element,
    required this.requiresAuth,
    required this.methods,
    required this.enableDeepLinking,
    this.transition,
  });

  /// The route path pattern.
  final String path;

  /// The element this route is associated with.
  final Element2 element;

  /// Whether this route requires authentication.
  final bool requiresAuth;

  /// HTTP methods supported by this route.
  final List<String> methods;

  /// Whether deep linking is enabled for this route.
  final bool enableDeepLinking;

  /// Optional transition animation type.
  final String? transition;
}

/// Mock RouteBuilder for generated code compilation.
abstract class RouteBuilder {
  /// Gets the singleton instance of the route builder.
  static RouteBuilder get instance => throw UnimplementedError();

  /// Navigates to a route with optional parameters.
  Future<R?> navigate<T, R>(String path, {T? params});

  /// Registers a deep link handler for a pattern.
  void registerDeepLinkHandler(String pattern, RouteHandler handler);
}

/// Type definition for route handlers.
typedef RouteHandler = void Function(Map<String, dynamic> params);
