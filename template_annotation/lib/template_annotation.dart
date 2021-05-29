const template = Template();
const constructor = Constructor();
const builderTemplate = BuilderTemplate();

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
