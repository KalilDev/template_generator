import 'package:source_gen/source_gen.dart';
import 'package:template_generator/src/template_class.dart';

import 'class_code_builder.dart';
import 'utils.dart';
import 'package:meta/meta.dart';

import 'package:analyzer/dart/ast/ast.dart' as ast;

import 'package:analyzer/dart/element/element.dart' as el;
import 'package:analyzer/dart/element/type.dart' as t;
import 'package:analyzer/src/dart/element/element.dart' as el_impl;
import 'package:tuple/tuple.dart';

class BuilderTemplateClassFactory extends ClassCodeBuilder {
  TemplateClassFactory templateFactory;
  ConstantReader builderTemplateAnnotation;

  String _defaultClassName() {
    final name = cls.name;
    verify(
        name.endsWith('Builder'),
        'Builder templates must either be named as __TEMPLATEBuilder or '
        'contain the template type in the BuilderTemplate annotation!');
    return name.substring(0, name.indexOf('Builder'));
  }

  String templateClassName() {
    var type = builderTemplateAnnotation.read('templateClass');
    if (type == null || type.isNull) {
      return _defaultClassName();
    }
    return type.typeValue.element.name;
  }

  void addToTemplate(TemplateClassFactory template) {
    templateFactory = template;
  }

  @override
  ClassModifiers get verbatinModifiers {
    final modifiers = super.verbatinModifiers;

    modifiers.implemented.add(ParameterizedType(
        TypeArgumentList([
          ParameterizedType(modifiers.typeParams.toArguments(),
              demangled(templateClassName())),
          ParameterizedType(
              modifiers.typeParams.toArguments(), demangledClassName)
        ]),
        'Builder'));
    if (templateFactory.isUnion) {
      modifiers.implemented.add(QualifiedType.fromName(
          templateFactory.unionFactory.demangledClassName + 'Builder'));
    }
    return modifiers;
  }

  @override
  void addMixinType(QualifiedType mixin) => mixins.add(mixin);

  @override
  final Set<QualifiedType> mixins = {};

  List<AcessorDeclaration> get _acessors => [
        ...cls.fields
            .where((e) => e.isStatic)
            .map((e) => FieldDeclaration.fromElement(e))
            .bind((e) => staticFieldRedirect(e, className)),
      ];
  List<FieldDeclaration> get _fields => [
        ...cls.methods
            .map((e) => FunctionDeclaration.fromElement(e))
            .map((e) => staticFunctionRedirect(e, className)),
        ...cls.fields.map((e) => FieldDeclaration.fromElement(e))
      ];

  @override
  Code build() => BuilderTemplateClass(
        comment: cls.documentationComment,
        className: demangledClassName,
        modifiers: modifiers,
        acessors: _acessors,
        fields: _fields,
      )..visitTypes(TypeNameDemangler());
}

class BuilderTemplateClass extends ClassCode {
  final String comment;

  final String className;
  final ClassModifiers modifiers;

  List<String> get constructors => [
        '$className._();',
      ];
  List<FactoryDeclaration> get factories => [
        RedirectingFactoryDeclaration(
          FunctionParameters.empty(),
          null,
          className,
          '_\$$className',
          false,
        )
      ];

  final List<AcessorDeclaration> acessors;
  final List<FieldDeclaration> fields;

  BuilderTemplateClass({
    @required this.comment,
    @required this.className,
    @required this.modifiers,
    @required this.acessors,
    @required this.fields,
  });
}
