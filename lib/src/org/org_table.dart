import 'dart:math';
import 'org_node.dart';
import 'indented_element.dart';
import 'org_table_row.dart';
import 'org_content.dart';
import 'org_plain_text.dart';

class OrgTable extends OrgNode with IndentedElement {
  OrgTable(Iterable<OrgTableRow> rows, this.trailing)
      : rows = List.unmodifiable(rows);

  final List<OrgTableRow> rows;

  @override
  List<OrgNode> get children => rows;

  @override
  String get indent => rows.isEmpty ? '' : rows.first.indent;
  @override
  final String trailing;

  bool get rectangular =>
      rows
          .whereType<OrgTableCellRow>()
          .map((row) => row.cellCount)
          .toSet()
          .length <
      2;

  int get columnCount =>
      rows.whereType<OrgTableCellRow>().map((row) => row.cellCount).reduce(max);

  bool columnIsNumeric(int colIdx) {
    final cells = rows
        .whereType<OrgTableCellRow>()
        .map((row) => row.cells[colIdx])
        .toList(growable: false);
    final totalCount = cells.length;
    final emptyCount = cells.where(_tableCellIsEmpty).length;
    final nonEmptyCount = totalCount - emptyCount;
    final numberCount = cells.where(_tableCellIsNumeric).length;
    return numberCount / nonEmptyCount >= _orgTableNumberFraction;
  }

  @override
  String toString() => 'OrgTable';

  @override
  String toOrg() {
    return children.map((e) => e.toOrg()).join('\n');
  }
}

bool _tableCellIsNumeric(OrgContent cell) {
  if (cell.children.length == 1) {
    final content = cell.children.first;
    if (content is OrgPlainText) {
      return _orgTableNumberRegexp.hasMatch(content.content);
    }
  }
  return false;
}

bool _tableCellIsEmpty(OrgContent cell) => cell.children.isEmpty;

// Default number-detecting regexp from org-mode 20200504, converted with:
//   (kill-new (rxt-elisp-to-pcre org-table-number-regexp))
final _orgTableNumberRegexp = RegExp(
    r'^([><]?[.\^+\-0-9]*[0-9][:%)(xDdEe.\^+\-0-9]*|[><]?[+\-]?0[Xx][.[:xdigit:]]+|[><]?[+\-]?[0-9]+#[.A-Za-z0-9]+|nan|[u+\-]?inf)$');

// Default fraction of non-empty cells in a column to make the column
// right-aligned. From org-mode 20200504.
const _orgTableNumberFraction = 0.5;
