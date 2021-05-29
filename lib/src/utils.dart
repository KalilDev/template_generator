import 'dart:developer';

import 'package:analyzer/dart/ast/ast.dart' as ast;

import 'package:analyzer/dart/element/element.dart' as el;
import 'package:analyzer/dart/element/type.dart' as t;
import 'package:analyzer/src/dart/element/element.dart' as el_impl;
import 'package:analyzer/src/dart/ast/ast.dart' as ast_impl;
import 'package:hive/hive.dart';
import 'package:source_gen/source_gen.dart';
import 'package:template_annotation/template_annotation.dart';
import 'package:tuple/tuple.dart';
import 'package:analyzer/dart/ast/token.dart' as token;
import 'package:collection/collection.dart';

extension Pipe<T> on T {
  R pipe<R>(R Function(T) fn) => fn(this);
}

Never failWith(String message) => throw StateError(message);
void verify(bool condition, String message) =>
    condition ? null : failWith(message);

void verifyFn(bool condition, String Function() message) =>
    condition ? null : failWith(message());

Tuple2<bool, String Function()> failureMessageFor(
  Iterable<Object> errors, {
  String errorFormat = '{}',
  String format = 'Fix the following mistakes:\n...{}',
}) =>
    Tuple2(
      errors?.isEmpty ?? false,
      () => errors
          .map((e) => e.toString())
          .map((e) => errorFormat.replaceAll('{}', e))
          .pipe((es) => StringBuffer()..writeAll(es, '\n'))
          .pipe((buff) => buff.toString())
          .pipe((es) => format.replaceAll('...{}', es)),
    );

void collectFailures(
  Iterable<Object> errors, {
  String errorFormat = '{}',
  String format = 'Fix the following mistakes:\n...{}',
}) =>
    failureMessageFor(
      errors,
      errorFormat: errorFormat,
      format: format,
    ).pipe((e) => verifyFn(
          e.item1,
          e.item2,
        ));

abstract class CodeBuilder {
  Code build();
}

abstract class TypeVisitor {
  void visitTypeParam(TypeParam p);
  void visitParameterizedType(ParameterizedType p);
  void visitFunctionType(FunctionType p);
}

String _codeFromElement(el.Element e) => e.isSynthetic
    ? null
    : (e as el_impl.ElementImpl).pipe((e) => e.source.contents.data.substring(
          e.codeOffset,
          e.codeLength,
        ));
mixin _AnnotatedCode {
  List<String> annotations = [];
  void annsFromElement(el.Element e) => annotations = e.metadata
      .cast<el_impl.ElementAnnotationImpl>()
      .map((e) => e.annotationAst)
      .map((e) => e.toSource())
      .toList();
}

mixin _DocumentatedCode {
  String documentation;
  void docFromElement(el.Element e) => documentation = e.documentationComment;
}

abstract class AnnotatedCode implements Code {
  List<String> get annotations;
  set annotations(List<String> v);
}

abstract class DocumentedCode implements Code {
  String get documentation;
  set documentation(String v);
}

abstract class Code {
  String toSource();
  void visitTypes(TypeVisitor v);
}

class TypeParam implements NormalType {
  final String name;
  final QualifiedType constraint;

  TypeParam(this.name, this.constraint);
  factory TypeParam.fromElement(el.TypeParameterElement e) {
    final name = e.name;
    final constraint =
        e.bound == null ? null : QualifiedType.fromDartType(e.bound);
    return TypeParam(name, constraint);
  }
  factory TypeParam.fromAst(ast.TypeParameter e) {
    final name = e.name.name;
    final constraint = e.bound == null ? null : QualifiedType.fromAst(e.bound);
    return TypeParam(name, constraint);
  }
  @override
  String toSource() {
    if (constraint == null) {
      return name;
    }
    return '$name extends ${constraint.toSource()}';
  }

  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is TypeParam) {
      return name == other.name && constraint == other.constraint;
    }

    return false;
  }

  int get hashCode => _multiHash([
        name,
        constraint,
      ]);
  QualifiedType toArgument() => QualifiedType.fromName(name);

  @override
  void visitTypes(TypeVisitor v) {
    v.visitTypeParam(this);
    constraint?.visitTypes(v);
  }
}

class TypeParamList implements Code {
  final List<TypeParam> params;

  TypeParamList(this.params);
  factory TypeParamList.empty() => TypeParamList([]);

  @override
  String toSource() {
    if (params.isEmpty) {
      return '';
    }
    return '<${params.map((p) => p.toSource()).join(', ')}>';
  }

  static final _iterableEquality = IterableEquality<TypeParam>();
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is TypeParamList) {
      return _iterableEquality.equals(params, other.params);
    }

    return false;
  }

  int get hashCode => params.pipe(_multiHash);
  TypeArgumentList toArguments() =>
      TypeArgumentList(params.map((e) => e.toArgument()).toList());

  @override
  void visitTypes(TypeVisitor v) => params.visitAllWith(v);
}

class TypeArgumentList implements Code {
  final List<QualifiedType> arguments;

