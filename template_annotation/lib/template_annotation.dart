const template = Template();

class Template {
  const Template({this.hiveType});
  final int hiveType;
}

class Union {
  const Union(this.members);
  final Set<Type> members;
}
