import 'org_node.dart';

class OrgKeyword extends OrgNode {
  OrgKeyword(this.content);

  final String content;

  @override
  String toString() => 'OrgKeyword';

  @override
  String toOrg() {
    return content;
  }
}
