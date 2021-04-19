import 'dart:async';
import 'dart:math';

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:build/build.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:hive/hive.dart' show HiveType;
import 'package:source_gen/source_gen.dart';
import 'package:template_annotation/template_annotation.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/src/output_helpers.dart';
import 'package:tuple/tuple.dart';

extension _IterableE<T> on Iterable<T> {
  Iterable<T1> bind<T1>(Iterable<T1> Function(T) fn) sync* {
    for (final t in this) {
      yield* fn(t);
    }
  }

  Iterable<Tuple2<T, T1>> zip<T1>(Iterable<T1> other) sync* {
    final ia = iterator, ib = other.iterator;
    while (ia.moveNext() && ib.moveNext()) {
      yield Tuple2(ia.current, ib.current);
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
        '${demangled(thisType.superclass.element.name)}${_typeParamsFor(thisType.superclass)}';
    for (final mix in thisType.mixins) {
      final mixin = '${demangled(mix.element.name)}${_typeParamsFor(mix)}';
      m.mix.add(mixin);
    }
    for (final i in thisType.interfaces) {
      final interface = '${demangled(i.element.name)}${_typeParamsFor(i)}';
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

String _typeParamsFor(DartType t) {
  if (t is! ParameterizedType) {
    return '';
  }
  final type = t as ParameterizedType;
  if (type.typeArguments.isEmpty) {
    return '';
  }
  final params = type.typeArguments
      .map((e) => '${demangled(e.element.name)}${_typeParamsFor(e)}')
      .join(', ');
  return '<$params>';
}

class TemplateGenerator extends Generator {
  final Set<TypeChecker> checkers = {
    templateChecker,
    unionChecker,
  };
  static final templateChecker = TypeChecker.fromRuntime(Template);
  static final unionChecker = TypeChecker.fromRuntime(Union);
  static final hiveTypeChecker = TypeChecker.fromRuntime(HiveType);
  static final constructorChecker = TypeChecker.fromRuntime(Constructor);

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
    final withHiveType = annotated.keys.where(hiveTypeChecker.hasAnnotationOf);
    if (notClasses.isEmpty &&
        notNamedCorrectly.isEmpty &&
        withHiveType.isEmpty) {
      return;
    }
    final result = StringBuffer();
    if (notClasses.isNotEmpty) {
      result.writeAll(
          notClasses
              .map((e) => e.name) //
              .map((e) =>
                  '$e is annotated with Template or Union but it is not an class.'),
          '\n');
    }
    if (notNamedCorrectly.isNotEmpty) {
      result.writeAll(
          notNamedCorrectly
              .map((e) => e.name) //
              .map((e) =>
                  'classes annotated with Template or Union must start with $mangledPrefix, but $e is not.'),
          '\n');
    }
    if (withHiveType.isNotEmpty) {
      result.writeAll(
          withHiveType
              .map((e) => e.name) //
              .map((e) =>
                  '$e is annotated with HiveType, but this is forbidden! Use Template(hiveType: number)'),
          '\n');
    }

    throw StateError(result.toString());
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
    await for (var value in normalizeGeneratorOutput(generateHiveTypeStatement(
        annotated.entries
            .where((e) => e.value.instanceOf(templateChecker))
            .where((el) => el.value.read("hiveType") != null)
            .where((el) => !el.value.read("hiveType").isNull)
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

  String _unionMemberClassFactory(Element union, Element unionMember) {
    final memberName = demangled(unionMember.name);
    final abbrMember = _unionMemberAbbreviatedName(union, unionMember);
    final typeParams = _typeParamsFor((unionMember as ClassElement).thisType);

    final defaultCtor =
        _defaultConstructorSignatureAndApplicationFor(unionMember);
    return '''
    ${_defaultConstructorDocumentationFor(unionMember)}
    static $memberName$typeParams $abbrMember$typeParams(${defaultCtor.item1})
        => $memberName$typeParams(${defaultCtor.item2});
    ''';
  }

  String _unionMemberAbbreviatedName(Element union, Element unionMember) {
    final unionName = demangled(union.name);
    var name = demangled(unionMember.name);
    name = name.replaceFirst(unionName, '');
    name = camelCase(name);
    return name;
  }

  String _visitSignature(Element union, Set<Element> unitedWith) {
    final required = '@required';
    final unitedClassNames =
        unitedWith.whereType<ClassElement>().map((e) => demangled(e.name));
    final unitedPosArgNames = unitedWith
        .whereType<ClassElement>()
        .map((klass) => _unionMemberAbbreviatedName(union, klass));
    final united = unitedClassNames.zip(unitedPosArgNames);
    return '''
  T visit<T>({
        ${united.map((tp) => '$required T Function(${tp.item1}) ${tp.item2},').join('\n')}
      })''';
  }

  FutureOr<String> generateSerializersStatement(List<Element> classes) {
    final names = classes.map((e) => demangled(e.name));
    return '''const List<Type> _\$serializableTypes = [
  ${names.join(',\n')},
];''';
  }

  FutureOr<String> generateHiveTypeStatement(List<Element> hiveTypeClasses) {
    if (hiveTypeClasses == null || hiveTypeClasses.isEmpty) {
      return null;
    }
    final statements = hiveTypeClasses
        .map((e) => demangled(e.name))
        .map((clsName) => 'registerAdapter<$clsName>(${clsName}Adapter())');
    final nullSuffix = '/*?*/';
    return '''void _\$registerHiveTypes([HiveInterface$nullSuffix hive]) {
      hive ??= Hive;
      hive..
      ${statements.join('\n..')};
    }''';
  }

  String _hiveTypeAnnotation(ConstantReader templateAnnotation) {
    final hiveType = templateAnnotation.read('hiveType');
    if (hiveType == null || hiveType.isNull || hiveType.intValue == null) {
      return '';
    }
    final id = hiveType.intValue;
    return '@HiveType(typeId: $id)';
  }

  Future<String> generateUnionElement(
    Element unionElement,
    ConstantReader unionAnnotation,
    BuildStep buildStep, {
    Set<Element> unitedWith,
  }) async {
    final cls = unionElement as ClassElement;
    final name = demangled(cls.name);
    final builderName = '${name}Builder';
    final classModifiers = ClassModifiers.fromElement(cls);
    final memberFactories =
        unitedWith.map((member) => _unionMemberClassFactory(cls, member));
    final typeParams = _typeParamsFor(cls.thisType);

    return '''
    @BuiltValue(instantiable: false)
    ${_bypassedAnnotationsFor(cls).join('\n')}
    ${cls.documentationComment ?? ''}
    abstract class $name$classModifiers {
      ${memberFactories.join('\n')}

      $_kBuiltToBuilderComment
      $builderName$typeParams toBuilder();

      $_kBuiltRebuildComment
      $name$typeParams rebuild(void Function($builderName$typeParams) updates);

      /// Visit every member of the union [$name]. Prefer this over explicit
      /// `as` checks because it is exaustive, therefore safer.
      ${_visitSignature(unionElement, unitedWith)};

      /// Serialize an [$name] to an json object.
      Map<String, dynamic> toJson();

      ${accessorsFrom(cls)}
      ${staticFieldsFrom(cls)}
      ${methodsFrom(cls, true, true)}
    }
    ''';
  }

  String methodsFrom(Element element, bool isUnionClass, bool staticAlso) {
    if (element == null) {
      return '';
    }
    final cls = element as ClassElement;
    var methods = cls.methods.whereType<MethodElementImpl>();
    if (!staticAlso) {
      methods = methods.where((m) => !m.isStatic);
    }
    if (!isUnionClass && methods.where((e) => e.isAbstract).isNotEmpty) {
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

  Iterable<String> _bypassedAnnotationsFor(Element e) {
    final disallowedAnnotations = checkers.followedBy([
      hiveTypeChecker,
    ]);
    return e.metadata
        .where((e) => !disallowedAnnotations.any(
              (c) => c.isExactlyType(e.computeConstantValue()?.type),
            ))
        .map((e) => e.toSource());
  }

  // The concrete getter declarations from [element]
  String accessorsFrom(Element element) {
    if (element == null) {
      return '';
    }
    final cls = element as ClassElement;
    if (cls.accessors.any((e) => e.isSetter && !e.isStatic)) {
      final setterNames = cls.accessors
          .where((e) => e.isSetter && !e.isStatic)
          .map((e) => e.name);
      throw StateError(
          'Non static setters are not allowed, but $setterNames were found on ${cls.name}');
    }
    final getters = cls.accessors.whereType<PropertyAccessorElementImpl>();

    final result = StringBuffer();

    final abstractGetters = getters.where((e) => e.isAbstract);
    abstractGetters
        .map((e) => '${_bypassedAnnotationsFor(e).join('\n')}'
            '${e.documentationComment ?? ''}\n'
            '${demangled(e.type.returnType.element.name)}${_typeParamsFor(e.type.returnType)} get ${e.name};')
        .forEach(result.writeln);

    final code = cls.source.contents.data;

    final concreteGettersAndStaticAccessors =
        getters.where((e) => !e.isAbstract || e.isStatic);
    final copiedAccessors = concreteGettersAndStaticAccessors
        .where((e) => e.codeOffset != null && e.codeLength != null)
        .map((e) => code.substring(
              e.codeOffset,
              e.codeLength + e.codeOffset,
            ))
        .where((s) => s.isNotEmpty);

    copiedAccessors.forEach(result.writeln);

    return result.toString();
  }

  String staticFieldsFrom(Element element) {
    if (element == null) {
      return '';
    }
    final cls = element as ClassElement;
    final code = cls.source.contents.data;
    final staticFields =
        cls.fields.whereType<FieldElementImpl>().where((e) => e.isStatic);

    final staticCode = staticFields
        .where((e) => e.codeOffset != null && e.codeLength != null)
        .map((e) => code.substring(
              e.codeOffset,
              e.codeLength + e.codeOffset,
            ))
        .where((s) => s.isNotEmpty)
        .map((statement) => '$statement;');

    return staticCode.join('\n');
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

  Tuple2<String, String> signatureAndApplicationFor(
    MethodElement method,
    String builderName,
    String builderTypeParameters,
  ) {
    final type = method.type;
    final signature = StringBuffer();
    final application = StringBuffer();

    final normal = type.normalParameterNames.zip(type.normalParameterTypes);
    final optional =
        type.optionalParameterNames.zip(type.optionalParameterTypes);
    final named =
        type.namedParameterTypes.entries.map((e) => Tuple2(e.key, e.value));

    void writeArg(Tuple2<String, DartType> nameAndType, bool isNamed) {
      final name = nameAndType.item1;
      final t = nameAndType.item2;
      if (t.element == null && name == 'updates') {
        signature
          ..write('void Function(')
          ..write(builderName)
          ..write(builderTypeParameters)
          ..write(')');
      } else {
        signature //
          ..write(t.element.name)
          ..write(_typeParamsFor(t));
      }
      signature..write(' ')..write(name)..write(',');
      application.write(name);
      if (isNamed) {
        application..write(': ')..write(name);
      }
      application.write(',');
    }

    normal.forEach((a) => writeArg(a, false));

    if (optional.isNotEmpty) {
      signature.write('[');
      optional.forEach((a) => writeArg(a, false));
      signature.write(']');
    }

    if (named.isNotEmpty) {
      signature.write('{');
      named.forEach((a) => writeArg(a, true));
      signature.write('}');
    }
    return Tuple2(signature.toString(), application.toString());
  }

  String _defaultConstructorDocumentationFor(ClassElement template) {
    final annotated = template.methods
        .where(constructorChecker.hasAnnotationOfExact)
        .where((el) => constructorChecker
            .firstAnnotationOfExact(el)
            .getField('name')
            .toStringValue()
            .isEmpty);

    final builderName = '${demangled(template.name)}Builder';
    if (annotated.isEmpty) {
      return '''
    /// Create an instance of an [${demangled(template.name)}] with the [updates] applied to to
    /// the [$builderName].
    ''';
    }
    return annotated.single.documentationComment ?? '';
  }

  Tuple2<String, String> _defaultConstructorSignatureAndApplicationFor(
      ClassElement template) {
    final annotated = template.methods
        .where(constructorChecker.hasAnnotationOfExact)
        .where((el) => constructorChecker
            .firstAnnotationOfExact(el)
            .getField('name')
            .toStringValue()
            .isEmpty);

    final builderName = '${demangled(template.name)}Builder';
    if (annotated.isEmpty) {
      return Tuple2('[void Function($builderName) updates]', 'updates');
    }
    final ctor = annotated.single;
    return signatureAndApplicationFor(
        ctor, builderName, _typeParamsFor(template.thisType));
  }

  String _builderFactory(
    String className,
    String ctorName,
    String typeParameters,
    MethodElement method,
  ) {
    final methodName = method.name;
    final doc = method.documentationComment;

    final fnAppl = signatureAndApplicationFor(
        method, '${className}Builder', typeParameters);
    final signature = fnAppl.item1;
    final application = fnAppl.item2;

    return '''
      ${doc ?? ''}
      factory $className${ctorName.isEmpty ? '' : '.$ctorName'}($signature) => _\$$className$typeParameters(
        (__builder)=>__builder
          ..update($methodName$typeParameters($application)));
      ''';
  }

  String _defaultBuilderFactory(
    String className,
    String builderName,
    String typeParameters,
  ) =>
      '''
      /// Construct an [$className] from the updates applied to an
      /// [$builderName].
      factory $className([void Function($builderName$typeParameters) updates]) => _\$$className$typeParameters((b)=>b..update(updates));
      ''';
  Iterable<String> _builderFactories(
    ClassElement cls,
  ) {
    final constructors =
        cls.methods.where(constructorChecker.hasAnnotationOfExact);
    if (constructors.where((el) => !el.isStatic).isNotEmpty) {
      final invalid =
          constructors.where((el) => !el.isStatic).map((e) => e.name);
      throw StateError(
          'Only static methods can be annotated as constructors, but ${invalid.join()} are not.');
    }
    final name = demangled(cls.name);
    final typeParameters = _typeParamsFor(cls.thisType);
    final builderName = '${name}Builder';
    final defaultCtor = _defaultBuilderFactory(
      name,
      builderName,
      typeParameters,
    );
    if (constructors.isEmpty) {
      return [
        defaultCtor,
      ];
    }

    final data = constructors.map((e) => Tuple2(
          e,
          constructorChecker
              .firstAnnotationOfExact(e)
              .getField('name')
              .toStringValue(),
        ));
    final hasDefault = data.any((e) => e.item2.isEmpty);
    final defaultCollection = hasDefault ? <String>[] : [defaultCtor];
    return data
        .map((e) => _builderFactory(name, e.item2, typeParameters, e.item1))
        .followedBy(defaultCollection);
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
    final typeParameters = _typeParamsFor(cls.thisType);
    final builderType = '$builderName$typeParameters';
    classModifiers.implement.add('Built<$name$typeParameters, $builderType>');

    final constructor = _constructor(cls);

    return '''
    ${_bypassedAnnotationsFor(cls).join('\n')}
    ${_hiveTypeAnnotation(templateAnnotation)}
    ${cls.documentationComment ?? ''}
    abstract class $name$classModifiers {
      $constructor

      ${_builderFactories(cls).join('\n')}

      ${isUnion ? '@override ${_visitSignature(unionWith, unitedWith)} => ${_unionMemberAbbreviatedName(unionWith, cls)}(this);' : ''}

      ${isUnion ? '@override' : '/// Serialize an [$name] to an json object.'}
      Map<String, dynamic> toJson() =>
        serializers.serialize(this) as Map<String, dynamic>;

      /// Deserialize an [$name] from an json object.
      static $name fromJson(Map<String, dynamic> json) =>
        serializers.deserializeWith($name.serializer, json);

      /// The [Serializer] that can serialize and deserialize an [$name].
      static Serializer<$name> get serializer => _\$${camelCase(name)}Serializer;
      ${accessorsFrom(templateElement)}
      ${staticFieldsFrom(templateElement)}
      ${methodsFrom(templateElement, false, true)}
      ${methodsFrom(unionWith, false, false)}
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