  TypeArgumentList(this.arguments);
  factory TypeArgumentList.empty() => TypeArgumentList([]);
  static final _iterableEquality = IterableEquality<QualifiedType>();
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is TypeArgumentList) {
      return _iterableEquality.equals(arguments, other.arguments);
    }

    return false;
  }

  int get hashCode => arguments.pipe(_multiHash);
  @override
  String toSource() {
    if (arguments.isEmpty) {
      return '';
    }
    return '<${arguments.map((p) => p.toSource()).join(', ')}>';
  }

  @override
  void visitTypes(TypeVisitor v) => arguments.visitAllWith(v);
}

class UnresolvableTypeException = Object with Exception;

class QualifiedTypeError extends Error {
  final String message;

  QualifiedTypeError(this.message);

  QualifiedTypeError withContext(String context) =>
      QualifiedTypeError('$message on $context');

  String toString() => '$runtimeType: $message';
}

abstract class NormalType implements Code {}

abstract class QualifiedType implements NormalType {
  static final mapStringDynamic = ParameterizedType(
      TypeArgumentList([
        string,
        dynamic,
      ]),
      'Map');
  static final string = QualifiedType.fromName('String');
  static final dynamic = QualifiedType.fromName('dynamic');
  static final voidType = QualifiedType.fromName('void');
  factory QualifiedType.fromDartType(t.DartType dartType,
      [bool allowsDynamic = false]) {
    if (dartType == null) {
      return null;
    }
    if (dartType is t.FunctionType) {
      return FunctionType.fromDartType(dartType, true, true);
    }
    if (dartType is t.ParameterizedType) {
      return ParameterizedType.fromDartType(dartType, true);
    }
    if (dartType.isVoid) {
      return QualifiedType.fromName('void');
    }
    // idk..
    if (dartType.isDynamic) {
      return allowsDynamic
          ? QualifiedType.fromName('dynamic')
          : throw QualifiedTypeError('dynamic is not allowed');
    }
    if (dartType.element == null) {
      throw UnresolvableTypeException();
    }
    return QualifiedType.fromName(dartType.element.name);
  }
  factory QualifiedType.fromName(String name) {
    return ParameterizedType(TypeArgumentList(const []), name);
  }
  factory QualifiedType.fromAst(ast.TypeAnnotation typeAnnotation) {
    if (typeAnnotation == null) {
      return null;
    }

    if (typeAnnotation is ast.GenericFunctionType) {
      return FunctionType.fromAst(typeAnnotation);
    }
    if (typeAnnotation is ast.NamedType) {
      if (typeAnnotation.typeArguments?.arguments?.isNotEmpty ?? false) {
        return ParameterizedType.fromAst(typeAnnotation);
      }
      return QualifiedType.fromName(typeAnnotation.name.name);
    }
    throw StateError('unreachable');
  }
  factory QualifiedType.fromAstFormalParameter(ast.FormalParameter param) {
    if (param is ast.FunctionTypedFormalParameter) {
      return FunctionType.fromAstParts(
        param.typeParameters.typeParameters.toList(),
        param.returnType,
        param.parameters.parameters.toList(),
      );
    }
    if (param is ast.FieldFormalParameter) {
      return QualifiedType.fromAst(param.type);
    }
    if (param is ast.SimpleFormalParameter) {
      return QualifiedType.fromAst(param.type);
    }
    if (param is ast.DefaultFormalParameter) {
      return QualifiedType.fromAstFormalParameter(param.parameter);
    }
    throw StateError('unreachable');
  }
}

int _multiHash(Iterable<Object> objs) =>
    objs.fold(7, (acc, obj) => 31 * acc + obj.hashCode);

class ParameterizedType implements QualifiedType {
  final TypeArgumentList typeArguments;
  String type;

  ParameterizedType(this.typeArguments, this.type);
  factory ParameterizedType.fromDartType(t.ParameterizedType dartType,
      [bool allowsDynamicParams = true]) {
    return ParameterizedType(
      TypeArgumentList(dartType.typeArguments
          .map((e) => QualifiedType.fromDartType(e, allowsDynamicParams))
          .toList()),
      dartType.element.name,
    );
  }
  factory ParameterizedType.fromAst(ast.NamedType typeAnnotation) {
    return ParameterizedType(
      TypeArgumentList(typeAnnotation.typeArguments.arguments
          .map((e) => QualifiedType.fromAst(e))
          .toList()),
      typeAnnotation.name.name,
    );
  }
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is ParameterizedType) {
      return type == other.type && typeArguments == other.typeArguments;
    }

    return false;
  }

  int get hashCode => _multiHash([type, typeArguments]);

  @override
  String toSource() =>
      '${type ?? 'dynamic'}' '${typeArguments?.toSource() ?? ''}';

  @override
  void visitTypes(TypeVisitor v) {
    v.visitParameterizedType(this);
    typeArguments?.visitTypes(v);
  }
}

class FunctionType implements QualifiedType {
  final TypeParamList typeParams;
  final QualifiedType returnType;
  final List<QualifiedType> positionalParams;
  final List<QualifiedType> optionalPositionalParams;
  final Map<String, QualifiedType> namedParams;

