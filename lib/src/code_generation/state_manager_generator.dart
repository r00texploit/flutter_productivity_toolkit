import 'package:analyzer/dart/element/element2.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import '../annotations/generate_state.dart';

/// Builder factory for state manager generation.
Builder stateManagerGenerator(BuilderOptions options) =>
    SharedPartBuilder([StateManagerGenerator()], 'state');

/// Generator for state management code from @GenerateState annotations.
class StateManagerGenerator extends GeneratorForAnnotation<GenerateState> {
  @override
  dynamic generateForAnnotatedElement(
    Element2 element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement2) {
      throw InvalidGenerationSourceError(
        'GenerateState can only be applied to classes.',
        element: element,
      );
    }

    final className = element.name3!;
    final persist = annotation.read('persist').boolValue;
    final storageKey = annotation.read('storageKey').isNull
        ? null
        : annotation.read('storageKey').stringValue;
    final enableDebugging = annotation.read('enableDebugging').boolValue;
    final autoDispose = annotation.read('autoDispose').boolValue;

    return _generateStateManager(
      className: className,
      classElement: element,
      persist: persist,
      storageKey: storageKey ?? className.toLowerCase(),
      enableDebugging: enableDebugging,
      autoDispose: autoDispose,
    );
  }

  String _generateStateManager({
    required String className,
    required ClassElement2 classElement,
    required bool persist,
    required String storageKey,
    required bool enableDebugging,
    required bool autoDispose,
  }) {
    final fields = _getReactiveFields(classElement);
    final methods = _getStateMethods(classElement);

    return '''
// Generated state manager for $className
class ${className}Manager extends StateManager<$className> {
  ${className}Manager._() {
    ${persist ? '_loadPersistedState();' : ''}
    ${enableDebugging ? '_initializeDebugging();' : ''}
  }

  static ${className}Manager? _instance;
  static ${className}Manager get instance {
    return _instance ??= ${className}Manager._();
  }

  $className _state = $className();
  final StreamController<$className> _controller = StreamController<$className>.broadcast();

  @override
  $className get state => _state;

  @override
  Stream<$className> get stream => _controller.stream;

  ${_generateFieldGettersAndSetters(fields)}

  ${_generateStateMethods(methods, className)}

  @override
  void update($className Function($className current) updater) {
    final newState = updater(_state);
    if (newState != _state) {
      ${enableDebugging ? '_logStateTransition(_state, newState);' : ''}
      _state = newState;
      _controller.add(_state);
      ${persist ? '_persistState();' : ''}
    }
  }

  ${persist ? _generatePersistenceMethods(storageKey) : ''}

  ${enableDebugging ? _generateDebuggingMethods(className) : ''}

  @override
  void dispose() {
    ${autoDispose ? '''
    _controller.close();
    _instance = null;
    ''' : ''}
  }
}

// Extension methods for convenient state access
extension ${className}StateExtension on $className {
  ${className}Manager get manager {
    return ${className}Manager.instance;
  }
}
''';
  }

  List<FieldElement2> _getReactiveFields(ClassElement2 classElement) {
    // For Element2 API, we'll simplify and return empty list for now
    // In a real implementation, this would need proper metadata handling
    return <FieldElement2>[];
  }

  List<MethodElement2> _getStateMethods(ClassElement2 classElement) {
    // For Element2 API, we'll simplify and return empty list for now
    // In a real implementation, this would need proper metadata handling
    return <MethodElement2>[];
  }

  String _generateFieldGettersAndSetters(List<FieldElement2> fields) {
    if (fields.isEmpty) return '';

    return fields.map((field) {
      final fieldName = field.name3!;
      final fieldType = field.type.getDisplayString();

      return '''
  $fieldType get $fieldName => _state.$fieldName;
  
  set $fieldName($fieldType value) {
    if (_state.$fieldName != value) {
      update((state) => state.copyWith($fieldName: value));
    }
  }
''';
    }).join('\n');
  }

  String _generateStateMethods(List<MethodElement2> methods, String className) {
    if (methods.isEmpty) return '';

    return methods.map((method) {
      final methodName = method.name3!;
      // Note: Element2 API for parameters might be different
      // For now, we'll use a simplified approach
      final parameters = ''; // Simplified for Element2 compatibility
      final paramNames = ''; // Simplified for Element2 compatibility

      return '''
  void $methodName($parameters) {
    final result = _state.$methodName($paramNames);
    if (result != _state) {
      update((_) => result);
    }
  }
''';
    }).join('\n');
  }

  String _generatePersistenceMethods(String storageKey) => '''
  void _loadPersistedState() async {
    try {
      // In a real implementation, this would use SharedPreferences or similar
      // For now, this is a placeholder
      print('Loading persisted state for key: $storageKey');
    } catch (e) {
      print('Failed to load persisted state: \$e');
    }
  }

  void _persistState() async {
    try {
      // In a real implementation, this would serialize and save the state
      print('Persisting state for key: $storageKey');
    } catch (e) {
      print('Failed to persist state: \$e');
    }
  }
''';

  String _generateDebuggingMethods(String className) => '''
  final List<StateTransition<$className>> _stateHistory = [];

  void _initializeDebugging() {
    print('State debugging enabled for ${className}Manager');
  }

  void _logStateTransition($className oldState, $className newState) {
    final transition = StateTransition<$className>(
      previousState: oldState,
      newState: newState,
      timestamp: DateTime.now(),
      action: 'update',
    );
    _stateHistory.add(transition);
    print('State transition: \${transition.toString()}');
  }

  List<StateTransition<$className>> get stateHistory {
    return List.unmodifiable(_stateHistory);
  }
''';
}

/// Represents a state transition for debugging purposes.
class StateTransition<T> {
  /// Creates a new state transition.
  const StateTransition({
    required this.previousState,
    required this.newState,
    required this.timestamp,
    this.action,
  });

  /// The previous state before the transition.
  final T previousState;

  /// The new state after the transition.
  final T newState;

  /// The timestamp when the transition occurred.
  final DateTime timestamp;

  /// The action that triggered the transition.
  final String? action;

  @override
  String toString() => 'StateTransition('
      'action: $action, '
      'timestamp: $timestamp, '
      'previous: $previousState, '
      'new: $newState'
      ')';
}

/// Abstract base class for state managers.
abstract class StateManager<T> {
  /// The current state.
  T get state;

  /// Stream of state changes.
  Stream<T> get stream;

  /// Updates the state using the provided updater function.
  void update(T Function(T current) updater);

  /// Disposes of the state manager and cleans up resources.
  void dispose();
}
