import 'org_node.dart';

class OrgMacroReference extends OrgNode {
  OrgMacroReference(this.content);

  final String content;

  @override
  String toString() => 'OrgMacroReference';

  @override
  String toOrg() {
    return content;
  }
}
