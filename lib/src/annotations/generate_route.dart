/// Annotation for generating type-safe route definitions.
///
/// When applied to a method or class, this annotation triggers the generation
/// of corresponding route definitions with parameter validation and
/// deep link support.
class GenerateRoute {
  /// Creates a new GenerateRoute annotation.
  const GenerateRoute(
    this.path, {
    this.requiresAuth = false,
    this.methods = const ['GET'],
    this.enableDeepLinking = true,
    this.transition,
    this.guards = const [],
  });

  /// The route path pattern with parameter placeholders.
  ///
  /// Example: '/user/:id/profile'
  final String path;

  /// Whether this route requires authentication.
  final bool requiresAuth;

  /// HTTP methods this route should handle (for web).
  final List<String> methods;

  /// Whether to generate deep link handlers for this route.
  final bool enableDeepLinking;

  /// Custom transition animation for this route.
  final String? transition;

  /// Route guards that must pass before navigation.
  final List<String> guards;
}

/// Annotation for marking route parameters.
///
/// Used to specify parameter types and validation rules
/// for route parameters.
class RouteParam {
  /// Creates a new RouteParam annotation.
  const RouteParam({
    required this.name,
    this.required = true,
    this.defaultValue,
    this.pattern,
  });

  /// The parameter name in the route path.
  final String name;

  /// Whether this parameter is required.
  final bool required;

  /// Default value if the parameter is not provided.
  final dynamic defaultValue;

  /// Validation pattern for the parameter value.
  final String? pattern;
}

/// Annotation for marking route query parameters.
///
/// Used to specify query parameter handling for routes.
class QueryParam {
  /// Creates a new QueryParam annotation.
  const QueryParam({
    required this.name,
    this.required = false,
    this.defaultValue,
  });

  /// The query parameter name.
  final String name;

  /// Whether this parameter is required.
  final bool required;

  /// Default value if the parameter is not provided.
  final dynamic defaultValue;
}

/// Annotation for defining route guards.
///
/// Route guards are functions that determine whether
/// navigation to a route should be allowed.
class RouteGuardAnnotation {
  /// Creates a new RouteGuard annotation.
  const RouteGuardAnnotation({
    required this.guardFunction,
    this.parameters = const {},
  });

  /// The guard function name.
  final String guardFunction;

  /// Parameters to pass to the guard function.
  final Map<String, dynamic> parameters;
}
