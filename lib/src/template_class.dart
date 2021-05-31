import 'dart:developer';

import 'package:analyzer/dart/constant/value.dart';
import 'package:source_gen/source_gen.dart';
import 'package:template_annotation/template_annotation.dart';
import 'package:template_generator/src/builder_template_class.dart';
import 'package:template_generator/src/union_class.dart';

import 'class_code_builder.dart';
import 'utils.dart';

import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:collection/collection.dart' as collection;
import 'package:analyzer/dart/element/element.dart' as el;
import 'package:analyzer/dart/element/type.dart' as t;
import 'package:analyzer/src/dart/element/element.dart' as el_impl;
import 'package:tuple/tuple.dart';
import 'package:meta/meta.dart';

T _id<T>(T v) => v;

extension BiFunctorTuple<A, B> on Tuple2<A, B> {
  A get l => item1;
  B get r => item2;
  Tuple2<A1, B> left<A1>(A1 Function(A) fn) => fmap(fn, _id);
  Tuple2<A, B1> right<B1>(B1 Function(B) fn) => fmap(_id, fn);
  Tuple2<A1, B1> fmap<A1, B1>(A1 Function(A) left, B1 Function(B) right) =>
      Tuple2(left(item1), right(item2));
  Tuple2<A1, B1> cast<A1, B1>() => Tuple2(item1 as A1, item2 as B1);
  Tuple2<A1, B> castL<A1>() => Tuple2(item1 as A1, item2);
  Tuple2<A, B1> castR<B1>() => Tuple2(item1, item2 as B1);
}

class Try<T> {
  final T Function() _fn;

  Try(this._fn);
  Try<T1> fmap<T1>(T1 Function(T) map) =>
      Try(() => map(runTry(this, (e) => throw e)));
  Try<T1> bind<T1>(Try<T1> Function(T) map) =>
      map(runTry(this, (e) => throw e));
}

Try<T> liftTry<T>(T obj) => Try(() => obj);
T runTry<T>(Try<T> obj, T Function(Object) onErr) {
  return visitTry(obj, onErr, (t) => t);
}

R visitTry<R, T>(Try<T> obj, R Function(Object) onErr, R Function(T) onVal) {
  // shit
  if (obj == null) {
    return null;
  }
  try {
    final e = obj._fn();
    if (e == null) {
      return null;
    }
    return onVal(e);
  } on Object catch (e) {
    return onErr(e);
  }
}

Tuple2<List<T>, List<Object>> runTries<T>(Iterable<Try<T>> ts) =>
    ts.fold<Tuple2<List<T>, List<Object>>>(Tuple2([], []), (res, e) {
      visitTry(
        e,
        (err) => res..item2.add(err),
        (val) => res..item1.add(val),
      );
      return res;
    });
List<T> handlePartitionedErrors<T>(
  Tuple2<List<T>, List<Object>> objects,
  Never Function(List<Object>) onErrors,
) =>
    objects.item2.isEmpty ? objects.item1 : throw onErrors(objects.item2);

class TemplateClassFactory extends ClassCodeBuilder {
  BuilderTemplateClassFactory builderTemplateFactory;
  UnionClassFactory unionFactory;
  ConstantReader templateAnnotation;

  String get builderClassName =>
      builderTemplateFactory?.demangledClassName ??
      '${demangledClassName}Builder';

  bool get hasHiveType => _hiveTypeAnnotation?.isNotEmpty ?? false;

  Iterable<AcessorDeclaration> get _abstractGetterDeclarations => cls.accessors
      .where((e) => e.isGetter && e.isAbstract)
      .map(liftTry)
      .map((e) => e
          .fmap((e) => AcessorDeclaration.fromElement(e))
          .fmap((e) => e..visitTypes(TypeNameDemangler())))
      .pipe(runTries)
      .pipe((e) => handlePartitionedErrors(
          e,
          (es) => collectFailures(es,
              format: 'Failed to retrieve some getters in the class $className '
                  'with the following errors:\n...{}\n'
                  'Hint: If you want to use an class generated from a @Template'
                  'as the type of the getter, use mangled class name (prefixed '
                  'with $mangledPrefix)!')));

  List<Reference> get valueReferences => _abstractGetterDeclarations
      .map((e) => Reference(e.type, e.name))
      .toList();

