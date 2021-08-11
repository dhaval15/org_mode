import 'org_node.dart';
import 'indented_element.dart';

class OrgFixedWidthArea extends OrgNode with IndentedElement {
  OrgFixedWidthArea(this.indent, this.content, this.trailing);

  @override
  final String indent;
  final String content;
  @override
  final String trailing;

  @override
  String toString() => 'OrgFixedWidthArea';

  @override
  String toOrg() {
    return '$trailing \n$content';
  }
}
