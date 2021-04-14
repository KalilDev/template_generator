library template_generator;

import 'package:build/build.dart';
import 'src/generator.dart';
import 'package:source_gen/source_gen.dart';

Builder templateBuilder(BuilderOptions options) => PartBuilder(
      [TemplateGenerator()],
      '.t.dart',
    );