  Iterable<FieldDeclaration> get _concreteFields => cls.fields
      .where((e) => e.isStatic)
      .map((e) => FieldDeclaration.fromElement(e));
  Iterable<Tuple2<String, ConcreteFunctionDeclaration>>
      get _annotatedWithConstructor => cls.methods
          .where((e) => e.isStatic)
          .where(constructorChecker.hasAnnotationOf)
          .map((e) => Tuple2(
              ConstantReader(constructorChecker.firstAnnotationOfExact(e)),
              FunctionDeclaration.fromElement(e)
                  as ConcreteFunctionDeclaration))
          .map((e) => e.left((e) => e.read("name")))
          .map((e) =>
              Tuple2(e.item1.isString ? e.item1.stringValue : null, e.item2));
  Iterable<ConcreteFunctionDeclaration> get _notAnnotatedWithConstructor =>
      cls.methods
          .where((e) => e.isStatic)
          .where((e) => !constructorChecker.hasAnnotationOf(e))
          .map((e) => FunctionDeclaration.fromElement(e))
          .cast();

  FactoryDeclaration get defaultFactoryDeclaration =>
      _builderFactories.singleWhere((e) => e.name == null || e.name.isEmpty);

  void addBuilder(BuilderTemplateClassFactory builder) {
    builder.addToTemplate(this);
    builderTemplateFactory = builder;
  }

  void addToUnion(UnionClassFactory union) {
    unionFactory = union;
  }

  String get _hiveTypeAnnotation {
    final type = templateAnnotation.read('hiveType');
    if (type?.isNull ?? true) {
      return '';
    }
    return '@HiveType(typeId: ${type.intValue})';
  }

  List<String> get _annotations => [
        if (_hiveTypeAnnotation != null) _hiveTypeAnnotation,
        ...bypassedAnnotationsFor(cls)
      ];

  bool get isUnion => unionFactory != null;
  @override
  ClassModifiers get verbatinModifiers {
    final modifiers = super.verbatinModifiers;

    modifiers.implemented.add(ParameterizedType(
        TypeArgumentList([
          ParameterizedType(
              modifiers.typeParams.toArguments(), demangledClassName),
          ParameterizedType(
              modifiers.typeParams.toArguments(), builderClassName)
        ]),
        'Built'));
    if (isUnion) {
      modifiers.implemented
          .add(QualifiedType.fromName(unionFactory.demangledClassName));
    }
    return modifiers;
  }

  String get _constructor =>
      unnamedConstructorFrom(cls)
          ?.replaceAll('$className()', '$demangledClassName._()') ??
      '$demangledClassName._();';

  static String generatedFactoryName(String className) => '_\$$className';
  static FactoryDeclaration defaultRedirectingFactoryName(
    TypeParamList typeParams,
    String className,
    String builderName,
  ) =>
      RedirectingFactoryDeclaration(
        FunctionParameters(
          typeParams,
          [],
          [
            PositionalOptionalFunctionParameter(
              FunctionType(
                  TypeParamList.empty(),
                  QualifiedType.voidType,
                  [ParameterizedType(typeParams.toArguments(), builderName)],
                  [],
                  {}),
              'updates',
              false,
              [],
              null,
            )
          ],
          [],
        ),
        null,
        className,
        generatedFactoryName(className),
        false,
      );
  static FactoryDeclaration staticFactoryConstructor(
          ConcreteFunctionDeclaration staticFactory,
          TypeParamList typeParams,
          String factoryName,
          String sourceClassName,
          String targetClassName) =>
      ConcreteFactoryDeclaration(
          staticFactory.prelude.parameters,
          targetClassName,
          factoryName,
          FunctionArrowBody(null,
              '''${generatedFactoryName(targetClassName)}${typeParams.toSource()}((__builder)=>__builder
          ..update($sourceClassName.${staticFactory.prelude.name}${staticFactory.prelude.parameters.toApplicationSource()}))'''));
  static TypeParamList _validatingDeletingTypeParams(
      TypeParamList container, TypeParamList contained) {
    final containedLength = contained.params.length;
    verify(
        collection.IterableEquality<TypeParam>()
            .equals(container.params.take(containedLength), contained.params),
        'The type parameter list ${container.toSource()} should contain the ${contained.toSource()} parameters!');
    return TypeParamList(container.params.skip(containedLength).toList());
  }

