import 'org_node.dart';

class OrgContent extends OrgNode {
  OrgContent(Iterable<OrgNode> children)
      : children = List.unmodifiable(children);

  @override
  final List<OrgNode> children;

  @override
  String toString() => 'OrgContent';

  @override
  String toOrg() {
    return children.map((e) => e.toOrg()).join('');
  }
}
