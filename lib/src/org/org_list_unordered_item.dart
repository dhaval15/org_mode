import 'org_list_item.dart';
import 'org_node.dart';
import 'org_content.dart';

class OrgListUnorderedItem extends OrgListItem {
  OrgListUnorderedItem(
    String indent,
    String bullet,
    String? checkbox,
    this.tag,
    this.tagDelimiter,
    OrgContent? body,
  )   : assert(tag == null && tagDelimiter == null ||
            tag != null && tagDelimiter != null),
        super(indent, bullet, checkbox, body);

  final OrgContent? tag;
  final String? tagDelimiter;

  @override
  List<OrgNode> get children => [if (tag != null) tag!, ...super.children];

  @override
  String toString() => 'OrgListUnorderedItem';

  @override
  String toOrg() {
    return '+ ${body?.toOrg() ?? ''}';
  }
}
