const template = Template();
const constructor = Constructor();
const builderTemplate = BuilderTemplate();
const method = Method();
const getter = Getter();
const setter = Setter();
const specified = SerializationSpec(
  specifiedFromJson: true,
  specifiedToJson: true,
);
const unspecified = SerializationSpec();

class Template {
  const Template({this.hiveType});
  final int hiveType;
}

class Union {
  const Union(this.members, {this.afix});
  final Set<Type> members;
  final String afix;
}

class Constructor {
  const Constructor([this.name = '']);
  final String name;
}

class BuilderTemplate {
  const BuilderTemplate([this.templateClass]);
  final Type templateClass;
}

class MixTo {
  const MixTo(this.type);
  final Type type;
}

class Method {
  const Method({this.name});
  final String name;
}

class Acessor extends Method {
  const Acessor._({String name}) : super(name: name);
}

class Getter extends Acessor {
  const Getter({String name}) : super._(name: name);
}

class Setter extends Acessor {
  const Setter({String name}) : super._(name: name);
}

class SerializationSpec {
  const SerializationSpec({
    this.specifiedToJson = false,
    this.specifiedFromJson = false,
  });
  final bool specifiedToJson;
  final bool specifiedFromJson;
}
