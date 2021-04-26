import 'dart:developer';

import 'package:analyzer/dart/ast/ast.dart' as ast;

import 'package:analyzer/dart/element/element.dart' as el;
import 'package:analyzer/dart/element/type.dart' as t;
import 'package:analyzer/src/dart/element/type.dart' as t_impl;
import 'package:analyzer/src/dart/element/element.dart' as el_impl;
import 'package:tuple/tuple.dart';

abstract class Code {
  String toSource();
}

class TypeParamList implements Code {
  final List<QualifiedType> params;

  TypeParamList(this.params);

  @override
  String toSource() {
    if (params.isEmpty) {
      return '';
    }
    return '<${params.map((p) => p.toSource()).join(', ')}>';
  }
}

class UnresolvableTypeException = Object with Exception;

class QualifiedTypeError extends Error {
  final String message;

  QualifiedTypeError(this.message);

  QualifiedTypeError withContext(String context) =>
      QualifiedTypeError('$message on $context');

  String toString() => '$runtimeType: $message';
}

abstract class QualifiedType implements Code {
  TypeParamList get typeParams;

  factory QualifiedType.fromDartType(t.DartType dartType,
      [bool allowsDynamic = false]) {
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
    return ParameterizedType(TypeParamList(const []), name);
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
    throw StateError("unreachable");
  }
  factory QualifiedType.fromAstTypeParameter(ast.TypeParameter typeParameter) {
    // TODO: constraints
    return QualifiedType.fromName(typeParameter.name.name);
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
    throw StateError("unreachable");
  }
}

class ParameterizedType implements QualifiedType {
  final TypeParamList typeParams;
  final String type;

  ParameterizedType(this.typeParams, this.type);
  factory ParameterizedType.fromDartType(t.ParameterizedType dartType,
      [bool allowsDynamicParams = true]) {
    return ParameterizedType(
      TypeParamList(dartType.typeArguments
          .map((e) => QualifiedType.fromDartType(e, allowsDynamicParams))
          .toList()),
      dartType.element.name,
    );
  }
  factory ParameterizedType.fromAst(ast.NamedType typeAnnotation) {
    return ParameterizedType(
      TypeParamList(typeAnnotation.typeArguments.arguments
          .map((e) => QualifiedType.fromAst(e))
          .toList()),
      typeAnnotation.name.name,
    );
  }

  @override
  String toSource() => '${type ?? 'dynamic'}' '${typeParams?.toSource() ?? ''}';
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
    final typeParams = dartType.typeFormals
        .map((e) => QualifiedType.fromName(e.name))
        .toList();
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

  static QualifiedType _formalParamType(ast.FormalParameter p) =>
      QualifiedType.fromAstFormalParameter(p);

  factory FunctionType.fromAstParts(
    List<ast.TypeParameter> typeParameters,
    ast.TypeAnnotation returnType,
    List<ast.FormalParameter> parameters,
  ) {
    return FunctionType(
      TypeParamList(typeParameters
          .map((e) => QualifiedType.fromAstTypeParameter(e))
          .toList()),
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
}

class Reference implements Code {
  final QualifiedType type;
  final String name;

  Reference(this.type, this.name);

  @override
  String toSource() => '${type.toSource()} $name';
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
      ..write(required ? '@required' : '')
      ..write(isCovariant ? 'covariant ' : '')
      ..write(type?.toSource() ?? 'dynamic')
      ..write(' ')
      ..write(name);
    if (defaultValue != null && defaultValue.isNotEmpty) {
      r..write(' = ')..write(defaultValue);
    }
    return r.toString();
  }
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
  factory FunctionParameters.fromElement(el.ExecutableElement element) {
    /// [element] is an [el.FunctionElement], [el.PropertyAccessorElement], or
    /// [el.MethodElement].
    if (element is el.ExecutableElement) {
      return FunctionParameters(
        TypeParamList(element.typeParameters
            .map((e) => QualifiedType.fromName(e.name))
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
    }
    throw TypeError();
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
      final entries = named.map((e) => Tuple2(e.name, e));
      r
        ..write('{')
        ..writeAll(
            entries
                .map((e) => '${e.item2.toSource()} ${e.item1}')
                .followedBy(['']),
            ', ')
        ..write('}');
    }
    r..write(')');
    return r.toString();
  }
}

class FunctionDeclaration implements Code {
  final FunctionParameters parameters;
  final String name;
  final QualifiedType returnType;
  FunctionDeclaration(this.parameters, this.name, this.returnType);

  factory FunctionDeclaration.fromElement(
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
      print('warning: $e');
    }
    return FunctionDeclaration(
      FunctionParameters.fromElement(element),
      element.name,
      returnType,
    );
  }
  @override
  String toSource({bool typeArgumentsAlso = true}) =>
      '${returnType?.toSource() ?? ''} $name${parameters?.toSource()}';
}
