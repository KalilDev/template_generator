// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'example.dart';

// **************************************************************************
// TemplateGenerator
// **************************************************************************

const List<Type> _$serializableTypes = [
  Foo,
  Bar,
  A,
  B,
  C,
  StateA,
  StateB,
];

void _$registerHiveTypes([HiveInterface /*?*/ hive]) {
  hive ??= Hive;
  hive..registerAdapter<C>(CAdapter());
}

abstract class Foo implements Built<Foo, FooBuilder> {
  Foo._();

  /// Construct an [Foo] from the updates applied to an
  /// [FooBuilder].
  factory Foo([void Function(FooBuilder) updates]) =>
      _$Foo((b) => b..update(updates));

  /// Serialize an [Foo] to an json object.
  Map<String, dynamic> toJson() =>
      serializers.serialize(this) as Map<String, dynamic>;

  /// Deserialize an [Foo] from an json object.
  static Foo fromJson(Map<String, dynamic> json) =>
      serializers.deserializeWith(Foo.serializer, json);

  /// The [Serializer] that can serialize and deserialize an [Foo].
  static Serializer<Foo> get serializer => _$fooSerializer;

  int get a;
}

abstract class Bar implements Built<Bar, BarBuilder> {
  Bar._();

  /// Construct an [Bar] from the updates applied to an
  /// [BarBuilder].
  factory Bar([void Function(BarBuilder) updates]) =>
      _$Bar((b) => b..update(updates));

  /// Serialize an [Bar] to an json object.
  Map<String, dynamic> toJson() =>
      serializers.serialize(this) as Map<String, dynamic>;

  /// Deserialize an [Bar] from an json object.
  static Bar fromJson(Map<String, dynamic> json) =>
      serializers.deserializeWith(Bar.serializer, json);

  /// The [Serializer] that can serialize and deserialize an [Bar].
  static Serializer<Bar> get serializer => _$barSerializer;

  int get a;
  int get a2 => a * 2;

  static void init() {}
}

abstract class A implements ABC, Built<A, ABuilder> {
  A._();

  /// Construct an [A] from the updates applied to an
  /// [ABuilder].
  factory A([void Function(ABuilder) updates]) =>
      _$A((b) => b..update(updates));

  @override
  T visit<T>({
    @required T Function(A) a,
    @required T Function(B) b,
    @required T Function(C) c,
  }) =>
      a(this);

  @override
  Map<String, dynamic> toJson() =>
      serializers.serialize(this) as Map<String, dynamic>;

  /// Deserialize an [A] from an json object.
  static A fromJson(Map<String, dynamic> json) =>
      serializers.deserializeWith(A.serializer, json);

  /// The [Serializer] that can serialize and deserialize an [A].
  static Serializer<A> get serializer => _$aSerializer;

  int get a;
}

abstract class B implements ABC, Built<B, BBuilder> {
  B._();

  /// Construct an [B] from the updates applied to an
  /// [BBuilder].
  factory B([void Function(BBuilder) updates]) =>
      _$B((b) => b..update(updates));

  @override
  T visit<T>({
    @required T Function(A) a,
    @required T Function(B) b,
    @required T Function(C) c,
  }) =>
      b(this);

  @override
  Map<String, dynamic> toJson() =>
      serializers.serialize(this) as Map<String, dynamic>;

  /// Deserialize an [B] from an json object.
  static B fromJson(Map<String, dynamic> json) =>
      serializers.deserializeWith(B.serializer, json);

  /// The [Serializer] that can serialize and deserialize an [B].
  static Serializer<B> get serializer => _$bSerializer;

  int get b;
}

@HiveType(typeId: 10)

/// C class
abstract class C<T>
    implements GenericInterface<T>, ABC, Built<C<T>, CBuilder<T>> {
  C._() {
    int foo = 1;
    foo++;
  }

  /// Construct an [C] from the updates applied to an
  /// [CBuilder].
  factory C([void Function(CBuilder<T>) updates]) =>
      _$C<T>((b) => b..update(updates));

  @override
  T visit<T>({
    @required T Function(A) a,
    @required T Function(B) b,
    @required T Function(C) c,
  }) =>
      c(this);

  @override
  Map<String, dynamic> toJson() =>
      serializers.serialize(this) as Map<String, dynamic>;

  /// Deserialize an [C] from an json object.
  static C fromJson(Map<String, dynamic> json) =>
      serializers.deserializeWith(C.serializer, json);

  /// The [Serializer] that can serialize and deserialize an [C].
  static Serializer<C> get serializer => _$cSerializer;

  /// c
  int get c;

  /// Generic param
  /// t
  T get t;

  /// c2
  int get c2 => 2 * c;

  /// cstring
  String cString() => c.toString();
}

