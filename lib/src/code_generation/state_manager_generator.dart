import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import '../annotations/generate_state.dart';

/// Builder factory for state manager generation.
Builder stateManagerGenerator(BuilderOptions options) =>
    SharedPartBuilder([StateManagerGenerator()], 'state');

/// Generator for state management code from @GenerateState annotations.
class StateManagerGenerator extends GeneratorForAnnotation<GenerateState> {
  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        'GenerateState can only be applied to classes.',
        element: element,
      );
    }

    final className = element.name;
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
    required ClassElement classElement,
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
  static ${className}Manager get instance => _instance ??= ${className}Manager._();

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
  ${className}Manager get manager => ${className}Manager.instance;
}
''';
  }

  List<FieldElement> _getReactiveFields(ClassElement classElement) =>
      classElement.fields
          .where(
            (field) => field.metadata
                .any((meta) => meta.element?.displayName == 'ReactiveProperty'),
          )
          .toList();

  List<MethodElement> _getStateMethods(ClassElement classElement) =>
      classElement.methods
          .where(
            (method) => method.metadata
                .any((meta) => meta.element?.displayName == 'StateAction'),
          )
          .toList();

  String _generateFieldGettersAndSetters(List<FieldElement> fields) {
    if (fields.isEmpty) return '';

    return fields.map((field) {
      final fieldName = field.name;
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

  String _generateStateMethods(List<MethodElement> methods, String className) {
    if (methods.isEmpty) return '';

    return methods.map((method) {
      final methodName = method.name;
      final parameters = method.parameters
          .map(
            (p) => '${p.type.getDisplayString()} ${p.name}',
          )
          .join(', ');
      final paramNames = method.parameters.map((p) => p.name).join(', ');

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

  List<StateTransition<$className>> get stateHistory => List.unmodifiable(_stateHistory);
''';
}

/// Represents a state transition for debugging purposes.
class StateTransition<T> {
  const StateTransition({
    required this.previousState,
    required this.newState,
    required this.timestamp,
    this.action,
  });

  final T previousState;
  final T newState;
  final DateTime timestamp;
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
  T get state;
  Stream<T> get stream;
  void update(T Function(T current) updater);
  void dispose();
}
