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
      ..add(Foo.serializer))
    .build();
Serializer<Foo> _$fooSerializer = new _$FooSerializer();
Serializer<Bar> _$barSerializer = new _$BarSerializer();
Serializer<A> _$aSerializer = new _$ASerializer();
Serializer<B> _$bSerializer = new _$BSerializer();
Serializer<C<Object>> _$cSerializer = new _$CSerializer();

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

class _$Foo extends Foo {
  @override
  final int a;

  factory _$Foo([void Function(FooBuilder) updates]) =>
      (new FooBuilder()..update(updates)).build();

  _$Foo._({this.a}) : super._() {
    BuiltValueNullFieldError.checkNotNull(a, 'Foo', 'a');
  }

  @override
  Foo rebuild(void Function(FooBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FooBuilder toBuilder() => new FooBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Foo && a == other.a;
  }

  @override
  int get hashCode {
    return $jf($jc(0, a.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Foo')..add('a', a)).toString();
  }
}

class FooBuilder implements Builder<Foo, FooBuilder> {
  _$Foo _$v;

  int _a;
  int get a => _$this._a;
  set a(int a) => _$this._a = a;

  FooBuilder();

  FooBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _a = $v.a;
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
    final _$result = _$v ??
        new _$Foo._(a: BuiltValueNullFieldError.checkNotNull(a, 'Foo', 'a'));
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

abstract class ABCBuilder {
  void replace(ABC other);
  void update(void Function(ABCBuilder) updates);
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new