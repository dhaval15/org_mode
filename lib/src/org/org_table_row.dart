import 'org_node.dart';
import 'org_content.dart';

abstract class OrgTableRow extends OrgNode {
  OrgTableRow(this.indent);

  final String indent;

  @override
  String toString() => runtimeType.toString();
}

class OrgTableDividerRow extends OrgTableRow {
  OrgTableDividerRow(String indent) : super(indent);

  @override
  String toString() => 'OrgTableDividerRow';

  @override
  String toOrg() {
    return '------';
  }
}

class OrgTableCellRow extends OrgTableRow {
  OrgTableCellRow(String indent, Iterable<OrgContent> cells)
      : cells = List.unmodifiable(cells),
        super(indent);

  final List<OrgContent> cells;

  @override
  List<OrgNode> get children => cells;

  int get cellCount => cells.length;

  @override
  String toString() => 'OrgTableCellRow';

  @override
  String toOrg() {
    return children.map((e) => e.toOrg()).join('|');
  }
}