  static ConcreteFunctionDeclaration staticMemberFunction(
      ConcreteFunctionDeclaration staticMember,
      String sourceClassName,
      QualifiedType classType,
      TypeParamList classTypeParams) {
    var parameters = staticMember.prelude.parameters;
    verify(parameters.normal.first.name == 'self',
        'First argument should be named self');
    verify(parameters.normal.first.type == classType,
        'First argument should have the same type as self');
    final typeParams =
        _validatingDeletingTypeParams(parameters.typeParams, classTypeParams);
    parameters = FunctionParameters(
        typeParams,
        parameters.normal.skip(1).toList(),
        parameters.optional,
        parameters.named);
    return ConcreteFunctionDeclaration(
        FunctionDeclarationPrelude(
          parameters,
          staticMember.prelude.name,
          staticMember.prelude.returnType,
          false,
        ),
        FunctionArrowBody(null,
            '$sourceClassName.${staticMember.prelude.name}${staticMember.prelude.parameters.toApplicationSource().replaceFirst('self', 'this')}'));
  }

  static GetterDeclaration staticGetterFunction(
      ConcreteFunctionDeclaration staticMember,
      bool memoized,
      String sourceClassName,
      QualifiedType classType,
      TypeParamList classTypeParams) {
    final parameters = staticMember.prelude.parameters;
    verify(
        parameters.normal.length == 1 &&
            parameters.optional.isEmpty &&
            parameters.named.isEmpty,
        'Only a single self argument should be provided');
    verify(parameters.normal.single.name == 'self',
        'Single argument should be named self');
    verify(parameters.normal.single.type == classType,
        'Single argument should have the same type as self');
    return GetterDeclaration(
        staticMember.prelude.returnType,
        false,
        staticMember.prelude.name,
        FunctionArrowBody(null,
            '$sourceClassName.${staticMember.prelude.name}${staticMember.prelude.parameters.toApplicationSource().replaceFirst('self', 'this')}'));
  }

  Set<Reference> get allCataReferences =>
      {...valueReferences, ...?unionFactory?.valueReferences};
  FunctionType cataFunctionType(
      TypeParam returnTypeParam, bool includeSelfTypeParams) {
    final named =
        Map.fromEntries(allCataReferences.map((e) => MapEntry(e.name, e.type)));
    return FunctionType(
      includeSelfTypeParams ? modifiers.typeParams : TypeParamList.empty(),
      returnTypeParam.toArgument(),
      [],
      [],
      named,
    );
  }

  FunctionDeclarationPrelude _cataFunctionPrelude(TypeParam returnTypeParam) =>
      FunctionDeclarationPrelude(
        FunctionParameters(TypeParamList([returnTypeParam]), [
          PositionalRequiredFunctionParameter(
              cataFunctionType(returnTypeParam, false), 'fn', false, [])
        ], [], []),
        'cata',
        returnTypeParam.toArgument(),
        false,
      );
  ConcreteFunctionDeclaration _cataFunctionDeclaration() {
    final returnTypeParam = TypeParam('R', null);
    final params = allCataReferences
        .map((e) => e.name)
        .map((e) => '$e: this.$e')
        .join(',');
    return ConcreteFunctionDeclaration(
      _cataFunctionPrelude(returnTypeParam),
      FunctionArrowBody(null, 'fn($params)'),
    );
  }

  List<FactoryDeclaration> get _builderFactories => [
        if (_annotatedWithConstructor
            .every((e) => e.item1 != null && e.item1.isNotEmpty))
          defaultRedirectingFactoryName(
              modifiers.typeParams, demangledClassName, builderClassName),
        ..._annotatedWithConstructor //
            .map((e) => staticFactoryConstructor(
                  e.item2,
                  modifiers.typeParams,
                  e.item1,
                  className,
                  demangledClassName,
                ))
      ];
  List<FunctionDeclaration> get _functions => [
        _cataFunctionDeclaration(),
      ];
  List<AcessorDeclaration> get _acessors => [
        ..._concreteFields.bind((e) => staticFieldRedirect(e, className)),
        ..._abstractGetterDeclarations,
      ];
  List<FieldDeclaration> get _fields => [
        ..._notAnnotatedWithConstructor
            .map((e) => staticFunctionRedirect(e, className))
      ];

