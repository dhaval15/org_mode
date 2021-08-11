import 'org_node.dart';
import 'org_content.dart';

abstract class OrgListItem extends OrgNode {
  OrgListItem(this.indent, this.bullet, this.checkbox, this.body);

  final String indent;
  final String bullet;
  final String? checkbox;
  final OrgContent? body;

  @override
  List<OrgNode> get children => body == null ? const [] : [body!];

  @override
  String toString() => runtimeType.toString();
}
