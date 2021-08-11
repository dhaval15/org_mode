import 'org_node.dart';
import 'org_timestamp.dart';

class OrgPlanningLine extends OrgNode {
  OrgPlanningLine({
    required this.timestamps,
  });

  final List<OrgTimestamp> timestamps;

  @override
  List<OrgNode> get children => timestamps;

  @override
  String toString() => 'OrgPlanningLine';

  @override
  String toOrg() {
    return '${timestamps.map((e) => e.toOrg()).join(' ')}\n';
  }
}
