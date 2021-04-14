import 'dart:async';

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:build/build.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';

import 'package:source_gen/source_gen.dart';
import 'package:template_annotation/template_annotation.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/src/output_helpers.dart';

extension _Bind<T> on Iterable<T> {
  Iterable<T1> bind<T1>(Iterable<T1> Function(T) fn) sync* {
    for (final t in this) {
      yield* fn(t);
    }
  }
}

String camelCase(String s) {
  if (s[0].toLowerCase() != s[0]) {
    return '${s[0].toLowerCase()}${s.substring(1)}';
  }
  return s;
}

class UnitedTypes {
  final Map<Element, Set<Element>> unionToUnited = {};
  final Map<Element, Element> unitedToUnion = {};

  void add(Element union, Set<Element> united) {
    for (final e in united) {
      if (unitedToUnion.containsKey(e)) {
        throw StateError('');
      }
      unitedToUnion[e] = union;
    }
    unionToUnited[union] = united;
  }
}

class ClassModifiers {
  final Set<String> typeParameters = {};
  final Set<String> implement = {};
  String extend;
  final Set<String> mix = {};
  ClassModifiers();

  static argsToString(List<DartType> arguments) {
    return argNamesToString(arguments.map((e) => e.element.name));
  }

  static argNamesToString(Iterable<String> names) {
    if (names.isEmpty) {
      return '';
    }
    return '<${names.map(demangled).join(', ')}>';
  }

  factory ClassModifiers.fromElement(ClassElement cls) {
    final m = ClassModifiers();
    final thisType = cls.thisType;
    for (final t in thisType.typeArguments) {
      m.typeParameters.add(demangled(t.element.name));
    }

    m.extend =
        '${demangled(thisType.superclass.element.name)}${argsToString(thisType.superclass.typeArguments)}';
    for (final mix in thisType.mixins) {
      final mixin =
          '${demangled(mix.element.name)}${argsToString(mix.typeArguments)}';
      m.mix.add(mixin);
    }
    for (final i in thisType.interfaces) {
      final interface =
          '${demangled(i.element.name)}${argsToString(i.typeArguments)}';
      m.implement.add(interface);
    }
    return m;
  }

  @override
  String toString() {
    final b = StringBuffer();
    if (typeParameters.isNotEmpty) {
      b.write('<${typeParameters.join(', ')}> ');
    } else {
      b.write(' ');
    }
    if (extend != null && extend != 'Object') {
      b.write('extends $extend ');
    }
    if (mix.isNotEmpty) {
      final mixins = mix.join(', ');
      b.write('with $mixins ');
    }
    if (implement.isNotEmpty) {
      final implementers = implement.join(', ');
      b.write('implements $implementers');
    }
    return b.toString();
  }
}

class TemplateGenerator extends Generator {
  final Set<TypeChecker> checkers = {
    templateChecker,
    unionChecker,
  };
  static final templateChecker = TypeChecker.fromRuntime(Template);
  static final unionChecker = TypeChecker.fromRuntime(Union);

  Map<Element, ConstantReader> _annotated(LibraryReader library) => checkers //
      .bind((e) => library.annotatedWithExact(e))
      .fold(
          {},
          (acc, e) => acc //
                  .containsKey(e.element)
              ? throw StateError('')
              : acc
            ..[e.element] = e.annotation);

  UnitedTypes _unionMap(Map<Element, ConstantReader> annotated) {
    final result = UnitedTypes();
    for (final e in annotated.entries) {
      if (!e.value.instanceOf(unionChecker)) {
        continue;
      }
      final union = e.value;
      final unitedTypes =
          union.read('members').setValue.map((e) => e.toTypeValue()).toList();
      final unitedCheckers = unitedTypes.map((e) => TypeChecker.fromStatic(e));
      final unitedElements = annotated.keys
          .whereType<ClassElement>()
          .where((e) => unitedCheckers.any((c) => c.isExactly(e)));
      result.add(e.key, unitedElements.toSet());
    }

    return result;
  }

  void _validateAnnotated(Map<Element, ConstantReader> annotated) {
    final notClasses =
        annotated.keys.where((element) => element is! ClassElement);
    final notNamedCorrectly = annotated.keys
        .whereType<ClassElement>()
        .where((element) => !element.name.startsWith(mangledPrefix));
    if (notClasses.isNotEmpty || notNamedCorrectly.isNotEmpty) {
      throw StateError('');
    }
  }

  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    final values = <String>{};
    final annotated = _annotated(library);
    if (annotated.isEmpty) {
      return null;
    }
    /*if (!p.basename(buildStep.inputId.path).endsWith('.template.dart')) {
      throw StateError(
          'The file containing the templates must end with .template.dart');
    }*/

