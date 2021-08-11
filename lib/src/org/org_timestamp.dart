import '../util/util.dart';
import 'org_node.dart';

class OrgTimestamp extends OrgNode {
  final String keyword;
  final Timestamp timestamp;

  OrgTimestamp({
    this.keyword = '',
    required this.timestamp,
  });

  @override
  String toString() => 'OrgTimestamp';

  String get _prettyKeyword => keyword.isEmpty ? '' : '${keyword} ';

  OrgTimestamp withKeyword(String keyword) =>
      OrgTimestamp(timestamp: timestamp, keyword: keyword);

  @override
  String toOrg() {
    return '${_prettyKeyword}${timestamp.toOrg()}';
  }
}
