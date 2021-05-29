import 'package:source_gen/source_gen.dart';
import 'package:template_generator/src/template_class.dart';

import 'class_code_builder.dart';
import 'utils.dart';

import 'package:analyzer/dart/ast/ast.dart' as ast;

import 'package:analyzer/dart/element/element.dart' as el;
import 'package:analyzer/dart/element/type.dart' as t;
import 'package:analyzer/src/dart/element/element.dart' as el_impl;
import 'package:tuple/tuple.dart';
import 'package:meta/meta.dart';

class UnionClassFactory extends ClassCodeBuilder {
  final List<TemplateClassFactory> memberFactories = [];
  ConstantReader unionAnnotation;
  Iterable<AcessorDeclaration> get _abstractGetterDeclarations => cls.accessors
      .where((e) => e.isGetter && e.isAbstract)
      .map((e) => AcessorDeclaration.fromElement(e));

  String get afix {
    final afix = unionAnnotation.read('afix');
    if (afix == null || afix.isNull) {
      return demangledClassName;
    }
    return afix.stringValue;
  }

  List<Reference> get valueReferences => cls.accessors
      .where((e) => e.isGetter && e.isAbstract)
      .map((e) => AcessorDeclaration.fromElement(e))
      .map((e) => Reference(e.type, e.name))
      .toList();

  static NamedFunctionParameter _visitFunctionParamFor(
    TypeParamList typeParams,
    String className,
    TypeParam returnTypeParam,
    String paramName,
  ) {
    final positional = [ParameterizedType(typeParams.toArguments(), className)];
    return NamedFunctionParameter(
      FunctionType(
        typeParams,
        returnTypeParam.toArgument(),
        positional,
        [],
        {},
      ),
      paramName,
      false,
      [],
      null,
      true,
    );
  }

  static NamedFunctionParameter _cataFunctionParamFor(
      Set<Reference> valueReferences,
      TypeParamList typeParams,
      TypeParam returnTypeParam,
      String paramName) {
    final named =
        Map.fromEntries(valueReferences.map((e) => MapEntry(e.name, e.type)));
    return NamedFunctionParameter(
      FunctionType(
        typeParams,
        returnTypeParam.toArgument(),
        [],
        [],
        named,
      ),
      paramName,
      false,
      [],
      null,
      true,
    );
  }

  FunctionDeclarationPrelude get visitCataSignature {
    final returnTypeParam = TypeParam('R', null);
    return FunctionDeclarationPrelude(
      FunctionParameters(
          TypeParamList([returnTypeParam]),
          [],
          [],
          memberFactories
              .map((e) => NamedFunctionParameter(
                    e.cataFunctionType(returnTypeParam, true),
                    _visitParamNameFor(e),
                    false,
                    [],
                    null,
                    true,
                  ))
              .toList()),
      'visitCata',
      returnTypeParam.toArgument(),
      false,
    );
  }

  FunctionDeclarationPrelude get visitSignature {
    final returnTypeParam = TypeParam('R', null);
    return FunctionDeclarationPrelude(
      FunctionParameters(
          TypeParamList([returnTypeParam]),
          [],
          [],
          memberFactories
              .map((e) => _visitFunctionParamFor(
                    e.typeParamList,
                    e.demangledClassName,
                    returnTypeParam,
                    _visitParamNameFor(e),
                  ))
              .toList()),
      'visit',
      returnTypeParam.toArgument(),
      false,
    );
  }

  String _visitParamNameFor(TemplateClassFactory templateClassFactory) {
    var name = templateClassFactory.demangledClassName;
    name = name.replaceFirst(afix, '');
    name = lowerCamelCase(name);
    return name;
  }

  FunctionBody visitInvokeBodyFor(TemplateClassFactory f) {
    return FunctionArrowBody(
        null, '${_visitParamNameFor(f)}${f.typeParamList.toSource()}(this)');
  }

  FunctionBody visitCataInvokeBodyFor(TemplateClassFactory f) {
    final namedParameters = f.allCataReferences
        .map((e) => e.name)
        .map((e) => '$e: this.$e')
        .join(', ');

    return FunctionArrowBody(null,
        '${_visitParamNameFor(f)}${f.typeParamList.toSource()}($namedParameters)');
  }

  void addMember(TemplateClassFactory member) {
    member.addToUnion(this);
    memberFactories.add(member);
  }

