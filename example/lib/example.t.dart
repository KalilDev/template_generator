// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'example.dart';

// **************************************************************************
// TemplateGenerator
// **************************************************************************

@BuiltValue(instantiable: false)

/// ABC class
abstract class ABC implements __ABC {
  static A a(
    int a,
  ) =>
      A(
        a,
      );

  static B b(
    int b,
  ) =>
      B(
        b,
      );

  static C<T> c<T>(
    int c,
    T t,
  ) =>
      C<T>(
        c,
        t,
      );

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

  ABC rebuild(
    void Function(
      ABCBuilder,
    )
        updates,
  );

  /// Visit every member of the union [ABC]. Prefer this over explicit
  /// `as` checks because it is exaustive, therefore safer.

  R visit<R>({
    @required
        R Function(
      A,
    )
            a,
    @required
        R Function(
      B,
    )
            b,
    @required
        R Function<T>(
      C<T>,
    )
            c,
  });

  /// Visit and destructure every member of the union [ABC]. Prefer
  /// this over explicit `as` checks because it is exaustive, therefore
  /// safer.

  R visitCata<R>({
    @required
        R Function({
      int a,
    })
            a,
    @required
        R Function({
      int b,
    })
            b,
    @required
        R Function<T>({
      int c,
      T t,
    })
            c,
  });

  /// Serialize an [ABC] to an json object.

  Map<String, dynamic> toJson();
}

@BuiltValue(instantiable: false)
abstract class State implements __State {
  static StateA a(
    int b,
  ) =>
      StateA(
        b,
      );

  static StateB b(
    int b, [
    void Function(
      StateBBuilder,
    )
        updates,
    String a,
  ]) =>
      StateB(
        b,
        updates,
        a,
      );

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

  State rebuild(
    void Function(
      StateBuilder,
    )
        updates,
  );

  /// Visit every member of the union [State]. Prefer this over explicit
  /// `as` checks because it is exaustive, therefore safer.

  R visit<R>({
    @required
        R Function(
      StateA,
    )
            a,
    @required
        R Function(
      StateB,
    )
            b,
  });

  /// Visit and destructure every member of the union [State]. Prefer
  /// this over explicit `as` checks because it is exaustive, therefore
  /// safer.

  R visitCata<R>({
    @required
        R Function({
      int b,
    })
            a,
    @required
        R Function({
      int b,
      List<int> ints,
    })
            b,
  });

  /// Serialize an [State] to an json object.

  Map<String, dynamic> toJson();

  static int get stateIndex => __State.stateIndex;

  static const init = __State.init;
}

abstract class Foo implements Built<Foo, FooBuilder>, __Foo {
  Foo._();

  factory Foo([
    void Function(
      FooBuilder,
    )
        updates,
  ]) = _$Foo;

  /// Serialize an [Foo] to an json object.

  Map<String, dynamic> toJson() =>
      serializers.serialize(this, specifiedType: FullType(Foo, []))
          as Map<String, dynamic>;

  /// Deserialize an [Foo] from an json object.

  static Foo fromJson(
    Map<String, dynamic> json,
  ) =>
      serializers.deserialize(json, specifiedType: FullType(Foo, [])) as Foo;

  /// The [Serializer] that can serialize and deserialize an [Foo].

  static Serializer<Foo> get serializer => _$fooSerializer;

  R cata<R>(
    R Function({
      int a,
      Bar bar,
    })
        fn,
  ) =>
      fn(a: this.a, bar: this.bar);

  int get a;

  Bar get bar;
}

abstract class Bar implements Built<Bar, BarBuilder>, __Bar {
  Bar._();

  factory Bar(
    int a,
  ) =>
      _$Bar((__bdr) => __bdr..a = a);

  /// Serialize an [Bar] to an json object.

  Map<String, dynamic> toJson() =>
      serializers.serialize(this, specifiedType: FullType(Bar, []))
          as Map<String, dynamic>;

  /// Deserialize an [Bar] from an json object.

  static Bar fromJson(
    Map<String, dynamic> json,
  ) =>
      serializers.deserialize(json, specifiedType: FullType(Bar, [])) as Bar;

  /// The [Serializer] that can serialize and deserialize an [Bar].

  static Serializer<Bar> get serializer => _$barSerializer;

  R cata<R>(
    R Function({
      int a,
    })
        fn,
  ) =>
      fn(a: this.a);

  @Method(name: 'notReturnA')
  int notReturnA() => __Bar.__returnA(
        this,
      );

  int get a;

  @Getter()
  int get b => __Bar.__getB(
        this,
      );

  @Setter()
  set b(int a2) => __Bar.__setB(
        this,
        a2,
      );

