import 'package:analyzer/dart/element/element.dart';
import 'package:template_generator/src/utils.dart';

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
