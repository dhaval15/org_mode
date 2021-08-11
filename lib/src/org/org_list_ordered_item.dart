import 'org_list_item.dart';
import 'org_content.dart';

class OrgListOrderedItem extends OrgListItem {
  OrgListOrderedItem(
    String indent,
    String bullet,
    this.counterSet,
    String? checkbox,
    OrgContent? body,
  ) : super(indent, bullet, checkbox, body);

  final String? counterSet;

  @override
  String toString() => 'OrgListOrderedItem';

  @override
  String toOrg() {
    return '+ ${body?.toOrg() ?? ''}';
  }
}
