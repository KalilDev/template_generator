const template = Template();
const constructor = Constructor();
const builderTemplate = BuilderTemplate();
const member = Member();
const getter = Getter();
const memoizedGetter = Getter(true);

class Template {
  const Template({this.hiveType});
  final int hiveType;
}

class Union {
  const Union(this.members, {this.afix, this.destructure = true});
  final Set<Type> members;
  final String afix;
  final bool destructure;
}

class Constructor {
  const Constructor([this.name = '']);
  final String name;
}

class BuilderTemplate {
  const BuilderTemplate([this.templateClass]);
  final Type templateClass;
}

class Member {
  const Member();
}

class Getter extends Member {
  final bool memoized;

  const Getter([this.memoized = false]);
}