  void _validate() {
    collectFailures(cls.methods.where((e) => !e.isStatic).map((e) => e.name),
        format:
            "Only static methods are allowed, but the following aren't:\n...{}"
            '\nIf you want an member method use an mixin with @MixTo(${thisType.toSource()}).',
        errorFormat: '$className.{}');
    collectFailures(
        cls.accessors
            .where((e) => !e.isStatic && !e.isGetter)
            .map((e) => e.name),
        format: 'Only abstract member getters allowed, but the following are '
            'setters:\n...{}',
        errorFormat: '$className.{}');
    collectFailures(
        cls.accessors
            .where((e) => !e.isStatic && e.isGetter && !e.isAbstract)
            .map((e) => e.name),
        format: 'Only abstract member getters allowed, but the following are '
            'concrete:\n...{}\n'
            'If you want to have an getter with code, use the '
            '@Getter([bool memoized]) annotation.',
        errorFormat: '$className.{}');
  }

  @override
  Code build() {
    _validate();
    return TemplateClass(
      annotations: _annotations,
      comment: cls.documentationComment,
      className: demangledClassName,
      modifiers: modifiers,
      constructor: _constructor,
      factories: _builderFactories,
      visit: isUnion
          ? ConcreteFunctionDeclaration(unionFactory.visitSignature,
              unionFactory.visitInvokeBodyFor(this))
          : null,
      visitCata: isUnion
          ? ConcreteFunctionDeclaration(unionFactory.visitCataSignature,
              unionFactory.visitCataInvokeBodyFor(this))
          : null,
      functions: _functions,
      acessors: _acessors,
      fields: _fields,
    )..visitTypes(TypeNameDemangler());
  }

  TypeParamList get typeParamList => modifiers.typeParams;

  @override
  void addMixinType(QualifiedType mixin) => mixins.add(mixin);

  @override
  final Set<QualifiedType> mixins = {};
}

//${functions(templateElement)}
//${staticFieldsFrom(templateElement)}
//${methodsFrom(templateElement, false)}
//${staticMethodsFrom(templateElement)}
//${methodsFrom(unionWith, false)}
class TemplateClass extends ClassCode {
  final List<String> annotations;
  final String comment;

  final String className;
  final ClassModifiers modifiers;

  final List<String> constructors;
  final List<FactoryDeclaration> factories;

  final FunctionDeclaration visit;
  final FunctionDeclaration visitCata;

  final List<FunctionDeclaration> functions;
  final List<AcessorDeclaration> acessors;
  final List<FieldDeclaration> fields;

  TemplateClass({
    @required this.annotations,
    @required this.comment,
    @required this.className,
    @required this.modifiers,
    @required String constructor,
    @required this.factories,
    @required this.visit,
    @required this.visitCata,
    @required this.functions,
    @required this.acessors,
    @required this.fields,
  }) : constructors = [constructor];

  static ConcreteFunctionDeclaration fromJson(String className) =>
      ConcreteFunctionDeclaration(
        FunctionDeclarationPrelude(
            FunctionParameters(TypeParamList(const []), [
              PositionalRequiredFunctionParameter(
                  QualifiedType.mapStringDynamic, 'json', false, [])
            ], [], []),
            'fromJson',
            QualifiedType.fromName(className),
            true),
        FunctionArrowBody(
          null,
          'serializers.deserializeWith($className.serializer, json)',
        ),
      );
  static ConcreteFunctionDeclaration toJson() => ConcreteFunctionDeclaration(
      toJsonPrelude,
      FunctionArrowBody(
          null, 'serializers.serialize(this) as Map<String, dynamic>'));
  static GetterDeclaration serializer(String className) => GetterDeclaration(
      ParameterizedType(
          TypeArgumentList([QualifiedType.fromName(className)]), 'Serializer'),
      true,
      'serializer',
      FunctionArrowBody(null, '_\$${lowerCamelCase(className)}Serializer'));

  bool get isUnion => visit != null;
  String get additionalBody => '''
      ${isUnion ? '@override ${visit.toSource()}' : ''}
      ${isUnion ? '@override ${visitCata.toSource()}' : ''}

      ${isUnion ? '@override' : '/// Serialize an [$className] to an json object.'}
      ${toJson().toSource()}

      /// Deserialize an [$className] from an json object.
      ${fromJson(className).toSource()}

      /// The [Serializer] that can serialize and deserialize an [$className].
      ${serializer(className).toSource()}
      ''';
}
