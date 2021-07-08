import 'package:analyzer/dart/element/element.dart';
import 'package:template_annotation/template_annotation.dart';
import 'package:template_generator/src/utils.dart';
import 'package:tuple/tuple.dart';

class ElementAndCode<E extends Element, C extends Code> extends Tuple2<E, C> {
  const ElementAndCode(E element, C code) : super(element, code);
  E get element => item1;
  C get code => item2;
}

class MethodAndCode extends ElementAndCode<MethodElement, FunctionDeclaration> {
  const MethodAndCode(MethodElement element, FunctionDeclaration code)
      : super(element, code);
}

class GetterAndCode
    extends ElementAndCode<PropertyAccessorElement, GetterDeclaration> {
  const GetterAndCode(PropertyAccessorElement element, GetterDeclaration code)
      : super(element, code);
}

class SetterAndCode
    extends ElementAndCode<PropertyAccessorElement, SetterDeclaration> {
  const SetterAndCode(PropertyAccessorElement element, SetterDeclaration code)
      : super(element, code);
}

class AcessorAndCode
    extends ElementAndCode<PropertyAccessorElement, AcessorDeclaration> {
  const AcessorAndCode(
    PropertyAccessorElement element,
    AcessorDeclaration code,
  ) : super(element, code);
  GetterAndCode toGetter() => GetterAndCode(element, code as GetterDeclaration);
  SetterAndCode toSetter() => SetterAndCode(element, code as SetterDeclaration);
}

abstract class ClassCodeBuilder {
  ClassElement cls;
  String get className => cls.name;
  String get demangledClassName => demangled(className);

  Future<ClassModifiers> get verbatinModifiers =>
      ClassModifiers.fromElement(cls, resolver: resolver)
          .then((mods) => mods..mixed.addAll(mixins));

  Future<ClassModifiers> get modifiers =>
      verbatinModifiers.then((mods) async => mods
        ..visitTypes(TypeNameDemangler())
        ..implemented.add(await verbatinThisType));

  Future<ParameterizedType> get verbatinThisType async => ParameterizedType(
        (await verbatinModifiers).typeParams.toArguments(),
        className,
      );

  Future<ParameterizedType> get thisType async => ParameterizedType(
        (await verbatinModifiers).typeParams.toArguments(),
        demangledClassName,
      );

  Future<List<MethodAndCode>> get methods => cls.methods
      .where((e) => !e.isSynthetic)
      .map((e) => FunctionDeclaration.fromElement(e, resolver)
          .then((decl) => MethodAndCode(e, decl)))
      .wait();

  Future<List<AcessorAndCode>> get acessors => cls.accessors
      .where((e) => !e.isSynthetic)
      .map((e) => AcessorDeclaration.fromElement(e, resolver)
          .then((decl) => AcessorAndCode(e, decl)))
      .wait();

  Future<List<GetterAndCode>> get getters => cls.accessors
      .where((e) => !e.isSynthetic && e.isGetter)
      .map((e) => AcessorDeclaration.fromElement(e, resolver)
          .then((decl) => AcessorAndCode(e, decl).toGetter()))
      .wait();

  Future<List<SetterAndCode>> get setters => cls.accessors
      .where((e) => !e.isSynthetic && e.isSetter)
      .map((e) => AcessorDeclaration.fromElement(e, resolver)
          .then((decl) => AcessorAndCode(e, decl).toSetter()))
      .wait();

  Future<List<Tuple2<Method, FunctionDeclaration>>>
      get methodAnnotatedStaticFunctions async =>
          methods.then((methods) => methods
              .where((e) => e.element.isStatic)
              .map((e) => e.left(methodAnnotationFrom))
              .where((e) => e.l != null)
              .toList());

