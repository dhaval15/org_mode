import 'org_content.dart';
import 'org_footnote_reference.dart';
import 'org_node.dart';

class OrgFootnote extends OrgNode {
  OrgFootnote(this.marker, this.content);

  final OrgFootnoteReference marker;
  final OrgContent content;

  @override
  List<OrgNode> get children => [marker, content];

  @override
  String toString() => 'OrgFootnote';

  @override
  String toOrg() {
    return '${marker.toOrg()} : ${content.toOrg()}';
  }
}
