// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'example.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializers _$serializers = (new Serializers().toBuilder()
      ..add(A.serializer)
      ..add(B.serializer)
      ..add(Bar.serializer)
      ..add(C.serializer)
      ..add(Foo.serializer)
      ..add(Generic.serializer)
      ..add(StateA.serializer)
      ..add(StateB.serializer))
    .build();
Serializer<Foo> _$fooSerializer = new _$FooSerializer();
Serializer<Bar> _$barSerializer = new _$BarSerializer();
Serializer<A> _$aSerializer = new _$ASerializer();
Serializer<B> _$bSerializer = new _$BSerializer();
Serializer<Generic<Object>> _$genericSerializer = new _$GenericSerializer();
Serializer<C<Object>> _$cSerializer = new _$CSerializer();
Serializer<StateA> _$stateASerializer = new _$StateASerializer();
Serializer<StateB> _$stateBSerializer = new _$StateBSerializer();

class _$FooSerializer implements StructuredSerializer<Foo> {
  @override
  final Iterable<Type> types = const [Foo, _$Foo];
  @override
  final String wireName = 'Foo';

  @override
  Iterable<Object> serialize(Serializers serializers, Foo object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'a',
      serializers.serialize(object.a, specifiedType: const FullType(int)),
      'bar',
      serializers.serialize(object.bar, specifiedType: const FullType(Bar)),
    ];

    return result;
  }

  @override
  Foo deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new FooBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final Object value = iterator.current;
      switch (key) {
        case 'a':
          result.a = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'bar':
          result.bar.replace(serializers.deserialize(value,
              specifiedType: const FullType(Bar)) as Bar);
          break;
      }
    }

    return result.build();
  }
}

class _$BarSerializer implements StructuredSerializer<Bar> {
  @override
  final Iterable<Type> types = const [Bar, _$Bar];
  @override
  final String wireName = 'Bar';

  @override
  Iterable<Object> serialize(Serializers serializers, Bar object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'a',
      serializers.serialize(object.a, specifiedType: const FullType(int)),
    ];

    return result;
  }

  @override
  Bar deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new BarBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final Object value = iterator.current;
      switch (key) {
        case 'a':
          result.a = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
      }
    }

    return result.build();
  }
}

class _$ASerializer implements StructuredSerializer<A> {
  @override
  final Iterable<Type> types = const [A, _$A];
  @override
  final String wireName = 'A';

  @override
  Iterable<Object> serialize(Serializers serializers, A object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'a',
      serializers.serialize(object.a, specifiedType: const FullType(int)),
    ];

    return result;
  }

  @override
  A deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new ABuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final Object value = iterator.current;
      switch (key) {
        case 'a':
          result.a = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
      }
    }

    return result.build();
  }
}

class _$BSerializer implements StructuredSerializer<B> {
  @override
  final Iterable<Type> types = const [B, _$B];
  @override
  final String wireName = 'B';

  @override
  Iterable<Object> serialize(Serializers serializers, B object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'b',
      serializers.serialize(object.b, specifiedType: const FullType(int)),
    ];

    return result;
  }

  @override
  B deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new BBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final Object value = iterator.current;
      switch (key) {
        case 'b':
          result.b = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
      }
    }

    return result.build();
  }
}

class _$GenericSerializer implements StructuredSerializer<Generic<Object>> {
  @override
  final Iterable<Type> types = const [Generic, _$Generic];
  @override
  final String wireName = 'Generic';

  @override
  Iterable<Object> serialize(Serializers serializers, Generic<Object> object,
      {FullType specifiedType = FullType.unspecified}) {
    final isUnderspecified =
        specifiedType.isUnspecified || specifiedType.parameters.isEmpty;
    if (!isUnderspecified) serializers.expectBuilder(specifiedType);
    final parameterT =
        isUnderspecified ? FullType.object : specifiedType.parameters[0];

    final result = <Object>[
      'c',
      serializers.serialize(object.c, specifiedType: const FullType(int)),
      't',
      serializers.serialize(object.t, specifiedType: parameterT),
    ];

    return result;
  }

  @override
  Generic<Object> deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final isUnderspecified =
        specifiedType.isUnspecified || specifiedType.parameters.isEmpty;
    if (!isUnderspecified) serializers.expectBuilder(specifiedType);
    final parameterT =
        isUnderspecified ? FullType.object : specifiedType.parameters[0];

    final result = isUnderspecified
        ? new GenericBuilder<Object>()
        : serializers.newBuilder(specifiedType) as GenericBuilder<Object>;

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final Object value = iterator.current;
      switch (key) {
        case 'c':
          result.c = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 't':
          result.t = serializers.deserialize(value, specifiedType: parameterT);
          break;
      }
    }

    return result.build();
  }
}