  FunctionType(this.typeParams, this.returnType, this.positionalParams,
      this.optionalPositionalParams, this.namedParams);
  factory FunctionType.fromDartType(t.FunctionType dartType,
      [bool allowsDynamicReturn = true, bool allowsDynamicParams = true]) {
    final typeParams =
        dartType.typeFormals.map((e) => TypeParam.fromElement(e)).toList();
    return FunctionType(
      TypeParamList(typeParams),
      QualifiedType.fromDartType(dartType.returnType, allowsDynamicReturn),
      dartType.normalParameterTypes
          .map((e) => QualifiedType.fromDartType(e, allowsDynamicParams))
          .toList(),
      dartType.optionalParameterTypes
          .map((e) => QualifiedType.fromDartType(e, allowsDynamicParams))
          .toList(),
      dartType.namedParameterTypes.map((k, v) =>
          MapEntry(k, QualifiedType.fromDartType(v, allowsDynamicParams))),
    );
  }
  static final _iterableEquality = IterableEquality<QualifiedType>();
  static final _mapEquality = MapEquality<String, QualifiedType>();
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is FunctionType) {
      return _mapEquality.equals(namedParams, other.namedParams) &&
          _iterableEquality.equals(
              optionalPositionalParams, other.optionalPositionalParams) &&
          _iterableEquality.equals(positionalParams, other.positionalParams) &&
          returnType == other.returnType &&
          typeParams == other.typeParams;
    }

    return false;
  }

  int get hashCode => _multiHash([
        namedParams.entries.bind((e) => [e.key, e.value]).pipe(_multiHash),
        optionalPositionalParams.pipe(_multiHash),
        positionalParams.pipe(_multiHash),
        returnType,
        typeParams,
      ]);

  static QualifiedType _formalParamType(ast.FormalParameter p) =>
      QualifiedType.fromAstFormalParameter(p);

  factory FunctionType.fromAstParts(
    List<ast.TypeParameter> typeParameters,
    ast.TypeAnnotation returnType,
    List<ast.FormalParameter> parameters,
  ) {
    return FunctionType(
      TypeParamList(typeParameters.map((e) => TypeParam.fromAst(e)).toList()),
      QualifiedType.fromAst(returnType),
      parameters
          .where((e) => e.isRequiredPositional)
          .map(_formalParamType)
          .toList(),
      parameters
          .where((e) => e.isOptionalPositional)
          .map(_formalParamType)
          .toList(),
      Map.fromEntries(
          parameters.where((e) => e.isRequiredNamed || e.isOptionalNamed).map(
                (e) => MapEntry(e.identifier.name, _formalParamType(e)),
              )),
    );
  }
  factory FunctionType.fromAst(ast.GenericFunctionType typeAnnotation) {
    return FunctionType.fromAstParts(
      typeAnnotation.typeParameters?.typeParameters?.toList() ?? [],
      typeAnnotation.returnType,
      typeAnnotation.parameters.parameters.toList(),
    );
  }

  @override
  String toSource() {
    final r = StringBuffer();
    r
      ..write(returnType.toSource())
      ..write(' ')
      ..write('Function')
      ..write(typeParams.toSource())
      ..write('(')
      ..writeAll(
          positionalParams.map((e) => e.toSource()).followedBy(['']), ', ');
    if (optionalPositionalParams.isNotEmpty) {
      r
        ..write('[')
        ..writeAll(
            optionalPositionalParams.map((e) => e.toSource()).followedBy(['']),
            ', ')
        ..write(']');
    }
    if (namedParams.isNotEmpty) {
      r
        ..write('{')
        ..writeAll(
            namedParams.entries
                .map((e) => '${e.value.toSource()} ${e.key}')
                .followedBy(['']),
            ', ')
        ..write('}');
    }
    r..write(')');
    return r.toString();
  }

  @override
  void visitTypes(TypeVisitor v) {
    v.visitFunctionType(this);
    returnType?.visitTypes(v);
    positionalParams.visitAllWith(v);
    optionalPositionalParams.visitAllWith(v);
    namedParams.values.visitAllWith(v);
  }
}

class Reference implements Code {
  final QualifiedType type;
  final String name;

  Reference(this.type, this.name);
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is Reference) {
      return type == other.type && name == other.name;
    }

    return false;
  }

  int get hashCode => _multiHash([
        type,
        name,
      ]);
  @override
  String toSource() => '${type?.toSource() ?? ''} $name';

  @override
  void visitTypes(TypeVisitor v) => type?.visitTypes(v);
}

abstract class CovariantReference implements Reference {
  QualifiedType get type;
  String get name;
  bool get isCovariant;
}

abstract class FunctionParameter implements CovariantReference {
  List<String> get annotations;
}

abstract class FunctionParameterWithDefault implements FunctionParameter {
  String get defaultValue;
}

class PositionalRequiredFunctionParameter implements FunctionParameter {
  final QualifiedType type;
  final String name;
  final bool isCovariant;
  final List<String> annotations;

  PositionalRequiredFunctionParameter(
    this.type,
    this.name,
    this.isCovariant,
    this.annotations,
  );
  factory PositionalRequiredFunctionParameter.fromElement(el.ParameterElement e,
      [bool fallbackToAstType = true, bool allowsDynamic = false]) {
    return PositionalRequiredFunctionParameter(
      _typeForParameterElement(e, fallbackToAstType, allowsDynamic),
      e.name,
      e.isCovariant,
      e.metadata.map((e) => e.toSource()).toList(),
    );
  }