  Future<List<FunctionDeclaration>> get memberizedStaticMethods =>
      methodAnnotatedStaticFunctions.then((funs) => funs
          .where((e) => e.l is Method && e.l is! Acessor)
          .map((e) async => _callRedirectedWithAnnotation(
                e.l,
                e.r,
                await verbatinThisType,
                (await modifiers).typeParams,
              ))
          .wait());
  Future<List<AcessorDeclaration>> get memberizedStaticAcessors =>
      methodAnnotatedStaticFunctions.then((funs) => funs
          .where((e) => e.l is Acessor)
          .map((e) async => _acessorRedirectedWithAnnotation(
                e.l,
                e.r,
                await verbatinThisType,
                (await modifiers).typeParams,
                e.l is Getter,
              ))
          .wait());
  ASTNodeResolver get resolver;
  Future<void> addMixin(ClassElement mixin) async {
    final mixinParams = (await ClassModifiers.fromElement(
      mixin,
      resolver: resolver,
    ))
        .typeParams;
    final hasSameParams = mixinParams == (await verbatinModifiers).typeParams;
    final hasNoParams = mixinParams == TypeParamList.empty();
    verify(
        hasSameParams || hasNoParams,
        "The mixin class ${mixin.name} should have either no type arguments or "
        "the same type arguments as ${(await thisType).toSource()}");

    addMixinType(ParameterizedType(
        hasSameParams
            ? (await thisType).typeArguments
            : TypeArgumentList.empty(),
        mixin.name));
  }

  void addMixinType(QualifiedType mixin);

  Iterable<QualifiedType> get mixins;
  Future<ClassCode> build();
}

abstract class ClassCode extends Code {
  Iterable<String> get annotations => [];
  String get comment => null;
  String get className;
  ClassModifiers get modifiers;

  Iterable<String> get constructors => [];
  Iterable<FactoryDeclaration> get factories => [];

  Iterable<FunctionDeclaration> get functions => [];
  Iterable<AcessorDeclaration> get acessors => [];
  Iterable<FieldDeclaration> get fields => [];

  String get additionalBody => null;

  String toSource() => '''
    ${annotations.join('\n')}
    ${comment ?? ''}
    abstract class $className${modifiers?.toSource() ?? ''} {
      ${constructors.join('\n')}

      ${factories.map((e) => e.toSource()).join('\n')}

      ${additionalBody ?? ''}

      ${functions.map((e) => e.toSource()).join('\n')}
      ${acessors.map((e) => e.toSource()).join('\n')}
      ${fields.map((e) => e.toSource()).join('\n')}
    }
    ''';

  @override
  void visitTypes(TypeVisitor v) {
    //modifiers.visitTypes(v);
    [
      factories,
      functions,
      acessors,
      fields,
    ].forEach((els) => els.visitAllWith(v));
  }
}

FunctionBody _bodyForRedirectedWithAnnotation(
  Method annotation,
  FunctionDeclaration decl,
  QualifiedType thisType,
  TypeParamList thisTypeParams,
  TypeParamList targetTypeParams,
) {
  final className = (thisType as ParameterizedType).type;
  thisType.visitTypes(TypeNameDemangler());
  final params = decl.prelude.parameters;
  final typeParams = decl.prelude.parameters.typeParams;
  final selfParam = params.normal.first;
  if (selfParam.name != 'self') {
    throw StateError(
        'Invalid self parameter name on ${decl.prelude.toSource()}, expected `self`');
  }
  if (selfParam.type != thisType) {
    throw StateError(
        'Invalid type on ${decl.prelude.toSource()}, expected `${thisType.toSource()}`');
  }
  if (!listContains(typeParams.params, thisTypeParams.params)) {
    throw StateError(
        'Invalid type params on ${decl.prelude.toSource()}, expected AT LEAST ${thisTypeParams.toSource()}');
  }
  // Rename self to this, so that we call it with `this`, and update the type
  // params
  selfParam.name = 'this';
  decl.prelude.parameters.typeParams = targetTypeParams;
  final body = FunctionArrowBody(
      null,
      className +
          '.' +
          decl.prelude.name +
          decl.prelude.parameters.toApplicationSource(typeArgumentsAlso: true));
  // Rename back to self and to the old type params so that there arent
  // apparent side effects to [decl]
  selfParam.name = 'self';
  decl.prelude.parameters.typeParams = typeParams;
  return body;
}