  @Setter(name: 'aaaa')
  set aaaa(int a2) => __Bar.__setNotB(
        this,
        a2,
      );

  static const init = __Bar.init;
}

abstract class A implements Built<A, ABuilder>, ABC, __A {
  A._();

  factory A(
    int a,
  ) =>
      _$A((__bdr) => __bdr..a = a);

  @override
  R visit<R>({
    @required
        R Function(
      A,
    )
            a,
    @required
        R Function(
      B,
    )
            b,
    @required
        R Function<T>(
      C<T>,
    )
            c,
  }) =>
      a(this);
  @override
  R visitCata<R>({
    @required
        R Function({
      int a,
    })
            a,
    @required
        R Function({
      int b,
    })
            b,
    @required
        R Function<T>({
      int c,
      T t,
    })
            c,
  }) =>
      a(a: this.a);

  @override
  Map<String, dynamic> toJson() =>
      serializers.serialize(this, specifiedType: FullType.unspecified)
          as Map<String, dynamic>;

  /// Deserialize an [A] from an json object.

  static A fromJson(
    Map<String, dynamic> json,
  ) =>
      serializers.deserialize(json, specifiedType: FullType.unspecified) as A;

  /// The [Serializer] that can serialize and deserialize an [A].

  static Serializer<A> get serializer => _$aSerializer;

  R cata<R>(
    R Function({
      int a,
    })
        fn,
  ) =>
      fn(a: this.a);

  int get a;
}

abstract class B implements Built<B, BBuilder>, ABC, __B {
  B._();

  factory B(
    int b,
  ) =>
      _$B((__bdr) => __bdr..b = b);

  @override
  R visit<R>({
    @required
        R Function(
      A,
    )
            a,
    @required
        R Function(
      B,
    )
            b,
    @required
        R Function<T>(
      C<T>,
    )
            c,
  }) =>
      b(this);
  @override
  R visitCata<R>({
    @required
        R Function({
      int a,
    })
            a,
    @required
        R Function({
      int b,
    })
            b,
    @required
        R Function<T>({
      int c,
      T t,
    })
            c,
  }) =>
      b(b: this.b);

  @override
  Map<String, dynamic> toJson() =>
      serializers.serialize(this, specifiedType: FullType.unspecified)
          as Map<String, dynamic>;

  /// Deserialize an [B] from an json object.

  static B fromJson(
    Map<String, dynamic> json,
  ) =>
      serializers.deserialize(json, specifiedType: FullType.unspecified) as B;

  /// The [Serializer] that can serialize and deserialize an [B].

  static Serializer<B> get serializer => _$bSerializer;

  R cata<R>(
    R Function({
      int b,
    })
        fn,
  ) =>
      fn(b: this.b);

  int get b;
}

@HiveType(typeId: 10)

/// C class
abstract class Generic<T>
    implements
        GenericInterface<T>,
        Built<Generic<T>, GenericBuilder<T>>,
        __Generic<T> {
  Generic._() {
    int foo = 1;
    foo++;
  }

  factory Generic(
    int c,
    T t,
  ) =>
      _$Generic<T>((__bdr) => __bdr
        ..c = c
        ..t = t);

  /// Serialize an [Generic] to an json object.

  Map<String, dynamic> toJson() =>
      serializers.serialize(this, specifiedType: FullType.unspecified)
          as Map<String, dynamic>;

  /// Deserialize an [Generic] from an json object.

  static Generic<Object> fromJson(
    Map<String, dynamic> json,
  ) =>
      serializers.deserialize(json, specifiedType: FullType.unspecified)
          as Generic<Object>;

  /// The [Serializer] that can serialize and deserialize an [Generic].

  static Serializer<Generic<Object>> get serializer => _$genericSerializer;

  R cata<R>(
    R Function({
      int c,
      T t,
    })
        fn,
  ) =>
      fn(c: this.c, t: this.t);

  /// c

  int get c;

  /// Generic param
  /// t

  T get t;
}

@HiveType(typeId: 10)

