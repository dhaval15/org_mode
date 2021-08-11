import 'org_content.dart';
import 'org_node.dart';

class OrgFootnoteReference extends OrgNode {
  OrgFootnoteReference.named(String leading, String name, String trailing)
      : this(leading, name, null, null, trailing);

  OrgFootnoteReference(
    this.leading,
    this.name,
    this.definitionDelimiter,
    this.definition,
    this.trailing,
  );

  final String leading;
  final String? name;
  final String? definitionDelimiter;
  final OrgContent? definition;
  final String trailing;

  @override
  List<OrgNode> get children => [if (definition != null) definition!];

  @override
  String toString() => 'OrgFootnoteReference';

  @override
  String toOrg() {
    return definition?.toOrg() ?? '';
  }
}