  @override
  String toSource() {
    final r = StringBuffer();
    r
      ..writeAll(annotations ?? [], ' ')
      ..write(isCovariant ? 'covariant ' : '')
      ..write(type?.toSource() ?? 'dynamic')
      ..write(' ')
      ..write(name);
    return r.toString();
  }

  @override
  void visitTypes(TypeVisitor v) => type?.visitTypes(v);
}

class PositionalOptionalFunctionParameter
    implements FunctionParameterWithDefault {
  final QualifiedType type;
  final String name;
  final bool isCovariant;
  final List<String> annotations;
  final String defaultValue;

  PositionalOptionalFunctionParameter(
    this.type,
    this.name,
    this.isCovariant,
    this.annotations,
    this.defaultValue,
  );
  factory PositionalOptionalFunctionParameter.fromElement(el.ParameterElement e,
      [bool fallbackToAstType = true, bool allowsDynamic = false]) {
    return PositionalOptionalFunctionParameter(
      _typeForParameterElement(e, fallbackToAstType, allowsDynamic),
      e.name,
      e.isCovariant,
      e.metadata.map((e) => e.toSource()).toList(),
      e.defaultValueCode,
    );
  }

  @override
  String toSource() {
    final r = StringBuffer();
    r
      ..writeAll(annotations ?? [], ' ')
      ..write(isCovariant ? 'covariant ' : '')
      ..write(type?.toSource() ?? 'dynamic')
      ..write(' ')
      ..write(name);
    if (defaultValue != null && defaultValue.isNotEmpty) {
      r..write(' = ')..write(defaultValue);
    }
    return r.toString();
  }

  @override
  void visitTypes(TypeVisitor v) => type?.visitTypes(v);
}

QualifiedType _typeForParameterElement(
    el.ParameterElement e, bool fallbackToAstType, bool allowsDynamic) {
  QualifiedType type;
  if (fallbackToAstType) {
    final el = e as el_impl.ParameterElementImpl;
    final node = el.linkedNode as ast.FormalParameter;

    type = node == null ? null : QualifiedType.fromAstFormalParameter(node);
  }
  type ??= QualifiedType.fromDartType(e.type, allowsDynamic);
  return type;
}

class NamedFunctionParameter implements FunctionParameterWithDefault {
  final QualifiedType type;
  final String name;
  final bool isCovariant;
  final List<String> annotations;
  final String defaultValue;
  final bool required;

  NamedFunctionParameter(
    this.type,
    this.name,
    this.isCovariant,
    this.annotations,
    this.defaultValue,
    this.required,
  );

  factory NamedFunctionParameter.fromElement(el.ParameterElement e,
      [bool fallbackToAstType = true, bool allowsDynamic = false]) {
    return NamedFunctionParameter(
      _typeForParameterElement(e, fallbackToAstType, allowsDynamic),
      e.name,
      e.isCovariant,
      e.metadata.map((e) => e.toSource()).toList(),
      e.defaultValueCode,
      e.isRequiredNamed,
    );
  }

  @override
  @override
  String toSource() {
    final r = StringBuffer();
    r
      ..writeAll(annotations ?? [], ' ')
      ..write(required ? '@required ' : '')
      ..write(isCovariant ? 'covariant ' : '')
      ..write(type?.toSource() ?? 'dynamic')
      ..write(' ')
      ..write(name);
    if (defaultValue != null && defaultValue.isNotEmpty) {
      r..write(' = ')..write(defaultValue);
    }
    return r.toString();
  }

  @override
  void visitTypes(TypeVisitor v) => type?.visitTypes(v);
}

class FunctionParameters implements Code {
  final TypeParamList typeParams;
  final List<PositionalRequiredFunctionParameter> normal;
  final List<PositionalOptionalFunctionParameter> optional;
  final List<NamedFunctionParameter> named;

  FunctionParameters(
    this.typeParams,
    this.normal,
    this.optional,
    this.named,
  );
  factory FunctionParameters.empty() =>
      FunctionParameters(TypeParamList([]), [], [], []);
  factory FunctionParameters.fromElement(el.ExecutableElement element) {
    /// [element] is an [el.FunctionElement], [el.PropertyAccessorElement], or
    /// [el.MethodElement].
    try {
      return FunctionParameters(
        TypeParamList(element.typeParameters
            .map((e) => TypeParam.fromElement(e))
            .toList()),
        element.parameters
            .where((e) => e.isRequiredPositional)
            .map((e) => PositionalRequiredFunctionParameter.fromElement(e))
            .toList(),
        element.parameters
            .where((e) => e.isOptionalPositional)
            .map((e) => PositionalOptionalFunctionParameter.fromElement(e))
            .toList(),
        element.parameters
            .where((e) => e.isNamed)
            .map((e) => NamedFunctionParameter.fromElement(e))
            .toList(),
      );
    } on QualifiedTypeError catch (e) {
      throw e.withContext('FunctionParameter.fromElement(${element.location})');
    }
  }
  String toApplicationSource({bool typeArgumentsAlso = true}) {
    final r = StringBuffer();
    r
      ..write(typeArgumentsAlso ? typeParams.toSource() : '')
      ..write('(')
      ..writeAll(normal.map((e) => e.name).followedBy(['']), ', ');
    if (optional.isNotEmpty) {
      r.writeAll(optional.map((e) => e.name).followedBy(['']), ', ');
    }
    if (named.isNotEmpty) {
      final entries = named.map((e) => e.name);
      r.writeAll(entries.map((e) => '$e: $e').followedBy(['']), ', ');
    }
    r..write(')');
    return r.toString();
  }

