import 'org_node.dart';

class OrgLink extends OrgNode {
  OrgLink(this.location, this.description);
  final String location;
  final String? description;

  @override
  String toString() => 'OrgLink';

  @override
  String toOrg() {
    return '[$description : $location]';
  }
}
