import '../parser/parser.dart';
import 'org_tree.dart';
import 'org_content.dart';
import 'org_section.dart';

final org = OrgParserDefinition().build();

class OrgDocument extends OrgTree {
  factory OrgDocument.parse(String text) =>
      org.parse(text).value as OrgDocument;

  OrgDocument(OrgContent? content, Iterable<OrgSection> sections)
      : super(content, sections);

  @override
  int get level => 0;

  @override
  String toString() => 'OrgDocument';

  @override
  String toOrg() {
    return '''${_prettyContent}${sections.map((e) => e.toOrg()).join('\n').replaceAll(RegExp('\\n+'), '\n')}''';
  }

  String get _prettyContent => content != null ? '${content!.toOrg()}\n' : '';
}