class _$CSerializer implements StructuredSerializer<C<Object>> {
  @override
  final Iterable<Type> types = const [C, _$C];
  @override
  final String wireName = 'C';

  @override
  Iterable<Object> serialize(Serializers serializers, C<Object> object,
      {FullType specifiedType = FullType.unspecified}) {
    final isUnderspecified =
        specifiedType.isUnspecified || specifiedType.parameters.isEmpty;
    if (!isUnderspecified) serializers.expectBuilder(specifiedType);
    final parameterT =
        isUnderspecified ? FullType.object : specifiedType.parameters[0];

    final result = <Object>[
      'c',
      serializers.serialize(object.c, specifiedType: const FullType(int)),
      't',
      serializers.serialize(object.t, specifiedType: parameterT),
    ];

    return result;
  }

  @override
  C<Object> deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final isUnderspecified =
        specifiedType.isUnspecified || specifiedType.parameters.isEmpty;
    if (!isUnderspecified) serializers.expectBuilder(specifiedType);
    final parameterT =
        isUnderspecified ? FullType.object : specifiedType.parameters[0];

    final result = isUnderspecified
        ? new CBuilder<Object>()
        : serializers.newBuilder(specifiedType) as CBuilder<Object>;

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final Object value = iterator.current;
      switch (key) {
        case 'c':
          result.c = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 't':
          result.t = serializers.deserialize(value, specifiedType: parameterT);
          break;
      }
    }

    return result.build();
  }
}

class _$StateASerializer implements StructuredSerializer<StateA> {
  @override
  final Iterable<Type> types = const [StateA, _$StateA];
  @override
  final String wireName = 'StateA';

  @override
  Iterable<Object> serialize(Serializers serializers, StateA object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'b',
      serializers.serialize(object.b, specifiedType: const FullType(int)),
    ];

    return result;
  }

  @override
  StateA deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new StateABuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final Object value = iterator.current;
      switch (key) {
        case 'b':
          result.b = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
      }
    }

    return result.build();
  }
}

class _$StateBSerializer implements StructuredSerializer<StateB> {
  @override
  final Iterable<Type> types = const [StateB, _$StateB];
  @override
  final String wireName = 'StateB';

  @override
  Iterable<Object> serialize(Serializers serializers, StateB object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'b',
      serializers.serialize(object.b, specifiedType: const FullType(int)),
      'ints',
      serializers.serialize(object.ints,
          specifiedType: const FullType(List, const [const FullType(int)])),
    ];

    return result;
  }

  @override
  StateB deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new StateBBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final Object value = iterator.current;
      switch (key) {
        case 'b':
          result.b = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'ints':
          result.ints = serializers.deserialize(value,
                  specifiedType:
                      const FullType(List, const [const FullType(int)]))
              as List<int>;
          break;
      }
    }

    return result.build();
  }
}

abstract class ABCBuilder {
  void replace(ABC other);
  void update(void Function(ABCBuilder) updates);
}

abstract class StateBuilder {
  void replace(State other);
  void update(void Function(StateBuilder) updates);
}

class _$Foo extends Foo {
  @override
  final int a;
  @override
  final Bar bar;

  factory _$Foo([void Function(FooBuilder) updates]) =>
      (new FooBuilder()..update(updates)).build();

  _$Foo._({this.a, this.bar}) : super._() {
    BuiltValueNullFieldError.checkNotNull(a, 'Foo', 'a');
    BuiltValueNullFieldError.checkNotNull(bar, 'Foo', 'bar');
  }

  @override
  Foo rebuild(void Function(FooBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FooBuilder toBuilder() => new FooBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Foo && a == other.a && bar == other.bar;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, a.hashCode), bar.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Foo')..add('a', a)..add('bar', bar))
        .toString();
  }
}

class FooBuilder implements Builder<Foo, FooBuilder> {
  _$Foo _$v;

  int _a;
  int get a => _$this._a;
  set a(int a) => _$this._a = a;

  BarBuilder _bar;
  BarBuilder get bar => _$this._bar ??= new BarBuilder();
  set bar(BarBuilder bar) => _$this._bar = bar;

  FooBuilder();

  FooBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _a = $v.a;
      _bar = $v.bar.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Foo other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$Foo;
  }

  @override
  void update(void Function(FooBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Foo build() {
    _$Foo _$result;
    try {
      _$result = _$v ??
          new _$Foo._(
              a: BuiltValueNullFieldError.checkNotNull(a, 'Foo', 'a'),
              bar: bar.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'bar';
        bar.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'Foo', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

class _$Bar extends Bar {
  @override
  final int a;

  factory _$Bar([void Function(BarBuilder) updates]) =>
      (new BarBuilder()..update(updates)).build();

  _$Bar._({this.a}) : super._() {
    BuiltValueNullFieldError.checkNotNull(a, 'Bar', 'a');
  }

  @override
  Bar rebuild(void Function(BarBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BarBuilder toBuilder() => new BarBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Bar && a == other.a;
  }

  @override
  int get hashCode {
    return $jf($jc(0, a.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Bar')..add('a', a)).toString();
  }
}

class BarBuilder implements Builder<Bar, BarBuilder> {
  _$Bar _$v;

  int _a;
  int get a => _$this._a;
  set a(int a) => _$this._a = a;

  BarBuilder();

  BarBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _a = $v.a;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Bar other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$Bar;
  }

  @override
  void update(void Function(BarBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Bar build() {
    final _$result = _$v ??
        new _$Bar._(a: BuiltValueNullFieldError.checkNotNull(a, 'Bar', 'a'));
    replace(_$result);
    return _$result;
  }
}

class _$A extends A {
  @override
  final int a;

  factory _$A([void Function(ABuilder) updates]) =>
      (new ABuilder()..update(updates)).build();

  _$A._({this.a}) : super._() {
    BuiltValueNullFieldError.checkNotNull(a, 'A', 'a');
  }

  @override
  A rebuild(void Function(ABuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ABuilder toBuilder() => new ABuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is A && a == other.a;
  }

  @override
  int get hashCode {
    return $jf($jc(0, a.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('A')..add('a', a)).toString();
  }
}

class ABuilder implements Builder<A, ABuilder>, ABCBuilder {
  _$A _$v;

  int _a;
  int get a => _$this._a;
  set a(covariant int a) => _$this._a = a;

  ABuilder();

  ABuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _a = $v.a;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(covariant A other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$A;
  }

  @override
  void update(void Function(ABuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$A build() {
    final _$result =
        _$v ?? new _$A._(a: BuiltValueNullFieldError.checkNotNull(a, 'A', 'a'));
    replace(_$result);
    return _$result;
  }
}

class _$B extends B {
  @override
  final int b;

  factory _$B([void Function(BBuilder) updates]) =>
      (new BBuilder()..update(updates)).build();

  _$B._({this.b}) : super._() {
    BuiltValueNullFieldError.checkNotNull(b, 'B', 'b');
  }

  @override
  B rebuild(void Function(BBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BBuilder toBuilder() => new BBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is B && b == other.b;
  }

  @override
  int get hashCode {
    return $jf($jc(0, b.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('B')..add('b', b)).toString();
  }
}

class BBuilder implements Builder<B, BBuilder>, ABCBuilder {
  _$B _$v;

  int _b;
  int get b => _$this._b;
  set b(covariant int b) => _$this._b = b;

  BBuilder();

  BBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _b = $v.b;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(covariant B other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$B;
  }

  @override
  void update(void Function(BBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$B build() {
    final _$result =
        _$v ?? new _$B._(b: BuiltValueNullFieldError.checkNotNull(b, 'B', 'b'));
    replace(_$result);
    return _$result;
  }
}

class _$Generic<T> extends Generic<T> {
  @override
  final int c;
  @override
  final T t;

  factory _$Generic([void Function(GenericBuilder<T>) updates]) =>
      (new GenericBuilder<T>()..update(updates)).build();

  _$Generic._({this.c, this.t}) : super._() {
    BuiltValueNullFieldError.checkNotNull(c, 'Generic', 'c');
    BuiltValueNullFieldError.checkNotNull(t, 'Generic', 't');
    if (T == dynamic) {
      throw new BuiltValueMissingGenericsError('Generic', 'T');
    }
  }

  @override
  Generic<T> rebuild(void Function(GenericBuilder<T>) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GenericBuilder<T> toBuilder() => new GenericBuilder<T>()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Generic && c == other.c && t == other.t;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, c.hashCode), t.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Generic')..add('c', c)..add('t', t))
        .toString();
  }
}

class GenericBuilder<T> implements Builder<Generic<T>, GenericBuilder<T>> {
  _$Generic<T> _$v;

  int _c;
  int get c => _$this._c;
  set c(int c) => _$this._c = c;

  T _t;
  T get t => _$this._t;
  set t(T t) => _$this._t = t;

  GenericBuilder();

  GenericBuilder<T> get _$this {
    final $v = _$v;
    if ($v != null) {
      _c = $v.c;
      _t = $v.t;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Generic<T> other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$Generic<T>;
  }

  @override
  void update(void Function(GenericBuilder<T>) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Generic<T> build() {
    final _$result = _$v ??
        new _$Generic<T>._(
            c: BuiltValueNullFieldError.checkNotNull(c, 'Generic', 'c'),
            t: BuiltValueNullFieldError.checkNotNull(t, 'Generic', 't'));
    replace(_$result);
    return _$result;
  }
}

class _$C<T> extends C<T> {
  @override
  final int c;
  @override
  final T t;

  factory _$C([void Function(CBuilder<T>) updates]) =>
      (new CBuilder<T>()..update(updates)).build();

  _$C._({this.c, this.t}) : super._() {
    BuiltValueNullFieldError.checkNotNull(c, 'C', 'c');
    BuiltValueNullFieldError.checkNotNull(t, 'C', 't');
    if (T == dynamic) {
      throw new BuiltValueMissingGenericsError('C', 'T');
    }
  }

  @override
  C<T> rebuild(void Function(CBuilder<T>) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CBuilder<T> toBuilder() => new CBuilder<T>()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is C && c == other.c && t == other.t;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, c.hashCode), t.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('C')..add('c', c)..add('t', t))
        .toString();
  }
}

class CBuilder<T> implements Builder<C<T>, CBuilder<T>>, ABCBuilder {
  _$C<T> _$v;

  int _c;
  int get c => _$this._c;
  set c(covariant int c) => _$this._c = c;

  T _t;
  T get t => _$this._t;
  set t(covariant T t) => _$this._t = t;

  CBuilder();

  CBuilder<T> get _$this {
    final $v = _$v;
    if ($v != null) {
      _c = $v.c;
      _t = $v.t;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(covariant C<T> other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$C<T>;
  }

  @override
  void update(void Function(CBuilder<T>) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$C<T> build() {
    final _$result = _$v ??
        new _$C<T>._(
            c: BuiltValueNullFieldError.checkNotNull(c, 'C', 'c'),
            t: BuiltValueNullFieldError.checkNotNull(t, 'C', 't'));
    replace(_$result);
    return _$result;
  }
}

class _$StateA extends StateA {
  @override
  final int b;

  factory _$StateA([void Function(StateABuilder) updates]) =>
      (new StateABuilder()..update(updates)).build() as _$StateA;

  _$StateA._({this.b}) : super._() {
    BuiltValueNullFieldError.checkNotNull(b, 'StateA', 'b');
  }

  @override
  StateA rebuild(void Function(StateABuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  _$StateABuilder toBuilder() => new _$StateABuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is StateA && b == other.b;
  }

  @override
  int get hashCode {
    return $jf($jc(0, b.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('StateA')..add('b', b)).toString();
  }
}

class _$StateABuilder extends StateABuilder {
  _$StateA _$v;

  @override
  int get b {
    _$this;
    return super.b;
  }

  @override
  set b(int b) {
    _$this;
    super.b = b;
  }

  _$StateABuilder() : super._();

  StateABuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      super.b = $v.b;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(covariant StateA other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$StateA;
  }

  @override
  void update(void Function(StateABuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$StateA build() {
    final _$result = _$v ??
        new _$StateA._(
            b: BuiltValueNullFieldError.checkNotNull(b, 'StateA', 'b'));
    replace(_$result);
    return _$result;
  }
}

class _$StateB extends StateB {
  @override
  final int b;
  @override
  final List<int> ints;

  factory _$StateB([void Function(StateBBuilder) updates]) =>
      (new StateBBuilder()..update(updates)).build();

  _$StateB._({this.b, this.ints}) : super._() {
    BuiltValueNullFieldError.checkNotNull(b, 'StateB', 'b');
    BuiltValueNullFieldError.checkNotNull(ints, 'StateB', 'ints');
  }

  @override
  StateB rebuild(void Function(StateBBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  StateBBuilder toBuilder() => new StateBBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is StateB && b == other.b && ints == other.ints;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, b.hashCode), ints.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('StateB')
          ..add('b', b)
          ..add('ints', ints))
        .toString();
  }
}

class StateBBuilder implements Builder<StateB, StateBBuilder>, StateBuilder {
  _$StateB _$v;

  int _b;
  int get b => _$this._b;
  set b(covariant int b) => _$this._b = b;

  List<int> _ints;
  List<int> get ints => _$this._ints;
  set ints(covariant List<int> ints) => _$this._ints = ints;

  StateBBuilder();

  StateBBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _b = $v.b;
      _ints = $v.ints;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(covariant StateB other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$StateB;
  }

  @override
  void update(void Function(StateBBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$StateB build() {
    final _$result = _$v ??
        new _$StateB._(
            b: BuiltValueNullFieldError.checkNotNull(b, 'StateB', 'b'),
            ints:
                BuiltValueNullFieldError.checkNotNull(ints, 'StateB', 'ints'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GenericAdapter extends TypeAdapter<Generic> {
  @override
  final int typeId = 10;

  @override
  Generic read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return (GenericBuilder()).build();
  }

  @override
  void write(BinaryWriter writer, Generic obj) {
    writer..writeByte(0);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GenericAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CAdapter extends TypeAdapter<C> {
  @override
  final int typeId = 10;

  @override
  C read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return (CBuilder()).build();
  }

  @override
  void write(BinaryWriter writer, C obj) {
    writer..writeByte(0);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
