import 'org_node.dart';
import 'indented_element.dart';

class OrgMeta extends OrgNode with IndentedElement {
  OrgMeta(this.indent, this.keyword, this.trailing);

  @override
  final String indent;
  final String keyword;
  @override
  final String trailing;

  @override
  String toString() => 'OrgMeta';

  @override
  String toOrg() {
    return '$keyword $trailing';
  }
}
