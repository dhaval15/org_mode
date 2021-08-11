import 'org_node.dart';

class OrgEntity extends OrgNode {
  OrgEntity(this.leading, this.name, this.trailing);

  final String leading;
  final String name;
  final String trailing;

  @override
  String toOrg() {
    return '$leading $name $trailing';
  }
}