FunctionDeclarationPrelude _preludeForRedirectedWithAnnotation(
  Method annotation,
  FunctionDeclarationPrelude decl,
  TypeParamList targetTypeParams,
) =>
    FunctionDeclarationPrelude(
      FunctionParameters(
        targetTypeParams,
        decl.parameters.normal.skip(1).toList(),
        decl.parameters.optional,
        decl.parameters.named,
      ),
      annotation.name ?? demangled(decl.name),
      decl.returnType,
      false,
    )
      ..annotations = decl.annotations
      ..documentation = decl.documentation;
final _getRegex = RegExp('get[A-Z]');
final _setRegex = RegExp('set[A-Z]');
String acessorNameFrom(String name, RegExp prefixRegex) {
  name = demangled(name);

  if (!name.startsWith(prefixRegex)) {
    return name;
  }
  return name.substring(3).pipe(lowerCamelCase);
}

SetterDeclaration _setterRedirectedWithAnnotation(
  Method annotation,
  FunctionDeclaration decl,
  QualifiedType thisType,
  TypeParamList thisTypeParams,
) =>
    _acessorRedirectedWithAnnotation(
      annotation,
      decl,
      thisType,
      thisTypeParams,
      false,
    ) as SetterDeclaration;
GetterDeclaration _getterRedirectedWithAnnotation(
  Method annotation,
  FunctionDeclaration decl,
  QualifiedType thisType,
  TypeParamList thisTypeParams,
) =>
    _acessorRedirectedWithAnnotation(
      annotation,
      decl,
      thisType,
      thisTypeParams,
      true,
    ) as GetterDeclaration;

AcessorDeclaration _acessorRedirectedWithAnnotation(
  Method annotation,
  FunctionDeclaration decl,
  QualifiedType thisType,
  TypeParamList thisTypeParams,
  bool isGetter,
) {
  final typeParams = decl.prelude.parameters.typeParams;
  final targetTypeParams = TypeParamList(
      typeParams.params.skip(thisTypeParams.params.length).toList());
  final prelude = _preludeForRedirectedWithAnnotation(
    annotation,
    decl.prelude,
    targetTypeParams,
  );
  final targetParamCount = isGetter ? 0 : 1;
  if (prelude.parameters.normal.length != targetParamCount ||
      prelude.parameters.optional.isNotEmpty ||
      prelude.parameters.named.isNotEmpty ||
      prelude.parameters.typeParams.params.isNotEmpty) {
    throw StateError(
        'Invalid params on ${decl.prelude.toSource()}, expected an single param of any type and no type params, but got ${prelude.parameters.toSource()}');
  }
  final body = _bodyForRedirectedWithAnnotation(
    annotation,
    decl,
    thisType,
    thisTypeParams,
    targetTypeParams,
  );
  final name = annotation.name ??
      acessorNameFrom(
        decl.prelude.name,
        isGetter ? _getRegex : _setRegex,
      );
  if (isGetter) {
    return GetterDeclaration(
      decl.prelude.returnType,
      false,
      name,
      body,
    )
      ..documentation = decl.documentation
      ..annotations = decl.annotations;
  }
  final param = prelude.parameters.normal.single;
  return SetterDeclaration(
    Reference(param.type, param.name),
    false,
    name,
    body,
  )
    ..documentation = decl.documentation
    ..annotations = decl.annotations;
}

ConcreteFunctionDeclaration _callRedirectedWithAnnotation(
  Method annotation,
  FunctionDeclaration decl,
  QualifiedType thisType,
  TypeParamList thisTypeParams,
) {
  final typeParams = decl.prelude.parameters.typeParams;
  final targetTypeParams = TypeParamList(
      typeParams.params.skip(thisTypeParams.params.length).toList());
  return ConcreteFunctionDeclaration(
      _preludeForRedirectedWithAnnotation(
        annotation,
        decl.prelude,
        targetTypeParams,
      ),
      _bodyForRedirectedWithAnnotation(
        annotation,
        decl,
        thisType,
        thisTypeParams,
        targetTypeParams,
      ));
}
