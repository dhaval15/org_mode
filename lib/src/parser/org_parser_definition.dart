import 'package:org_mode/org_mode.dart';
import 'package:petitparser/petitparser.dart';
import '../grammar/grammar.dart';
import '../org/org.dart';
import '../util/util.dart';
import 'org_content_parser_definition.dart';

class OrgParserDefinition extends OrgGrammarDefinition {
  final List<String> todoKeywords = [];
  OrgParserDefinition();

  @override
  Parser start() => super.start().map((items) {
        final topContent = items[0] as OrgContent?;
        final sections = items[1] as List;
        return OrgDocument(topContent, List.unmodifiable(sections));
      });

  @override
  Parser document() => super.document().map((items) {
        final firstContent = items[0] as OrgContent?;
        final sections = items[1] as List;
        return [firstContent, _nestSections(sections.cast<OrgSection>())];
      });

  List<OrgSection> _nestSections(List<OrgSection> sections) {
    if (sections.length < 2) {
      return sections;
    }
    final result = <OrgSection>[];
    for (var i = 0; i < sections.length; i++) {
      final parent = sections[i];
      final children = sections
          .sublist(i + 1)
          .takeWhile((item) => item is OrgSection && item.level > parent.level)
          .cast<OrgSection>()
          .toList();
      if (children.isNotEmpty) {
        result.add(parent.copyWith(sections: _nestSections(children)));
        i += children.length;
      } else {
        result.add(parent);
      }
    }
    return result;
  }

  @override
  Parser section() => super.section().map((items) {
        final headline = items[0] as OrgHeadline;
        final content = items[1] as OrgContent?;
        return OrgSection(headline, content);
      });

  @override
  Parser headline() =>
      super.headline().flatten('Headline Expected').map((value) =>
          OrgHeadlineParserDefinition(todoKeywords).build().parse(value).value);

  @override
  Parser content() {
    final _orgContentParser = OrgContentParserDefinition((meta) {
      if (todoKeywords.isEmpty && meta.keyword == '#+TODO:') {
        todoKeywords.addAll(collectTodoKeywords(meta.trailing));
      }
    }).build();
    return super.content().map((value) {
      final res = _orgContentParser.parse(value).value;
      return res;
    });
  }
}
