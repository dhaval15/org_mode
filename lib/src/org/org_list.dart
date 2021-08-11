import 'org_node.dart';
import 'indented_element.dart';
import 'org_list_item.dart';

class OrgList extends OrgNode with IndentedElement {
  OrgList(Iterable<OrgListItem> items, this.trailing)
      : items = List.unmodifiable(items);
  final List<OrgListItem> items;

  @override
  String get indent => items.isEmpty ? '' : items.first.indent;
  @override
  final String trailing;

  @override
  String toString() => 'OrgList';

  @override
  String toOrg() {
    return items.map((e) => e.toOrg()).join('\n');
  }
}
