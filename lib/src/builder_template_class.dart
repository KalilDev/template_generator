import 'package:source_gen/source_gen.dart';
import 'package:template_generator/src/template_class.dart';

import 'utils.dart';

import 'package:analyzer/dart/ast/ast.dart' as ast;

import 'package:analyzer/dart/element/element.dart' as el;
import 'package:analyzer/dart/element/type.dart' as t;
import 'package:analyzer/src/dart/element/element.dart' as el_impl;
import 'package:tuple/tuple.dart';

class BuilderTemplateClassFactory extends CodeBuilder {
  TemplateClassFactory templateFactory;
  ConstantReader builderTemplateAnnotation;
  el.ClassElement cls;

  get demangledClassName => null;

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
  Code build() {
    // TODO: implement build
    throw UnimplementedError();
  }
}

class BuilderTemplateClass extends Code {
  @override
  String toSource() {
    // TODO: implement toSource
    throw UnimplementedError();
  }

  @override
  void visitTypes(TypeVisitor v) {
    // TODO: implement visitTypes
  }
}