abstract class StateA implements State, Built<StateA, StateABuilder> {
  StateA._();

  /// Construct an [StateA] from the updates applied to an
  /// [StateABuilder].
  factory StateA([void Function(StateABuilder) updates]) =>
      _$StateA((b) => b..update(updates));

  @override
  T visit<T>({
    @required T Function(StateA) a,
    @required T Function(StateB) b,
  }) =>
      a(this);

  @override
  Map<String, dynamic> toJson() =>
      serializers.serialize(this) as Map<String, dynamic>;

  /// Deserialize an [StateA] from an json object.
  static StateA fromJson(Map<String, dynamic> json) =>
      serializers.deserializeWith(StateA.serializer, json);

  /// The [Serializer] that can serialize and deserialize an [StateA].
  static Serializer<StateA> get serializer => _$stateASerializer;

  int get b;
}

abstract class StateB implements State, Built<StateB, StateBBuilder> {
  StateB._();

  /// Construct an [StateB] from the updates applied to an
  /// [StateBBuilder].
  factory StateB([void Function(StateBBuilder) updates]) =>
      _$StateB((b) => b..update(updates));

  @override
  T visit<T>({
    @required T Function(StateA) a,
    @required T Function(StateB) b,
  }) =>
      b(this);

  @override
  Map<String, dynamic> toJson() =>
      serializers.serialize(this) as Map<String, dynamic>;

  /// Deserialize an [StateB] from an json object.
  static StateB fromJson(Map<String, dynamic> json) =>
      serializers.deserializeWith(StateB.serializer, json);

  /// The [Serializer] that can serialize and deserialize an [StateB].
  static Serializer<StateB> get serializer => _$stateBSerializer;

  int get b;
}

@BuiltValue(instantiable: false)

/// ABC class
abstract class ABC {
  /// Create an instance of an [A] with the [updates] applied to to
  /// the [ABuilder].
  static A a([void Function(ABuilder) updates]) => A(updates);

  /// Create an instance of an [B] with the [updates] applied to to
  /// the [BBuilder].
  static B b([void Function(BBuilder) updates]) => B(updates);

  /// Create an instance of an [C] with the [updates] applied to to
  /// the [CBuilder].
  static C c([void Function(CBuilder) updates]) => C(updates);

  /// Rebuilds the instance.
  ///
  /// The result is the same as this instance but with [updates] applied.
  /// [updates] is a function that takes a builder [B].
  ///
  /// The implementation of this method will be generated for you by the
  /// built_value generator.

  ABCBuilder toBuilder();

  /// Rebuilds the instance.
  ///
  /// The result is the same as this instance but with [updates] applied.
  /// [updates] is a function that takes a builder [B].
  ///
  /// The implementation of this method will be generated for you by the
  /// built_value generator.

  ABC rebuild(void Function(ABCBuilder) updates);

  /// Visit every member of the union [ABC]. Prefer this over explicit
  /// `as` checks because it is exaustive, therefore safer.
  T visit<T>({
    @required T Function(A) a,
    @required T Function(B) b,
    @required T Function(C) c,
  });

  /// Serialize an [ABC] to an json object.
  Map<String, dynamic> toJson();
}

@BuiltValue(instantiable: false)
abstract class State {
  /// Create an instance of an [StateA] with the [updates] applied to to
  /// the [StateABuilder].
  static StateA a([void Function(StateABuilder) updates]) => StateA(updates);

  /// Create an instance of an [StateB] with the [updates] applied to to
  /// the [StateBBuilder].
  static StateB b([void Function(StateBBuilder) updates]) => StateB(updates);

  /// Rebuilds the instance.
  ///
  /// The result is the same as this instance but with [updates] applied.
  /// [updates] is a function that takes a builder [B].
  ///
  /// The implementation of this method will be generated for you by the
  /// built_value generator.

  StateBuilder toBuilder();

  /// Rebuilds the instance.
  ///
  /// The result is the same as this instance but with [updates] applied.
  /// [updates] is a function that takes a builder [B].
  ///
  /// The implementation of this method will be generated for you by the
  /// built_value generator.

  State rebuild(void Function(StateBuilder) updates);

  /// Visit every member of the union [State]. Prefer this over explicit
  /// `as` checks because it is exaustive, therefore safer.
  T visit<T>({
    @required T Function(StateA) a,
    @required T Function(StateB) b,
  });

  /// Serialize an [State] to an json object.
  Map<String, dynamic> toJson();
}
