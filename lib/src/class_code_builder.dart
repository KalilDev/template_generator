import 'package:analyzer/dart/element/element.dart';
import 'package:template_generator/src/utils.dart';

abstract class ClassCodeBuilder extends CodeBuilder {
  ClassElement cls;
  String get className => cls.name;
  String get demangledClassName => demangled(className);
  ClassModifiers get verbatinModifiers =>
      ClassModifiers.fromElement(cls)..mixed.addAll(mixins);
  ClassModifiers get modifiers =>
      verbatinModifiers..visitTypes(TypeNameDemangler());
  ParameterizedType get thisType => ParameterizedType(
        verbatinModifiers.typeParams.toArguments(),
        demangledClassName,
      );
  void addMixin(ClassElement mixin) {
    final mixinParams = ClassModifiers.fromElement(mixin).typeParams;
    final hasSameParams = mixinParams == verbatinModifiers.typeParams;
    final hasNoParams = mixinParams == TypeParamList.empty();
    verify(
        hasSameParams || hasNoParams,
        "The mixin class ${mixin.name} should have either no type arguments or "
        "the same type arguments as ${thisType.toSource()}");

    addMixinType(ParameterizedType(
        hasSameParams ? thisType.typeArguments : TypeArgumentList.empty(),
        mixin.name));
  }

  void addMixinType(QualifiedType mixin);

  Iterable<QualifiedType> get mixins;
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
    modifiers.visitTypes(v);
    [
      factories,
      functions,
      acessors,
      fields,
    ].forEach((els) => els.visitAllWith(v));
  }
}