    _validateAnnotated(annotated);
    final unitedTypes = _unionMap(annotated);

    await for (var value in normalizeGeneratorOutput(
        generateSerializersStatement(annotated.entries
            .where((e) => e.value.instanceOf(templateChecker))
            .map((e) => e.key)
            .toList()))) {
      assert(value.length == value.trim().length);
      values.add(value);
    }
    for (var e in annotated.entries) {
      var generatedValue;
      if (e.value.instanceOf(unionChecker)) {
        generatedValue = generateUnionElement(
          e.key,
          e.value,
          buildStep,
          unionWith: unitedTypes.unitedToUnion[e.key],
          unitedWith: unitedTypes.unionToUnited[e.key],
        );
      } else {
        generatedValue = generateTemplateElement(
          e.key,
          e.value,
          buildStep,
          unionWith: unitedTypes.unitedToUnion[e.key],
          unitedWith:
              unitedTypes.unionToUnited[unitedTypes.unitedToUnion[e.key]],
        );
      }
      await for (var value in normalizeGeneratorOutput(generatedValue)) {
        assert(value.length == value.trim().length);
        values.add(value);
      }
    }

    return values.join('\n\n');
  }

  String _visitSignature(Set<Element> unitedWith) {
    final required = '@required';
    final unitedNames =
        unitedWith.whereType<ClassElement>().map((e) => demangled(e.name));
    return '''
  T visit<T>({
        ${unitedNames.map((n) => '$required T Function($n) ${camelCase(n)},').join('\n')}
      })''';
  }

  FutureOr<String> generateSerializersStatement(List<Element> classes) {
    final names = classes.map((e) => demangled(e.name));
    return '''const List<Type> _\$serializableTypes = [
  ${names.join(',\n')},
];''';
  }

  Future<String> generateUnionElement(
    Element unionElement,
    ConstantReader unionAnnotation,
    BuildStep buildStep, {
    Element unionWith,
    Set<Element> unitedWith,
  }) async {
    final cls = unionElement as ClassElement;
    final name = demangled(cls.name);
    final builderName = '${name}Builder';
    final classModifiers = ClassModifiers.fromElement(cls);
    final isSubUnion = unionWith != null;
    if (isSubUnion) {
      classModifiers.implement.add(demangled(unionWith.name));
    }

    return '''
    @BuiltValue(instantiable: false)
    ${_bypassedAnnotationsFor(cls).join('\n')}
    ${cls.documentationComment ?? ''}
    abstract class $name$classModifiers {
      $_kBuiltToBuilderComment
      $builderName toBuilder();

      $_kBuiltRebuildComment
      $name rebuild(void Function($builderName) updates);

      /// Visit every member of the union [$name]. Prefer this over explicit
      /// `as` checks because it is exaustive, therefore safer.
      ${_visitSignature(unitedWith)};

      /// Serialize an [$name] to an json object.
      Map<String, dynamic> toJson();
    }
    ''';
  }

  String methodsFrom(Element element) {
    if (element == null) {
      return '';
    }
    final cls = element as ClassElement;
    final methods = cls.methods.whereType<MethodElementImpl>();
    if (methods.where((e) => e.isAbstract).isNotEmpty) {
      final abstractM = methods.where((e) => e.isAbstract).map((e) => e.name);
      throw StateError(
          'Abstract methods are not allowed on templates, but $abstractM '
          'were found on ${cls.name}.');
    }

    final code = cls.source.contents.data;
    final methodBodies = methods
        .where((e) => e.codeOffset != null && e.codeLength != null)
        .map((e) => code.substring(
              e.codeOffset,
              e.codeLength + e.codeOffset,
            ))
        .where((s) => s.isNotEmpty);

    return methodBodies.join('\n');
  }

  Iterable<String> _bypassedAnnotationsFor(Element e) => e.metadata
      .where((e) => !checkers.any(
            (c) => c.isExactlyType(e.computeConstantValue()?.type),
          ))
      .map((e) => e.toSource());

  // The concrete getter declarations from [element]
  String gettersFrom(Element element) {
    if (element == null) {
      return '';
    }
    final cls = element as ClassElement;
    if (cls.accessors.any((e) => e.isSetter)) {
      final setterNames =
          cls.accessors.where((e) => e.isSetter).map((e) => e.name);
      throw StateError(
          'Setters are not allowed, but $setterNames were found on ${cls.name}');
    }
    final getters = cls.accessors.whereType<PropertyAccessorElementImpl>();

    final result = StringBuffer();

    final abstractGetters = getters.where((e) => e.isAbstract);
    abstractGetters
        .map((e) => '${_bypassedAnnotationsFor(e).join('\n')}'
            '${e.documentationComment ?? ''}\n'
            '${demangled(e.type.returnType.element.name)} get ${e.name};')
        .forEach(result.writeln);

    final concreteGetters = getters.where((e) => !e.isAbstract);
    final code = cls.source.contents.data;
    final concreteGetterCode = concreteGetters
        .where((e) => e.codeOffset != null && e.codeLength != null)
        .map((e) => code.substring(
              e.codeOffset,
              e.codeLength + e.codeOffset,
            ))
        .where((s) => s.isNotEmpty);
    concreteGetterCode.forEach(result.writeln);

    return result.toString();
  }

  String fieldsFrom(Element element) {
    if (element == null) {
      return '';
    }
    final cls = element as ClassElement;
    final instanceFields = cls.fields.where((e) => !e.isStatic);
    if (instanceFields.any((e) => !e.isFinal)) {
      final varNames =
          instanceFields.where((e) => !e.isFinal).map((e) => e.name);
      throw StateError(
          'Non final fields are not allowed, but $varNames were found on ${cls.name}');
    }

    return instanceFields
        .map((f) => '${demangled(f.type.element.name)} get ${f.name};')
        .join('\n');
  }

  String _constructor(ClassElement cls) {
    if (cls.unnamedConstructor == null) {
      return '${demangled(cls.name)}._();';
    }
    final ctor = cls.unnamedConstructor as ConstructorElementImpl;
    final code = ctor.source.contents.data;

    // The constructor may be synthetic
    if (ctor.codeLength == null || ctor.codeOffset == null) {
      return '${demangled(cls.name)}._();';
    }
    final ctorString =
        code.substring(ctor.codeOffset, ctor.codeLength + ctor.codeOffset);
    return ctorString.replaceAll('${cls.name}()', '${demangled(cls.name)}._()');
  }

  Future<String> generateTemplateElement(
    Element templateElement,
    ConstantReader templateAnnotation,
    BuildStep buildStep, {
    Element unionWith,
    Set<Element> unitedWith,
  }) async {
    final cls = templateElement as ClassElement;
    final name = demangled(cls.name);
    final builderName = '${name}Builder';
    final classModifiers = ClassModifiers.fromElement(templateElement);
    final isUnion = unionWith != null && unitedWith != null;
    if (isUnion && (cls.supertype != null && !cls.supertype.isDartCoreObject)) {
      throw StateError('The supertype of an united template type must be'
          ' none or Object only!'
          'But instead it is ${cls.supertype.element.name}');
    }
    if (isUnion) {
      classModifiers.implement.add(demangled(unionWith.name));
    }
    final typeParameters =
        '${ClassModifiers.argNamesToString(classModifiers.typeParameters)}';
    final builderType = '$builderName$typeParameters';
    classModifiers.implement.add('Built<$name$typeParameters, $builderType>');

    final constructor = _constructor(cls);

    return '''
    ${_bypassedAnnotationsFor(cls).join('\n')}
    ${cls.documentationComment ?? ''}
    abstract class $name$classModifiers {
      $constructor

      /// Construct an [$name] from the updates applied to an
      /// [$builderName].
      factory $name([void Function($builderType) updates]) => _\$$name$typeParameters((b)=>b..update(updates));

      ${isUnion ? '@override ${_visitSignature(unitedWith)} => ${camelCase(name)}(this);' : ''}

      ${isUnion ? '@override' : '/// Serialize an [$name] to an json object.'}
      Map<String, dynamic> toJson() =>
        serializers.serialize(this) as Map<String, dynamic>;

      /// Deserialize an [$name] from an json object.
      static $name fromJson(Map<String, dynamic> json) =>
        serializers.deserializeWith($name.serializer, json);

      /// The [Serializer] that can serialize and deserialize an [$name].
      static Serializer<$name> get serializer => _\$${camelCase(name)}Serializer;
      ${gettersFrom(templateElement)}
      ${methodsFrom(templateElement)}
      ${methodsFrom(unionWith)}
    }
    ''';
  }
}

const mangledPrefix = '__';
String demangled(String name) {
  if (name.startsWith(mangledPrefix)) {
    return name.substring(mangledPrefix.length);
  }
  return name;
}

const _kBuiltRebuildComment = r'''
  /// Rebuilds the instance.
  ///
  /// The result is the same as this instance but with [updates] applied.
  /// [updates] is a function that takes a builder [B].
  ///
  /// The implementation of this method will be generated for you by the
  /// built_value generator.
''';
const _kBuiltToBuilderComment = r'''
  /// Rebuilds the instance.
  ///
  /// The result is the same as this instance but with [updates] applied.
  /// [updates] is a function that takes a builder [B].
  ///
  /// The implementation of this method will be generated for you by the
  /// built_value generator.
''';
