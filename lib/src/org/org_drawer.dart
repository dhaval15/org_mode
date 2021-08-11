import 'org_node.dart';
import 'indented_element.dart';

class OrgDrawer extends OrgNode with IndentedElement {
  OrgDrawer(this.indent, this.header, this.body, this.footer, this.trailing);

  @override
  final String indent;
  final String header;
  final OrgNode body;
  final String footer;
  @override
  final String trailing;

  @override
  List<OrgNode> get children => [body];

  @override
  String toString() => 'OrgDrawer';

  @override
  String toOrg() {
    return body.toOrg();
  }
}