  @override
  String toSource({bool typeArgumentsAlso = true}) {
    final r = StringBuffer();
    r
      ..write(typeArgumentsAlso ? typeParams.toSource() : '')
      ..write('(')
      ..writeAll(normal.map((e) => e.toSource()).followedBy(['']), ', ');
    if (optional.isNotEmpty) {
      r
        ..write('[')
        ..writeAll(optional.map((e) => e.toSource()).followedBy(['']), ', ')
        ..write(']');
    }
    if (named.isNotEmpty) {
      r
        ..write('{')
        ..writeAll(named.map((e) => e.toSource()).followedBy(['']), ', ')
        ..write('}');
    }
    r..write(')');
    return r.toString();
  }

  @override
  void visitTypes(TypeVisitor v) {
    typeParams?.visitTypes(v);
    normal.visitAllWith(v);
    optional.visitAllWith(v);
    named.visitAllWith(v);
  }
}

abstract class FunctionBody implements Code {
  // sync*, async*, async or null/empty
  String get qualifier;
  factory FunctionBody.fromAst(ast.FunctionBody body) {
    if (body == null) {
      return null;
    }
    String qualifier;
    if (body.isAsynchronous) {
      qualifier = 'async${body.star != null ? '*' : ''}';
    } else if (body.isGenerator) {
      qualifier = 'sync*';
    }
    if (body is ast.EmptyFunctionBody) {
      return null;
    }
    if (body is ast.BlockFunctionBody) {
      return FunctionBlockBody(
          qualifier, codeInsideBrackets(body.block.toSource()));
    }
    if (body is ast.ExpressionFunctionBody) {
      return FunctionArrowBody(qualifier, codeInsideArrow(body.toSource()));
    }
    throw TypeError();
  }
}

String codeInsideBrackets(String code) {
  final a = code.indexOf('{');
  final b = code.lastIndexOf('}');
  return code.substring(a, b);
}

String codeInsideArrow(String code) {
  final a = code.indexOf('=>');
  final b = code.lastIndexOf(';');
  return code.substring(a + 2, b);
}

class FunctionArrowBody implements FunctionBody {
  final String qualifier;
  final String code;

  FunctionArrowBody(
    this.qualifier,
    this.code,
  );
  @override
  String toSource() => '${qualifier ?? ''} => $code;';

  @override
  void visitTypes(TypeVisitor v) => null;
}

class FunctionBlockBody implements FunctionBody {
  final String qualifier;
  final String code;

  FunctionBlockBody(
    this.qualifier,
    this.code,
  );
  @override
  String toSource() => '''
  ${qualifier ?? ''} {
    $code
  }
  ''';
  @override
  void visitTypes(TypeVisitor v) => null;
}

abstract class AcessorDeclaration
    with _AnnotatedCode, _DocumentatedCode
    implements Code, AnnotatedCode, DocumentedCode {
  QualifiedType get type;
  String get name;
  bool get isStatic;
  FunctionBody get body;
  bool get isAbstract => body == null;
  AcessorDeclaration();

  factory AcessorDeclaration.fromElement(el.PropertyAccessorElement element) {
    try {
      final acessor = (element as el_impl.PropertyAccessorElementImpl)
          .linkedNode as ast.MethodDeclaration;
      return AcessorDeclaration.fromAst(
          acessor, QualifiedType.fromDartType(element.returnType))
        ..annsFromElement(element)
        ..docFromElement(element);
    } on QualifiedTypeError catch (e) {
      throw e
          .withContext('AcessorDeclaration.fromElement(${element.location})');
    }
  }
  factory AcessorDeclaration.fromAst(ast.MethodDeclaration acessor,
      [QualifiedType fallbackType]) {
    if (acessor.isSynthetic) {
      return null;
    }
    if (!acessor.isSetter && !acessor.isGetter) {
      throw StateError(
          'Acessor declarations can only be created from acessors!');
    }
    if (acessor.isSetter) {
      var param = acessor.parameters.parameters.single;
      param = param is ast.DefaultFormalParameter ? param.parameter : param;
      String name;

      final type = QualifiedType.fromAstFormalParameter(param);

      if (param is ast.FunctionTypedFormalParameter) {
        name = param.identifier.name;
      } else if (param is ast.FieldFormalParameter) {
        name = param.identifier.name;
      } else if (param is ast.SimpleFormalParameter) {
        name = param.identifier.name;
      } else {
        throw TypeError();
      }
      return SetterDeclaration(
        Reference(type ?? fallbackType, name),
        acessor.isStatic,
        acessor.name.name,
        FunctionBody.fromAst(acessor.body),
      );
    } else {
      return GetterDeclaration(
        QualifiedType.fromAst(acessor.returnType) ?? fallbackType,
        acessor.isStatic,
        acessor.name.name,
        FunctionBody.fromAst(acessor.body),
      );
    }
  }
}

