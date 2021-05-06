import 'package:template_annotation/template_annotation.dart';
import 'package:built_value/built_value.dart';
import 'package:hive/hive.dart';
import 'package:meta/meta.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
part 'example.t.dart';
part 'example.g.dart';

@SerializersFor(_$serializableTypes)
final Serializers serializers =
    (_$serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();

@template
abstract class __Foo {
  int get a;
}

@template
abstract class __Bar {
  int get a;

  @getter
  static int a2(Bar self) => self.a * 2;
  static void init() {}
  @member
  static BarBuilder getBuilder(Bar self) => self.toBuilder();
}

@template
abstract class __A {
  int get a;
}

@template
abstract class __B {
  int get b;
}

abstract class GenericInterface<T> {}

@Template(hiveType: 10)

/// C class
abstract class __C<T> implements GenericInterface<T> {
  __C() {
    int foo = 1;
    foo++;
  }

  /// c
  int get c;

  /// c2
  @member
  static int c2<T>(C<T> self) => self.c * 2;

  /// cstring
  @member
  static String cString<T>(C<T> self) => self.c.toString();

  @member
  static C doNothing<T>(C<T> self) => C<T>();

  /// Generic param
  /// t
  T get t;
}

@Union({__A, __B, __C})

/// ABC class
abstract class __ABC {}

@template
abstract class __StateA {
  int get b;
}

@builderTemplate
abstract class __StateABuilder {
  int b;
}

@template
abstract class __StateB {
  int get b;
  List<int> get ints;

  static final index = 0;
  @constructor
  static _ctor(int b, [void Function(StateBBuilder) updates, String a]) =>
      (StateBBuilder bdr) => bdr..update(updates);
  @Constructor('two')
  static _ctorTwo(String name) =>
      (StateBBuilder bdr) => bdr..b = int.parse(name);
  @Constructor('three')
  static _ctorThree(StateB b) => (StateBBuilder bdr) => bdr.replace(b);

  @member
  static StateA toA(StateB self) => StateA();
}

@Union({__StateA, __StateB})
abstract class __State {
  static final stateIndex = 1;
  static void init() {}
}
