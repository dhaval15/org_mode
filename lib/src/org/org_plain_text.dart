import 'org_node.dart';

class OrgPlainText extends OrgNode {
  OrgPlainText(this.content);

  final String content;

  @override
  String toString() => 'OrgPlainText';

  @override
  String toOrg() {
    return content;
  }
}
