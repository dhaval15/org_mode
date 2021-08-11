import 'org_node.dart';
import 'org_section.dart';
import 'org_content.dart';

abstract class OrgTree extends OrgNode {
  OrgTree(this.content, [Iterable<OrgSection>? sections])
      : sections = List.unmodifiable(sections ?? const <OrgSection>[]);
  final OrgContent? content;
  final List<OrgSection> sections;

  @override
  List<OrgNode> get children => [if (content != null) content!, ...sections];

  int get level;

  @override
  String toString() => runtimeType.toString();
}