  FunctionDeclaration _staticFactoryFrom(TemplateClassFactory classFactory) {
    final declaration = classFactory.defaultFactoryDeclaration;
    final name = _visitParamNameFor(classFactory);
    return ConcreteFunctionDeclaration(
        FunctionDeclarationPrelude(
          declaration.parameters,
          name,
          ParameterizedType(classFactory.typeParamList.toArguments(),
              classFactory.demangledClassName),
          true,
        ),
        FunctionArrowBody(null,
            '${classFactory.demangledClassName}${declaration.parameters.toApplicationSource()}'));
  }

  List<FunctionDeclaration> get _memberStaticFactories =>
      memberFactories.map(_staticFactoryFrom).toList();

  List<AcessorDeclaration> get _acessors => cls.fields
      .where((e) => e.isStatic)
      .map((e) => FieldDeclaration.fromElement(e))
      .bind((e) => staticFieldRedirect(e, className))
      .followedBy(_abstractGetterDeclarations)
      .toList();
  List<FieldDeclaration> get _fields => cls.methods
      .where((e) => e.isStatic)
      .map((e) => FunctionDeclaration.fromElement(e))
      .map((e) => staticFunctionRedirect(e, className))
      .toList();

  @override
  Code build() {
    return UnionClass(
      comment: cls.documentationComment,
      className: demangledClassName,
      modifiers: ClassModifiers.fromElement(cls)
        ..visitTypes(TypeNameDemangler()),
      memberStaticFactories: _memberStaticFactories,
      visit: AbstractFunctionDeclaration(visitSignature),
      visitCata: AbstractFunctionDeclaration(visitCataSignature),
      functions: [],
      acessors: _acessors,
      fields: _fields,
    )..visitTypes(TypeNameDemangler());
  }

  @override
  void addMixinType(QualifiedType mixin) {
    mixins.add(mixin);
    memberFactories.forEach((e) => e.addMixinType(mixin));
  }

  @override
  Set<QualifiedType> mixins = {};
}

class UnionClass extends ClassCode {
  final String comment;
  final String className;
  final ClassModifiers modifiers;

  final List<FunctionDeclaration> memberStaticFactories;
  final AbstractFunctionDeclaration visit;
  final AbstractFunctionDeclaration visitCata;

  final List<FunctionDeclaration> functions;
  final List<AcessorDeclaration> acessors;
  final List<FieldDeclaration> fields;

  UnionClass({
    @required this.comment,
    @required this.className,
    @required this.modifiers,
    @required this.memberStaticFactories,
    @required this.visit,
    @required this.visitCata,
    @required this.functions,
    @required this.acessors,
    @required this.fields,
  });

  static AbstractFunctionDeclaration toBuilder(String className) =>
      AbstractFunctionDeclaration(FunctionDeclarationPrelude(
          FunctionParameters.empty(),
          'toBuilder',
          QualifiedType.fromName('${className}Builder'),
          false));
  static AbstractFunctionDeclaration rebuild(String className) =>
      AbstractFunctionDeclaration(FunctionDeclarationPrelude(
          FunctionParameters(TypeParamList.empty(), [
            PositionalRequiredFunctionParameter(
                FunctionType(TypeParamList.empty(), QualifiedType.voidType,
                    [QualifiedType.fromName('${className}Builder')], [], {}),
                'updates',
                false,
                [])
          ], [], []),
          'rebuild',
          QualifiedType.fromName(className),
          false));
  static AbstractFunctionDeclaration toJson() =>
      AbstractFunctionDeclaration(FunctionDeclarationPrelude(
          FunctionParameters.empty(),
          'toJson',
          QualifiedType.mapStringDynamic,
          false));
  String get additionalBody => '''
      ${memberStaticFactories.map((e) => e.toSource()).join('\n')}

      $_kBuiltToBuilderComment
      ${toBuilder(className).toSource()}

      $_kBuiltRebuildComment
      ${rebuild(className).toSource()}

      /// Visit every member of the union [$className]. Prefer this over explicit
      /// `as` checks because it is exaustive, therefore safer.
      ${visit.toSource()}

      /// Visit and destructure every member of the union [$className]. Prefer
      /// this over explicit `as` checks because it is exaustive, therefore
      /// safer.
      ${visitCata.toSource()}

      /// Serialize an [$className] to an json object.
      ${toJson().toSource()}
''';
  Iterable<String> get annotations => ['@BuiltValue(instantiable: false)'];
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
