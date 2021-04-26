const template = Template();
const constructor = Constructor();
const builderTemplate = BuilderTemplate();
const member = Member();

class Template {
  const Template({this.hiveType});
  final int hiveType;
}

class Union {
  const Union(this.members);
  final Set<Type> members;
}

class Constructor {
  const Constructor([this.name = '']);
  final String name;
}

class BuilderTemplate {
  const BuilderTemplate();
}

class Member {
  const Member();
}