class SetterDeclaration extends AcessorDeclaration {
  final Reference argument;
  final bool isStatic;
  final String name;
  final FunctionBody body;

  SetterDeclaration(this.argument, this.isStatic, this.name, this.body);
  QualifiedType get type => argument.type;

  @override
  String toSource() =>
      '''${documentation ?? ''}\n${annotations.join('\n')}\n${isStatic ? 'static ' : ' '} set $name(${argument.toSource()}) ${body?.toSource() ?? ';'}''';

  @override
  void visitTypes(TypeVisitor v) => argument?.visitTypes(v);
}

class GetterDeclaration extends AcessorDeclaration {
  final QualifiedType type;
  final bool isStatic;
  final String name;
  final FunctionBody body;

  GetterDeclaration(this.type, this.isStatic, this.name, this.body);

  @override
  String toSource() =>
      '''${documentation ?? ''}\n${annotations.join('\n')}\n${isStatic ? 'static ' : ' '} ${type?.toSource() ?? ""} get $name ${body?.toSource() ?? ';'}''';
  @override
  void visitTypes(TypeVisitor v) => type?.visitTypes(v);
}

abstract class FactoryDeclaration
    implements Code, AnnotatedCode, DocumentedCode {
  FunctionParameters get parameters;
  String get className;
  String get name;
}

class RedirectingFactoryDeclaration
    with _AnnotatedCode, _DocumentatedCode
    implements FactoryDeclaration {
  final FunctionParameters parameters;
  final String className;
  final String name;
  final String targetFactoryName;
  final bool isConst;

  RedirectingFactoryDeclaration(this.parameters, this.name, this.className,
      this.targetFactoryName, this.isConst);

  String get factoryName {
    if (name == null || name.isEmpty) {
      return className;
    }
    return '$className.$name';
  }

  @override
  String toSource() =>
      '${documentation ?? ''}\n${annotations.join('\n')}\n${isConst ? 'const ' : ''}factory $factoryName${parameters.toSource(typeArgumentsAlso: false)} = $targetFactoryName${parameters.typeParams.toSource()};';

  @override
  void visitTypes(TypeVisitor v) {
    parameters?.visitTypes(v);
  }
}

class ConcreteFactoryDeclaration
    with _AnnotatedCode, _DocumentatedCode
    implements FactoryDeclaration {
  final FunctionParameters parameters;
  final String className;
  final String name;
  final FunctionBody body;

  ConcreteFactoryDeclaration(
      this.parameters, this.className, this.name, this.body);

  String get factoryName {
    if (name == null || name.isEmpty) {
      return className;
    }
    return '$className.$name';
  }

  @override
  String toSource() =>
      '${documentation ?? ''}\n${annotations.join('\n')}\nfactory $factoryName${parameters.toSource(typeArgumentsAlso: false)} ${body.toSource()}';

  @override
  void visitTypes(TypeVisitor v) {
    parameters?.visitTypes(v);
  }
}

abstract class FunctionDeclaration
    implements Code, DocumentedCode, AnnotatedCode {
  FunctionDeclarationPrelude get prelude;

  factory FunctionDeclaration.fromElement(el.ExecutableElement element) {
    try {
      final prelude = FunctionDeclarationPrelude.fromElement(element);
      if (element.isAbstract) {
        return AbstractFunctionDeclaration(prelude);
      }
      FunctionBody body;
      if (element is el_impl.FunctionElementImpl) {
        final node = element.linkedNode as ast.FunctionDeclaration;
        body = FunctionBody.fromAst(node.functionExpression.body);
      } else if (element is el_impl.MethodElementImpl) {
        final node = element.linkedNode as ast.MethodDeclaration;
        body = FunctionBody.fromAst(node.body);
      } else {
        throw TypeError();
      }
      return ConcreteFunctionDeclaration(prelude, body);
    } on QualifiedTypeError catch (e) {
      throw e
          .withContext('FunctionDeclaration.fromElement(${element.location})');
    }
  }
}

class ConcreteFunctionDeclaration implements FunctionDeclaration {
  final FunctionDeclarationPrelude prelude;
  final FunctionBody body;

  ConcreteFunctionDeclaration(this.prelude, this.body);

  @override
  String toSource() =>
      '${documentation ?? ''}\n${annotations.join('\n')}\n${prelude.toSource()} ${body.toSource()}';
  @override
  void visitTypes(TypeVisitor v) => prelude?.visitTypes(v);

  @override
  List<String> get annotations => prelude.annotations;

  set annotations(List<String> annotations) =>
      prelude.annotations = annotations;

  @override
  String get documentation => prelude.documentation;

  set documentation(String documentation) =>
      prelude.documentation = documentation;
}

class AbstractFunctionDeclaration implements FunctionDeclaration {
  final FunctionDeclarationPrelude prelude;

  AbstractFunctionDeclaration(this.prelude);

  @override
  String toSource() =>
      '${documentation ?? ''}\n${annotations.join('\n')}\n${prelude.toSource()};';
  @override
  void visitTypes(TypeVisitor v) => prelude?.visitTypes(v);

  @override
  List<String> get annotations => prelude.annotations;

  set annotations(List<String> annotations) =>
      prelude.annotations = annotations;

  @override
  String get documentation => prelude.documentation;

