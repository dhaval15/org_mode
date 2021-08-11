import 'org_node.dart';

class OrgLatexBlock extends OrgNode {
  OrgLatexBlock(
    this.environment,
    this.leading,
    this.begin,
    this.content,
    this.end,
    this.trailing,
  );

  final String environment;
  final String leading;
  final String begin;
  final String content;
  final String end;
  final String trailing;

  @override
  String toString() => 'OrgLatexBlock';

  @override
  String toOrg() {
    return '''$environment
$content''';
  }
}