/// C class
abstract class C<T>
    implements GenericInterface<T>, Built<C<T>, CBuilder<T>>, ABC, __C<T> {
  C._() {
    int foo = 1;
    foo++;
  }

  factory C(
    int c,
    T t,
  ) =>
      _$C<T>((__bdr) => __bdr
        ..c = c
        ..t = t);

  @override
  R visit<R>({
    @required
        R Function(
      A,
    )
            a,
    @required
        R Function(
      B,
    )
            b,
    @required
        R Function<T>(
      C<T>,
    )
            c,
  }) =>
      c<T>(this);
  @override
  R visitCata<R>({
    @required
        R Function({
      int a,
    })
            a,
    @required
        R Function({
      int b,
    })
            b,
    @required
        R Function<T>({
      int c,
      T t,
    })
            c,
  }) =>
      c<T>(c: this.c, t: this.t);

  @override
  Map<String, dynamic> toJson() =>
      serializers.serialize(this, specifiedType: FullType.unspecified)
          as Map<String, dynamic>;

  /// Deserialize an [C] from an json object.

  static C<Object> fromJson(
    Map<String, dynamic> json,
  ) =>
      serializers.deserialize(json, specifiedType: FullType.unspecified)
          as C<Object>;

  /// The [Serializer] that can serialize and deserialize an [C].

  static Serializer<C<Object>> get serializer => _$cSerializer;

  R cata<R>(
    R Function({
      int c,
      T t,
    })
        fn,
  ) =>
      fn(c: this.c, t: this.t);

  /// c

  int get c;

  /// Generic param
  /// t

  T get t;
}

abstract class StateA implements Built<StateA, StateABuilder>, State, __StateA {
  StateA._();

  factory StateA(
    int b,
  ) =>
      _$StateA((__bdr) => __bdr..b = b);

  @override
  R visit<R>({
    @required
        R Function(
      StateA,
    )
            a,
    @required
        R Function(
      StateB,
    )
            b,
  }) =>
      a(this);
  @override
  R visitCata<R>({
    @required
        R Function({
      int b,
    })
            a,
    @required
        R Function({
      int b,
      List<int> ints,
    })
            b,
  }) =>
      a(b: this.b);

  @override
  Map<String, dynamic> toJson() =>
      serializers.serialize(this, specifiedType: FullType.unspecified)
          as Map<String, dynamic>;

  /// Deserialize an [StateA] from an json object.

  static StateA fromJson(
    Map<String, dynamic> json,
  ) =>
      serializers.deserialize(json, specifiedType: FullType.unspecified)
          as StateA;

  /// The [Serializer] that can serialize and deserialize an [StateA].

  static Serializer<StateA> get serializer => _$stateASerializer;

  R cata<R>(
    R Function({
      int b,
    })
        fn,
  ) =>
      fn(b: this.b);

  int get b;
}

abstract class StateB implements Built<StateB, StateBBuilder>, State, __StateB {
  StateB._();

  factory StateB(
    int b, [
    void Function(
      StateBBuilder,
    )
        updates,
    String a,
  ]) =>
      _$StateB((__builder) => __builder
        ..update(__StateB._ctor(
          b,
          updates,
          a,
        )));

  factory StateB.two(
    String name,
  ) =>
      _$StateB((__builder) => __builder
        ..update(__StateB._ctorTwo(
          name,
        )));

  factory StateB.three(
    StateB b,
  ) =>
      _$StateB((__builder) => __builder
        ..update(__StateB._ctorThree(
          b,
        )));

  @override
  R visit<R>({
    @required
        R Function(
      StateA,
    )
            a,
    @required
        R Function(
      StateB,
    )
            b,
  }) =>
      b(this);
  @override
  R visitCata<R>({
    @required
        R Function({
      int b,
    })
            a,
    @required
        R Function({
      int b,
      List<int> ints,
    })
            b,
  }) =>
      b(b: this.b, ints: this.ints);

  @override
  Map<String, dynamic> toJson() =>
      serializers.serialize(this, specifiedType: FullType.unspecified)
          as Map<String, dynamic>;

  /// Deserialize an [StateB] from an json object.

  static StateB fromJson(
    Map<String, dynamic> json,
  ) =>
      serializers.deserialize(json, specifiedType: FullType.unspecified)
          as StateB;

  /// The [Serializer] that can serialize and deserialize an [StateB].

  static Serializer<StateB> get serializer => _$stateBSerializer;

  R cata<R>(
    R Function({
      int b,
      List<int> ints,
    })
        fn,
  ) =>
      fn(b: this.b, ints: this.ints);

  static int get index => __StateB.index;

  int get b;

  List<int> get ints;
}

abstract class StateABuilder
    implements Builder<StateA, StateABuilder>, StateBuilder, __StateABuilder {
  StateABuilder._();

  factory StateABuilder() = _$StateABuilder;

  int b;
}

const List<Type> _$serializableTypes = [
  Foo,
  Bar,
  A,
  B,
  Generic,
  C,
  StateA,
  StateB,
];
void _$registerHiveTypes([HiveInterface /*?*/ hive]) {
  hive ??= Hive;
  hive
    ..registerAdapter<Generic>(GenericAdapter())
    ..registerAdapter<C>(CAdapter());
}
// ignore_for_file: unnecessary_this, lines_longer_than_80_chars, sort_unnamed_constructors_first, prefer_constructors_over_static_methods, avoid_single_cascade_in_expression_statements
