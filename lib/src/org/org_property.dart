import 'org_node.dart';
import 'indented_element.dart';

class OrgProperty extends OrgNode with IndentedElement {
  OrgProperty(this.indent, this.key, this.value, this.trailing);

  @override
  final String indent;
  final String key;
  final String value;
  @override
  final String trailing;

  @override
  String toString() => 'OrgProperty';

  @override
  String toOrg() {
    return '$key $value';
  }
}
