import 'dart:async';
import 'dart:developer';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:build/build.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:hive/hive.dart' show HiveType;
import 'package:source_gen/source_gen.dart';
import 'package:template_annotation/template_annotation.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/src/output_helpers.dart';
import 'package:template_generator/src/builder_template_class.dart';
import 'package:template_generator/src/class_code_builder.dart';
import 'package:template_generator/src/template_class.dart';
import 'package:template_generator/src/union_class.dart';
import 'package:tuple/tuple.dart';

import 'utils.dart' as util;

Iterable<T> infiniteIterable<T>(T value) sync* {
  while (true) {
    yield value;
  }
}

extension _Unwrap2a<T1, T2, T3> on Iterable<Tuple2<T1, Tuple2<T2, T3>>> {
  Iterable<Tuple3<T1, T2, T3>> unwrap() =>
      map((e) => Tuple3(e.item1, e.item2.item1, e.item2.item2));
}

extension _Unwrap2b<T1, T2, T3> on Iterable<Tuple2<Tuple2<T1, T2>, T3>> {
  Iterable<Tuple3<T1, T2, T3>> unwrap() =>
      map((e) => Tuple3(e.item1.item1, e.item1.item2, e.item2));
}

extension _Unwrap3a<T1, T2, T3, T4>
    on Iterable<Tuple3<Tuple2<T1, T2>, T3, T4>> {
  Iterable<Tuple4<T1, T2, T3, T4>> unwrap() =>
      map((e) => Tuple4(e.item1.item1, e.item1.item2, e.item2, e.item3));
}

class TemplateGenerator extends Generator {
  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    final resolverCache = Expando<AstNode>('Resolver Cache');
    Future<AstNode> cachingResolver(Element e) async {
      final cached = resolverCache[e];
      if (cached != null) {
        return cached;
      }
      return resolverCache[e] =
          await buildStep.resolver.astNodeFor(e, resolve: false);
    }

    final unitedToUnion = <ClassElement, UnionClassFactory>{};
    final nameToTemplate = <String, TemplateClassFactory>{};
    final builders = <String, ClassCodeBuilder>{};
    // Walking order must be union -> template -> builder template, as this
    // allows an single pass
    for (final union
        in library.classes.where(util.unionChecker.hasAnnotationOf)) {
      final annotation = ConstantReader(
        util.unionChecker.annotationsOfExact(union).single,
      );
      final uFactory = UnionClassFactory()
        ..cls = union
        ..unionAnnotation = annotation
        ..resolver = cachingResolver;

      unitedToUnion.addEntries(
        annotation
            .read('members')
            .setValue
            .map((e) => e.toTypeValue())
            .map((e) => e.element)
            .zip(infiniteIterable(uFactory))
            .map((e) => MapEntry(e.item1, e.item2)),
      );
      builders[uFactory.className] = uFactory;
    }
    for (final template
        in library.classes.where(util.templateChecker.hasAnnotationOf)) {
      final tFactory = TemplateClassFactory()
        ..cls = template
        ..templateAnnotation = ConstantReader(
          util.templateChecker.annotationsOfExact(template).single,
        )
        ..resolver = cachingResolver;
      if (unitedToUnion.containsKey(template)) {
        final union = unitedToUnion.remove(template);
        union.addMember(tFactory);
      }
      nameToTemplate[template.name] = tFactory;
      builders[tFactory.className] = tFactory;
    }

    for (final builderTemplate
        in library.classes.where(util.builderTemplateChecker.hasAnnotationOf)) {
      final bFactory = BuilderTemplateClassFactory()
        ..cls = builderTemplate
        ..builderTemplateAnnotation = ConstantReader(
          util.builderTemplateChecker
              .annotationsOfExact(builderTemplate)
              .single,
        )
        ..resolver = cachingResolver;
      final templateName = bFactory.templateClassName();
      final template = nameToTemplate.remove(templateName);
      util.verify(template != null,
          'The template class $templateName either has duplicate builder templates or it does not exist');
      template.addBuilder(bFactory);
      builders[bFactory.className] = bFactory;
    }
    util.collectFailures(
      unitedToUnion //
          .entries
          .map((e) => 'The member class ${e.key.name} of the union'
              ' ${e.value.cls.name} is not an template'),
    );
    final possibleMixins = library.element.units.expand((cu) => cu.mixins
        .cast<ClassElement>()
        .followedBy(cu.types.where((e) => e.isAbstract)));
    for (final toBeMixed in possibleMixins) {
      final types = util.mixToChecker
          .annotationsOf(toBeMixed)
          .map((e) => e.getField("type"))
          .map((e) => e.toTypeValue())
          .map((e) => e.element.name);
      util.collectFailures(
        types.where((t) =>
            !builders.containsKey(t) || builders[t] is! ClassCodeBuilder),
        format:
            "The following types in @MixTo annotations are not templates or "
            "unions!\n...{}",
      );
      types
          .map((e) => builders[e])
          .cast<ClassCodeBuilder>()
          .forEach((bdr) => bdr.addMixin(toBeMixed));
    }

    return builders.values
        .map((e) => e.build())
        .wait()
        .then((results) => results
            .map((e) => e.toSource())
            .where((e) => e?.isNotEmpty ?? false)
            .fold<StringBuffer>(
              StringBuffer(),
              (buff, source) => buff..write(source),
            )
            .pipe((buff) => _addSerializersIfNotEmpty(buff, builders.values))
            .pipe((buff) => _addHiveTypeIfNotEmpty(buff, builders.values))
            .pipe(_addIgnoreForFileIfNotEmpty)
            .pipe((e) => e.toString()));
  }

  StringBuffer _addSerializersIfNotEmpty(
      StringBuffer buff, Iterable<ClassCodeBuilder> builders) {
    if (buff.isEmpty) {
      return buff;
    }
    final names = builders
        .whereType<TemplateClassFactory>()
        .map((f) => f.demangledClassName);
    if (names.isEmpty) {
      return buff;
    }

    return buff
      ..writeln('const List<Type> _\$serializableTypes = [')
      ..writeAll(names, ',\n')
      ..writeln(',\n];');
  }

  StringBuffer _addHiveTypeIfNotEmpty(
      StringBuffer buff, Iterable<ClassCodeBuilder> builders) {
    if (buff.isEmpty) {
      return buff;
    }
    final statements = builders
        .whereType<TemplateClassFactory>()
        .where((f) => f.hasHiveType)
        .map((f) => f.demangledClassName)
        .map((clsName) => 'registerAdapter<$clsName>(${clsName}Adapter())');
    if (statements.isEmpty) {
      return buff;
    }
    final nullSuffix = '/*?*/';

    return buff
      ..writeln('''void _\$registerHiveTypes([HiveInterface$nullSuffix hive]) {
      hive ??= Hive;
      hive..''')
      ..writeAll(statements, '\n..')
      ..writeln(';\n}');
  }

  StringBuffer _addIgnoreForFileIfNotEmpty(StringBuffer buff) {
    if (buff.isEmpty) {
      return buff;
    }
    const lints = [
      'unnecessary_this',
      'lines_longer_than_80_chars',
      'sort_unnamed_constructors_first',
      'prefer_constructors_over_static_methods',
      'avoid_single_cascade_in_expression_statements',
    ];
    return buff
      ..write('// ignore_for_file: ')
      ..writeAll(lints, ', ');
  }
}
