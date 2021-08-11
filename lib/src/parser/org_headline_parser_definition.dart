import 'package:org_mode/src/util/util.dart';

import '../grammar/grammar.dart';
import 'package:petitparser/petitparser.dart';
import '../org/org.dart';
import 'org_content_parser_definition.dart';

class OrgHeadlineParserDefinition extends OrgHeadlineGrammarDefinition {
  OrgHeadlineParserDefinition(List<String> keywords) : super(keywords);

  @override
  Parser headline() => super.headline().map((items) {
        final stars = items[0] as String;
        final keyword = items[1] as String?;
        final priority = items[2] as String?;
        final title = items[3] as Token?;
        final tags = items[4] as List?;
        return OrgHeadline(
          stars,
          keyword,
          priority,
          title?.value as OrgContent?,
          title?.input,
          tags?.cast<String>(),
        );
      });

  @override
  Parser title() {
    final limit = ref0(tags) | lineEnd();
    return _textRun(limit)
        .plusLazy(limit)
        .castList<OrgNode>()
        .map((items) => OrgContent(items))
        .token();
  }

  @override
  Parser priority() => super.priority().flatten('Priority expected');

  @override
  Parser tags() => super.tags().castList().pick(1);
}

Parser _textRun([Parser? limit]) {
  final definition = OrgContentParserDefinition((meta) {});
  final args = limit == null ? const <Object>[] : [limit];
  return definition.build(start: definition.textRun, arguments: args);
}
