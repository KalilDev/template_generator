import 'dart:async';
import 'dart:developer';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/ast/ast.dart';
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

import 'utils.dart' as util;

Iterable<T> infiniteIterable<T>(T value) sync* {
  while (true) {
    yield value;
  }
}

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

extension _Unwrap2a<T1, T2, T3> on Iterable<Tuple2<T1, Tuple2<T2, T3>>> {
  Iterable<Tuple3<T1, T2, T3>> unwrap() =>
      map((e) => Tuple3(e.item1, e.item2.item1, e.item2.item2));
}

extension _Unwrap2b<T1, T2, T3> on Iterable<Tuple2<Tuple2<T1, T2>, T3>> {
  Iterable<Tuple3<T1, T2, T3>> unwrap() =>
      map((e) => Tuple3(e.item1.item1, e.item1.item2, e.item2));
}

extension _Unwrap3a<T1, T2, T3, T4>
    on Iterable<Tuple3<Tuple2<T1, T2>, T3, T4>> {
  Iterable<Tuple4<T1, T2, T3, T4>> unwrap() =>
      map((e) => Tuple4(e.item1.item1, e.item1.item2, e.item2, e.item3));
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

  Element unionForNamed(String name) {
    final el = unitedToUnion.keys.singleWhere(
      (el) => demangled(el.name) == demangled(name),
      orElse: () => null,
    );
    return unitedToUnion[el];
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
    builderTemplateChecker,
  };
  static final templateChecker = TypeChecker.fromRuntime(Template);
  static final unionChecker = TypeChecker.fromRuntime(Union);
  static final hiveTypeChecker = TypeChecker.fromRuntime(HiveType);
  static final constructorChecker = TypeChecker.fromRuntime(Constructor);
  static final builderTemplateChecker =
      TypeChecker.fromRuntime(BuilderTemplate);
  static final memberChecker = TypeChecker.fromRuntime(Member);

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
    final result = StringBuffer();

    Future<void> write(FutureOr<String> generatorOutput) async {
      await for (var value in normalizeGeneratorOutput(generatorOutput)) {
        assert(value.length == value.trim().length);
        result..write(value)..write('\n\n');
      }
    }

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

    await write(generateSerializersStatement(annotated.entries
        .where((e) => e.value.instanceOf(templateChecker))
        .map((e) => e.key)
        .toList()));
    await write(generateHiveTypeStatement(annotated.entries
        .where((e) => e.value.instanceOf(templateChecker))
        .where((el) => !el.value.read("hiveType").isNull)
        .map((e) => e.key)
        .toList()));
    for (var e in annotated.entries) {
      var generatedValue;
      if (e.value.instanceOf(unionChecker)) {
        generatedValue = generateUnionElement(
          e.key,
          e.value,
          buildStep,
          unitedWith: unitedTypes.unionToUnited[e.key],
        );
      } else if (e.value.instanceOf(templateChecker)) {
        generatedValue = generateTemplateElement(
          e.key,
          e.value,
          buildStep,
          unionWith: unitedTypes.unitedToUnion[e.key],
          unitedWith:
              unitedTypes.unionToUnited[unitedTypes.unitedToUnion[e.key]],
        );
      } else if (e.value.instanceOf(builderTemplateChecker)) {
        generatedValue = generateBuilderTemplateElement(
            e.key, e.value, buildStep,
            unionWithClass:
                unitedTypes.unionForNamed(_nameFromBuilderName(e.key.name)));
      }
      await write(generatedValue);
    }

    if (result.isEmpty) {
      return null;
    }

    result.writeln('// ignore_for_file: '
        'lines_longer_than_80_chars, '
        'sort_unnamed_constructors_first, '
        'prefer_constructors_over_static_methods, '
        'avoid_single_cascade_in_expression_statements');

    return result.toString();
  }

  String _unionMemberClassFactory(Element union, Element unionMember) {
    final memberName = demangled(unionMember.name);
    final abbrMember = _unionMemberAbbreviatedName(union, unionMember);
    final typeParams = _typeParamsFor((unionMember as ClassElement).thisType);

    final defaultCtor =
        _defaultConstructorSignatureAndApplicationFor(unionMember);
    return '''
    ${_defaultConstructorDocumentationFor(unionMember)}
    static $memberName$typeParams $abbrMember$typeParams${defaultCtor.item1}
        => $memberName$typeParams${defaultCtor.item2};
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
      ${staticMethodsFrom(cls)}
      ${methodsFrom(cls, true)}
    }
    ''';
  }

  String staticMethodsFrom(Element element) {
    if (element == null) {
      return '';
    }
    final cls = element as ClassElement;
    final methods = cls.methods.where((m) => m.isStatic);

    util.FunctionDeclaration _dclFrom(MethodElement e) {
      final dcl = util.FunctionDeclaration.fromElement(e);
      if (dcl.parameters.normal.isEmpty) {
        throw StateError(
            'Static methods annotated with @Method need to have at least an'
            ' single positional argument called `self`.');
      }
      final firstParam = dcl.parameters.normal.first;
      if ((firstParam.type as util.ParameterizedType).type !=
              demangled(cls.name) ||
          firstParam.name != 'self') {
        throw StateError(
            'Static methods annotated with @Method should have the first '
            'param called self and with the type of the generated class, but on ${cls.name}.${e.name} it isn\'t.\n'
            'The first param needed to be of type ${demangled(cls.name)} and called `self`, but it was of type ${firstParam.type.toSource()} and called ${firstParam.name}');
      }
      dcl.parameters.normal.removeAt(0);
      return dcl;
    }

    String _toSourceWithThis(util.FunctionParameters params) {
      params.normal.insert(
          0,
          util.PositionalRequiredFunctionParameter(
            util.QualifiedType.fromName('dynamic'),
            'this',
            false,
            [],
          ));
      return params.toApplicationSource();
    }

    final statics = methods
        .where((e) => !memberChecker.hasAnnotationOfExact(e))
        .map((e) => '''
      ${e.documentationComment ?? ''}
      static const ${e.name} = ${cls.name}.${e.name};''');
    final fakeMethods = methods
        .where(memberChecker.hasAnnotationOfExact)
        .map((e) => Tuple2(e.documentationComment, _dclFrom(e)))
        .map((e) => '''
      ${e.item1 ?? ''}
      ${e.item2.toSource()} => ${cls.name}.${e.item2.name}${_toSourceWithThis(e.item2.parameters)};''');
    return statics.followedBy(fakeMethods).join('\n');
  }

  String methodsFrom(Element element, bool isUnionClass) {
    if (element == null) {
      return '';
    }
    final cls = element as ClassElement;
    final methods =
        cls.methods.whereType<MethodElementImpl>().where((m) => !m.isStatic);
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
    final notBuilderTemplate = !builderTemplateChecker.hasAnnotationOf(element);
    if (cls.accessors.any((e) => e.isSetter && !e.isStatic) &&
        notBuilderTemplate) {
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

  String fieldsFrom(Element element, [bool Function(FieldElement) where]) {
    if (element == null) {
      return '';
    }
    where ??= (_) => true;
    final cls = element as ClassElement;
    final code = cls.source.contents.data;
    final staticFields = cls.fields.whereType<FieldElementImpl>().where(where);

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

  String staticFieldsFrom(Element element) {
    if (element == null) {
      return '';
    }
    final cls = element as ClassElement;
    final clsFields = cls.fields.where((m) => m.isStatic);
    final declsAndElements = clsFields
        .cast<FieldElementImpl>()
        .map((e) => Tuple2(e, e.linkedNode as VariableDeclaration));

    String typeForDcl(FieldElementImpl e, VariableDeclaration dcl) {
      final dcls = dcl.parent as VariableDeclarationList;
      final explicitType = dcls.type?.toSource();
      if (explicitType != null) {
        return explicitType;
      }

      final inferredType = '${e.type.element.name}${_typeParamsFor(e.type)}';
      return inferredType;
    }

    Iterable<String> docForDcls(VariableDeclarationList dcls) {
      return dcls.variables
          .map((e) => e.declaredElement)
          .map((e) => e.documentationComment);
    }

    final nameTypeCommentAssignable = declsAndElements.map(
      (de) => Tuple4(
          de.item1.name,
          typeForDcl(de.item1, de.item2),
          de.item1.documentationComment,
          !de.item1.isConst && !de.item2.isFinal),
    );

    return nameTypeCommentAssignable
        .bind((e) => [
              '${e.item3 ?? ''}',
              'static ${e.item2 ?? 'dynamic'} get ${e.item1} => ${cls.name}.${e.item1};',
              if (e.item4)
                'static set(${e.item2 ?? 'dynamic'} v) => ${cls.name}.${e.item1} = v;'
            ])
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

  Tuple2<String, String> signatureAndApplicationFor(
    MethodElement method,
    String builderName,
    String builderTypeParameters,
  ) {
    final decl = util.FunctionParameters.fromElement(method);
    return Tuple2(decl.toSource(typeArgumentsAlso: false),
        decl.toApplicationSource(typeArgumentsAlso: false));

    final signature = StringBuffer();
    final application = StringBuffer();

    final parameters = method.parameters
        .cast<ParameterElementImpl>()
        .map((e) => e.linkedNode)
        .cast<FormalParameter>();

    Tuple5<List<String>, String, String, String, bool> extractInfo(
        FormalParameter p) {
      final annotations = p?.metadata?.map((e) => e.toSource())?.toList();
      final defaultV =
          (p is DefaultFormalParameter) ? p.defaultValue?.toSource() : null;
      final name = p.identifier.name;
      final typename = (p is SimpleFormalParameter)
          ? p.type.toSource()
          : (p is DefaultFormalParameter)
              ? (p.parameter as SimpleFormalParameter).type.toSource()
              : throw StateError('');
      return Tuple5(
          annotations, name, typename, defaultV, p.covariantKeyword != null);
    }

    final normal = parameters.where((e) => e.isRequiredPositional);
    final optional = parameters.where((e) => e.isOptionalPositional);
    final optionalNamed =
        parameters.where((e) => e.isOptionalNamed).zip(infiniteIterable(false));
    final requiredNamed =
        parameters.where((e) => e.isRequiredNamed).zip(infiniteIterable(true));
    final named = optionalNamed.followedBy(requiredNamed);

    final required = '@required';

    void writeArg(
        Tuple5<List<String>, String, String, String, bool>
            annNameTypeDefaultCovariant,
        bool isNamed,
        bool isRequired) {
      final annotations = annNameTypeDefaultCovariant.item1;
      final name = annNameTypeDefaultCovariant.item2;
      final type = annNameTypeDefaultCovariant.item3;
      final defaultV = annNameTypeDefaultCovariant.item4;
      final covariant = annNameTypeDefaultCovariant.item5;
      signature //
        ..writeAll(annotations, ' ')
        ..write(' ')
        ..write(covariant ? 'covariant ' : '')
        ..write(demangled(type))
        ..write(' ')
        ..write(name)
        ..write(' ')
        ..write(defaultV == null ? '' : '= $defaultV')
        ..write(',');
      if (isRequired) {
        application..write(required)..write(' ');
      }
      application.write(name);
      if (isNamed) {
        application..write(': ')..write(name);
      }
      application.write(',');
    }

    normal.map(extractInfo).forEach((a) => writeArg(a, false, false));

    if (optional.isNotEmpty) {
      signature.write('[');
      optional.map(extractInfo).forEach((a) => writeArg(a, false, false));
      signature.write(']');
    }

    if (named.isNotEmpty) {
      signature.write('{');
      named
          .map((a) => Tuple2(extractInfo(a.item1), a.item2))
          .forEach((a) => writeArg(a.item1, true, a.item2));
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
      return Tuple2('([void Function($builderName) updates])', '(updates)');
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
      factory $className${ctorName.isEmpty ? '' : '.$ctorName'}$signature => _\$$className$typeParameters(
        (__builder)=>__builder
          ..update($methodName$typeParameters$application));
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

  String _nameFromBuilderName(String builderName) =>
      demangled(builderName.substring(0, builderName.indexOf('Builder')));

  Future<String> generateBuilderTemplateElement(Element templateElement,
      ConstantReader templateAnnotation, BuildStep buildStep,
      {Element unionWithClass}) async {
    final cls = templateElement as ClassElement;
    final builderName = demangled(cls.name);
    final name = _nameFromBuilderName(cls.name);
    final classModifiers = ClassModifiers.fromElement(templateElement);
    final typeParameters = _typeParamsFor(cls.thisType);
    final builderType = '$builderName$typeParameters';
    classModifiers.implement.add('Builder<$name$typeParameters, $builderType>');
    if (unionWithClass != null) {
      classModifiers.implement.add('${demangled(unionWithClass.name)}Builder');
    }

    final constructor = _constructor(cls);

    return '''
    ${_bypassedAnnotationsFor(cls).join('\n')}
    ${cls.documentationComment ?? ''}
    abstract class $builderName$classModifiers {
      $constructor

      factory $builderName() = _\$$builderName;

      ${accessorsFrom(templateElement)}
      ${fieldsFrom(templateElement)}
      ${staticFieldsFrom(templateElement)}
      ${staticMethodsFrom(templateElement)}
      ${methodsFrom(templateElement, false)}
    }
    ''';
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
      ${methodsFrom(templateElement, false)}
      ${staticMethodsFrom(templateElement)}
      ${methodsFrom(unionWith, false)}
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

String mangled(String name) {
  if (name.startsWith(mangledPrefix)) {
    return name;
  }
  return '$mangledPrefix$name';
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
