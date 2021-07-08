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

  Future<List<GetterDeclaration>> get _abstractGetterDeclarations async => cls
      .accessors
      .where((e) => e.isGetter && e.isAbstract)
      .map(liftTry)
      .map((e) => e
          .fmap((e) => AcessorDeclaration.fromElement(e, resolver))
          .fmap((e) => e
              .then((e) => e as GetterDeclaration)
              .then((e) => e..visitTypes(TypeNameDemangler()))))
      .pipe(runTries)
      .pipe((e) => handlePartitionedErrors(
          e,
          (es) => collectFailures(es,
              format: 'Failed to retrieve some getters in the class $className '
                  'with the following errors:\n...{}\n'
                  'Hint: If you want to use an class generated from a @Template'
                  'as the type of the getter, use mangled class name (prefixed '
                  'with $mangledPrefix)!')))
      .wait();

  Future<List<Reference>> get valueReferences => _abstractGetterDeclarations
      .then((decls) => decls.map((e) => Reference(e.type, e.name)).toList());

  Iterable<FieldDeclaration> get _concreteFields => cls.fields
      .where((e) => e.isStatic)
      .map((e) => FieldDeclaration.fromElement(e));
  Future<Iterable<Tuple2<String, ConcreteFunctionDeclaration>>>
      get _annotatedWithConstructor => cls.methods
          .where((e) => e.isStatic)
          .where(constructorChecker.hasAnnotationOf)
          .map((e) async => Tuple2(
              ConstantReader(constructorChecker.firstAnnotationOfExact(e)),
              await FunctionDeclaration.fromElement(e, resolver)
                  .then((e) => e as ConcreteFunctionDeclaration)))
          .wait()
          .then((e) => e.map((e) => e.left((e) => e.read("name"))).map((e) =>
              Tuple2(e.item1.isString ? e.item1.stringValue : null, e.item2)));
  Future<List<ConcreteFunctionDeclaration>>
      get _notAnnotatedWithConstructorOrMethod => cls.methods
          .where((e) => e.isStatic)
          .where((e) =>
              !constructorChecker.hasAnnotationOf(e) &&
              !methodChecker.hasAnnotationOf(e))
          .map((e) => FunctionDeclaration.fromElement(e, resolver)
              .then((e) => e as ConcreteFunctionDeclaration))
          .wait();

  Future<FactoryDeclaration> get defaultFactoryDeclaration async =>
      _builderFactories.then((factories) =>
          factories.singleWhere((e) => e.name == null || e.name.isEmpty));

  void addBuilder(BuilderTemplateClassFactory builder) {
    builder.addToTemplate(this);
    builderTemplateFactory = builder;
  }

  void addToUnion(UnionClassFactory union) {
    unionFactory = union;
  }

  bool get _specifiedType =>
      templateAnnotation.read('specifiedType')?.maybeBoolValue ??
      unionFactory == null;
  String get _cataConstructorName =>
      templateAnnotation.read('cataConstructorName')?.maybeStringValue;
  String get _hiveTypeAnnotation {
    final type = templateAnnotation.read('hiveType')?.maybeIntValue;
    if (type == null) {
      return '';
    }
    return '@HiveType(typeId: $type)';
  }

  List<String> get _annotations => [
        if (_hiveTypeAnnotation != null) _hiveTypeAnnotation,
        ...bypassedAnnotationsFor(cls)
      ];

  bool get isUnion => unionFactory != null;
  @override
  Future<ClassModifiers> get verbatinModifiers async {
    final modifiers = await super.verbatinModifiers;

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
  static FactoryDeclaration defaultRedirectingFactory(
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
  static FactoryDeclaration defaultCataFactory(
    TypeParamList typeParams,
    String className,
    String builderName,
    List<GetterDeclaration> fields,
    String targetName,
  ) {
    final parameters = FunctionParameters(
      typeParams,
      [
        if (fields.length <= 2)
          ...fields.map((e) => PositionalRequiredFunctionParameter(
                e.type,
                e.name,
                false,
                [],
              ))
      ],
      [],
      [
        if (fields.length > 2)
          ...fields.map((e) => NamedFunctionParameter(
              e.type,
              e.name,
              false,
              [],
              e.type is ParameterizedType
                  ? (e.type as ParameterizedType).type == 'Maybe'
                      ? 'const None()'
                      : null
                  : null,
              !e.annotations.any((e) => e.trim() == '@nullable')))
      ],
    );
    final body = fields.fold<StringBuffer>(
        StringBuffer(generatedFactoryName(className))
          ..write(typeParams.toArguments().toSource())
          ..write('((__bdr)=>__bdr'),
        (buff, e) => buff..writeln('..${e.name} = ${e.name}'))
      ..write(')');
    return ConcreteFactoryDeclaration(
      parameters,
      className,
      targetName,
      FunctionArrowBody(null, body.toString()),
    );
  }

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

  Future<Set<Reference>> get allCataReferences async =>
      {...await valueReferences, ...?await unionFactory?.valueReferences};
  Future<FunctionType> cataFunctionType(
    TypeParam returnTypeParam,
    bool includeSelfTypeParams,
  ) async {
    final named = Map.fromEntries(
        (await allCataReferences).map((e) => MapEntry(e.name, e.type)));
    return FunctionType(
      includeSelfTypeParams ? await typeParamList : TypeParamList.empty(),
      returnTypeParam.toArgument(),
      [],
      [],
      named,
    );
  }

  Future<FunctionDeclarationPrelude> _cataFunctionPrelude(
          TypeParam returnTypeParam) async =>
      FunctionDeclarationPrelude(
        FunctionParameters(TypeParamList([returnTypeParam]), [
          PositionalRequiredFunctionParameter(
              await cataFunctionType(returnTypeParam, false), 'fn', false, [])
        ], [], []),
        'cata',
        returnTypeParam.toArgument(),
        false,
      );
  Future<ConcreteFunctionDeclaration> _cataFunctionDeclaration() async {
    final returnTypeParam = TypeParam('R', null);
    final params = (await allCataReferences)
        .map((e) => e.name)
        .map((e) => '$e: this.$e')
        .join(',');
    return ConcreteFunctionDeclaration(
      await _cataFunctionPrelude(returnTypeParam),
      FunctionArrowBody(null, 'fn($params)'),
    );
  }

  Future<List<FactoryDeclaration>> get _builderFactories async {
    final typeParams = await typeParamList;
    return [
      if ((await _annotatedWithConstructor)
          .every((e) => e.item1 != null && e.item1.isNotEmpty))
        _cataConstructorName == ''
            ? defaultCataFactory(
                typeParams,
                demangledClassName,
                builderClassName,
                await _abstractGetterDeclarations,
                '',
              )
            : defaultRedirectingFactory(
                typeParams,
                demangledClassName,
                builderClassName,
              ),
      ...(await _annotatedWithConstructor) //
          .map((e) => staticFactoryConstructor(
                e.item2,
                typeParams,
                e.item1,
                className,
                demangledClassName,
              )),
      if (_cataConstructorName != '' && _cataConstructorName != null)
        defaultCataFactory(
          typeParams,
          demangledClassName,
          builderClassName,
          await _abstractGetterDeclarations,
          _cataConstructorName,
        ),
    ];
  }

  Future<List<FunctionDeclaration>> get _functions async => [
        await _cataFunctionDeclaration(),
        ...await memberizedStaticMethods,
      ];
  Future<List<AcessorDeclaration>> get _acessors async => [
        ..._concreteFields.bind((e) => staticFieldRedirect(e, className)),
        ...await _abstractGetterDeclarations,
        ...await memberizedStaticAcessors
      ];
  Future<List<FieldDeclaration>> get _fields async => [
        ...(await _notAnnotatedWithConstructorOrMethod)
            .map((e) => staticFunctionRedirect(e, className))
      ];

  Future<void> _validate() async {
    collectFailures(cls.methods.where((e) => !e.isStatic).map((e) => e.name),
        format:
            "Only static methods are allowed, but the following aren't:\n...{}"
            '\nIf you want an member method use an mixin with @MixTo(${(await thisType).toSource()}).',
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
  Future<ClassCode> build() async {
    await _validate();
    return TemplateClass(
      annotations: _annotations,
      comment: cls.documentationComment,
      className: demangledClassName,
      modifiers: await modifiers,
      constructor: _constructor,
      factories: await _builderFactories,
      visit: isUnion
          ? ConcreteFunctionDeclaration(await unionFactory.visitSignature,
              await unionFactory.visitInvokeBodyFor(this))
          : null,
      visitCata: isUnion
          ? ConcreteFunctionDeclaration(await unionFactory.visitCataSignature,
              await unionFactory.visitCataInvokeBodyFor(this))
          : null,
      functions: await _functions,
      acessors: await _acessors,
      fields: await _fields,
      specifiedType: _specifiedType,
    )..visitTypes(TypeNameDemangler());
  }

  @override
  ASTNodeResolver resolver;

  Future<TypeParamList> get typeParamList =>
      modifiers.then((mods) => mods.typeParams);

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
  final bool specifiedType;

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
    @required this.specifiedType,
  }) : constructors = [constructor];

  static ConcreteFunctionDeclaration fromJson(
    String className,
    String specifiedType,
    QualifiedType selfType,
  ) =>
      ConcreteFunctionDeclaration(
        FunctionDeclarationPrelude(
            FunctionParameters(TypeParamList(const []), [
              PositionalRequiredFunctionParameter(
                  QualifiedType.mapStringDynamic, 'json', false, [])
            ], [], []),
            'fromJson',
            selfType,
            true),
        FunctionArrowBody(
          null,
          'serializers.deserialize(json, specifiedType: $specifiedType) '
          'as ${selfType.toSource()}',
        ),
      );
  static ConcreteFunctionDeclaration toJson(
    String className,
    String specifiedType,
  ) =>
      ConcreteFunctionDeclaration(
          toJsonPrelude,
          FunctionArrowBody(
              null,
              'serializers.serialize(this, specifiedType: $specifiedType) '
              'as Map<String, dynamic>'));
  static GetterDeclaration serializer(
    String className,
    QualifiedType selfType,
  ) =>
      GetterDeclaration(
          ParameterizedType(TypeArgumentList([selfType]), 'Serializer'),
          true,
          'serializer',
          FunctionArrowBody(null, '_\$${lowerCamelCase(className)}Serializer'));

  static String parameterizedTypeToFullTypeInstantiation(
      ParameterizedType type) {
    if (type == null ||
        type == QualifiedType.dynamic ||
        type == QualifiedType.object) return 'FullType.object';
    final params = type.typeArguments.arguments
        .cast<ParameterizedType>()
        .map(parameterizedTypeToFullTypeInstantiation);
    return 'FullType(${type.type}, [${params.join(',')}])';
  }

  String get _specifiedType {
    if (!specifiedType) {
      return 'FullType.unspecified';
    }
    final typeParams = modifiers.typeParams.params
        .map((e) => e.constraint)
        .cast<ParameterizedType>()
        .map(parameterizedTypeToFullTypeInstantiation);

    return 'FullType($className, [${typeParams.join(',')}])';
  }

  QualifiedType get _selfBottomType => ParameterizedType(
      TypeArgumentList(modifiers.typeParams.params
          .map((e) => e.constraint ?? QualifiedType.object)
          .toList()),
      className);

  bool get isUnion => visit != null;
  String get additionalBody => '''
      ${isUnion ? '@override ${visit.toSource()}' : ''}
      ${isUnion ? '@override ${visitCata.toSource()}' : ''}

      ${isUnion ? '@override' : '/// Serialize an [$className] to an json object.'}
      ${toJson(className, _specifiedType).toSource()}

      /// Deserialize an [$className] from an json object.
      ${fromJson(className, _specifiedType, _selfBottomType).toSource()}

      /// The [Serializer] that can serialize and deserialize an [$className].
      ${serializer(className, _selfBottomType).toSource()}
      ''';
}
