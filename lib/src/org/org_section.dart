import 'org_content.dart';
import 'org_tree.dart';
import 'org_headline.dart';
import 'org_node.dart';

class OrgSection extends OrgTree {
  OrgSection(
    this.headline,
    OrgContent? content, [
    Iterable<OrgSection>? sections,
  ]) : super(content, sections);
  final OrgHeadline headline;

  @override
  List<OrgNode> get children => [headline, ...super.children];

  @override
  int get level => headline.level;

  bool get isEmpty => content == null && sections.isEmpty;

  OrgSection copyWith({
    OrgHeadline? headline,
    OrgContent? content,
    Iterable<OrgSection>? sections,
  }) =>
      OrgSection(
        headline ?? this.headline,
        content ?? this.content,
        sections ?? this.sections,
      );

  @override
  String toString() => 'OrgSection';

  @override
  String toOrg() {
    return '''${headline.toOrg()}
${content?.toOrg() ?? ''}
${sections.map((e) => e.toOrg()).join('')}''';
  }
}
