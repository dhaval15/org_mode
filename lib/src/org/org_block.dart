import 'org_node.dart';
import 'indented_element.dart';

class OrgBlock extends OrgNode with IndentedElement {
  OrgBlock(this.indent, this.header, this.body, this.footer, this.trailing);

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
  String toString() => 'OrgBlock';

  @override
  String toOrg() {
    return '''$header
${body.toOrg()}
$footer''';
  }
}