  set documentation(String documentation) =>
      prelude.documentation = documentation;
}

class FunctionDeclarationPrelude
    with _AnnotatedCode, _DocumentatedCode
    implements Code {
  final FunctionParameters parameters;
  final String name;
  final QualifiedType returnType;
  final bool isStatic;
  FunctionDeclarationPrelude(
      this.parameters, this.name, this.returnType, this.isStatic);

  factory FunctionDeclarationPrelude.fromElement(
    el.ExecutableElement element, {
    bool returnTypeFromAst = true,
    bool allowsDynamicReturn = false,
  }) {
    /// [element] is an [el.FunctionElement], [el.PropertyAccessorElement], or
    /// [el.MethodElement].
    QualifiedType returnType;
    if (element is el_impl.FunctionElementImpl) {
      final node = element.linkedNode as ast.FunctionDeclaration;
      returnType = QualifiedType.fromAst(node?.returnType);
    }
    if (element is el_impl.MethodElementImpl) {
      final node = element.linkedNode as ast.MethodDeclaration;
      returnType = QualifiedType.fromAst(node?.returnType);
    }
    try {
      returnType ??= QualifiedType.fromDartType(element.returnType, false);
    } on QualifiedTypeError catch (e) {
      print(e);
      /*throw e.withContext(
          'FunctionDeclarationPrelude.fromElement(${element.location})');*/
    }
    return FunctionDeclarationPrelude(
      FunctionParameters.fromElement(element),
      element.name,
      returnType,
      element.isStatic,
    )
      ..annsFromElement(element)
      ..docFromElement(element);
  }
  @override
  String toSource({bool typeArgumentsAlso = true}) =>
      '${isStatic ? 'static ' : ''}${returnType?.toSource() ?? ''} $name${parameters?.toSource()}';

  @override
  void visitTypes(TypeVisitor v) {
    returnType?.visitTypes(v);
    parameters?.visitTypes(v);
  }
}

class ClassModifiers implements Code {
  final TypeParamList typeParams;
  final QualifiedType superType;
  final List<QualifiedType> implemented;
  final List<QualifiedType> mixed;

  ClassModifiers(
    this.typeParams,
    this.superType,
    this.implemented,
    this.mixed,
  );
  factory ClassModifiers.fromElement(
    el.ClassElement cls, {
    bool typesFromAst = true,
  }) {
    try {
      final typeParams = TypeParamList(cls.typeParameters //
          .map((e) => TypeParam.fromElement(e))
          .toList());
      QualifiedType superType;
      final implemented = <QualifiedType>[];
      final mixed = <QualifiedType>[];
      if (typesFromAst) {
        final node = (cls as el_impl.ClassElementImpl).linkedNode
            as ast.ClassOrMixinDeclaration;
        implemented.addAll(node?.implementsClause?.interfaces
                ?.map((e) => QualifiedType.fromAst(e)) ??
            []);
        final maybeClassNode = node is ast.ClassDeclaration ? node : null;
        superType =
            QualifiedType.fromAst(maybeClassNode?.extendsClause?.superclass);
        mixed.addAll(maybeClassNode?.withClause?.mixinTypes
                ?.map((e) => QualifiedType.fromAst(e)) ??
            []);
      } else {
        final t = cls.thisType;
        superType = QualifiedType.fromDartType(t.superclass);
        implemented
            .addAll(t.interfaces.map((e) => QualifiedType.fromDartType(e)));
        mixed.addAll(t.mixins.map((e) => QualifiedType.fromDartType(e)));
      }
      return ClassModifiers(
        typeParams,
        superType,
        implemented,
        mixed,
      );
    } on QualifiedTypeError catch (e) {
      throw e.withContext('ClassModifiers.fromElement(${cls.location})');
    }
  }

  @override
  String toSource() {
    final b = StringBuffer();
    b..write(typeParams.toSource())..write(' ');
    if (superType != null) {
      b.write('extends ${superType.toSource()} ');
    }
    if (mixed.isNotEmpty) {
      b
        ..write('with ')
        ..writeAll(mixed.map((e) => e.toSource()), ', ')
        ..write(' ');
    }
    if (implemented.isNotEmpty) {
      b
        ..write('implements ')
        ..writeAll(implemented.map((e) => e.toSource()), ', ')
        ..write(' ');
    }
    return b.toString();
  }

  @override
  void visitTypes(TypeVisitor v) {
    typeParams?.visitTypes(v);
    superType?.visitTypes(v);
    implemented.visitAllWith(v);
    mixed.visitAllWith(v);
  }
}

enum FieldAcessModifier {
  Final,
  Const,
  Var,
}

