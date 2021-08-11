import 'org_node.dart';
import 'org_content.dart';

class OrgParagraph extends OrgNode {
  OrgParagraph(this.indent, this.body);

  final String indent;
  final OrgContent body;

  @override
  List<OrgNode> get children => [body];

  @override
  String toString() => 'OrgParagraph';

  @override
  String toOrg() {
    return body.toOrg();
  }
}