class FieldDeclaration
    with _AnnotatedCode, _DocumentatedCode
    implements Code, AnnotatedCode, DocumentedCode {
  final bool isStatic;
  final FieldAcessModifier modifier;
  final Reference reference;
  final String defaultValue;

  FieldDeclaration(
      this.isStatic, this.modifier, this.reference, this.defaultValue);

  factory FieldDeclaration.fromElement(el.FieldElement el) {
    try {
      final element = el as el_impl.FieldElementImpl;
      final variable = element.linkedNode as ast.VariableDeclaration;
      final field = variable.parent.parent as ast.FieldDeclaration;
      final isStatic = element.isStatic;
      final modifier = element.isConst
          ? FieldAcessModifier.Const
          : element.isFinal
              ? FieldAcessModifier.Final
              : null;
      var type = QualifiedType.fromAst(field.fields.type);
      type ??= QualifiedType.fromDartType(el.type);
      return FieldDeclaration(isStatic, modifier, Reference(type, element.name),
          variable.initializer?.toSource())
        ..annsFromElement(element)
        ..docFromElement(element);
    } on QualifiedTypeError catch (e) {
      throw e.withContext('FieldDeclaration.fromElement(${el.location})');
    }
  }

  String get modifierString {
    switch (modifier) {
      case FieldAcessModifier.Final:
        return 'final';
      case FieldAcessModifier.Const:
        return 'const';
      case FieldAcessModifier.Var:
        return 'var';
      default:
        return '';
    }
  }

  List<AcessorDeclaration> toAcessors([String Function(String p) createRef]) {
    createRef ??= (s) => s;
    final ro = modifier == FieldAcessModifier.Const ||
        modifier == FieldAcessModifier.Final;
    final getter = GetterDeclaration(reference.type, isStatic, reference.name,
        FunctionArrowBody('', createRef(reference.name)));
    final setterParam = 'p${reference.name.pipe(UpperCamelCase)}';
    final setter = SetterDeclaration(
        Reference(reference.type, setterParam),
        isStatic,
        reference.name,
        FunctionArrowBody(null, '${createRef(reference.name)} = $setterParam'))
      ..annotations = annotations.toList()
      ..documentation = documentation;
    return [
      getter,
      if (!ro) setter,
    ];
  }

  @override
  String toSource() =>
      '${isStatic ? 'static ' : ''}$modifierString ${reference.toSource()}${defaultValue == null ? '' : ' = $defaultValue'};';

  @override
  void visitTypes(TypeVisitor v) {
    reference.visitTypes(v);
  }
}

FunctionDeclarationPrelude toJsonPrelude = FunctionDeclarationPrelude(
  FunctionParameters(TypeParamList([]), [], [], []),
  'toJson',
  QualifiedType.mapStringDynamic,
  false,
);

String lowerCamelCase(String s) {
  if (s[0].toLowerCase() != s[0]) {
    return '${s[0].toLowerCase()}${s.substring(1)}';
  }
  return s;
}

String UpperCamelCase(String s) {
  if (s[0].toUpperCase() != s[0]) {
    return '${s[0].toUpperCase()}${s.substring(1)}';
  }
  return s;
}

final Set<TypeChecker> consumedAnnotationCheckers = {
  templateChecker,
  unionChecker,
  constructorChecker,
  builderTemplateChecker,
  mixToChecker,
};
final templateChecker = TypeChecker.fromRuntime(Template);
final unionChecker = TypeChecker.fromRuntime(Union);
final hiveTypeChecker = TypeChecker.fromRuntime(HiveType);
final constructorChecker = TypeChecker.fromRuntime(Constructor);
final builderTemplateChecker = TypeChecker.fromRuntime(BuilderTemplate);
final mixToChecker = TypeChecker.fromRuntime(MixTo);

Iterable<String> bypassedAnnotationsFor(el.Element e) {
  final disallowedAnnotations = consumedAnnotationCheckers.followedBy([
    hiveTypeChecker,
  ]);
  return e.metadata
      .where((e) => !disallowedAnnotations.any(
            (c) => c.isExactlyType(e.computeConstantValue()?.type),
          ))
      .map((e) => e.toSource());
}

String unnamedConstructorFrom(el.ClassElement cls) {
  if (cls.unnamedConstructor == null) {
    return null;
  }
  final ctor = cls.unnamedConstructor as el_impl.ConstructorElementImpl;
  final code = ctor.source.contents.data;

  // The constructor may be synthetic
  if (ctor.codeLength == null || ctor.codeOffset == null) {
    return null;
  }

  final ctorString = code.substring(
    ctor.codeOffset,
    ctor.codeLength + ctor.codeOffset,
  );
  return ctorString;
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

class TypeNameDemangler implements TypeVisitor {
  @override
  void visitFunctionType(FunctionType p) {}

  @override
  void visitParameterizedType(ParameterizedType p) {
    p.type = demangled(p.type);
  }

  @override
  void visitTypeParam(TypeParam p) {}
}

extension VisitAllCode on Iterable<Code> {
  void visitAllWith(TypeVisitor visitor) =>
      forEach((e) => e?.visitTypes(visitor));
}

extension IterableE<T> on Iterable<T> {
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

List<AcessorDeclaration> staticFieldRedirect(
        FieldDeclaration staticField, String sourceClassName) =>
    staticField.toAcessors((fieldName) => '$sourceClassName.$fieldName');

FieldDeclaration staticFunctionRedirect(
  ConcreteFunctionDeclaration staticFunction,
  String sourceClassName,
) =>
    FieldDeclaration(
        true,
        FieldAcessModifier.Const,
        Reference(null, '${staticFunction.prelude.name}'),
        '$sourceClassName.${staticFunction.prelude.name}')
      ..documentation = staticFunction.documentation
      ..annotations = staticFunction.annotations.toList();
