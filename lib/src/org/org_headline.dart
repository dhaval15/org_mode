import 'org_node.dart';
import 'org_content.dart';
import '../util/util.dart';

class OrgHeadline extends OrgNode {
  OrgHeadline(
    this.stars,
    this.keyword,
    this.priority,
    this.title,
    this.rawTitle, [
    Iterable<String>? tags,
  ]) : tags = List.unmodifiable(tags ?? const <String>[]);
  final String stars;
  final String? keyword;
  final String? priority;
  final OrgContent? title;

  // For resolving links
  final String? rawTitle;
  final List<String> tags;

  // -1 for trailing space
  int get level => stars.length - 1;

  @override
  List<OrgNode> get children => title == null ? const [] : [title!];

  @override
  String toString() => 'OrgHeadline';

  @override
  String toOrg() {
    return '${stars}${_prettyKeyword}${_prettyPriority}$rawTitle ${_prettyTags}';
  }

  String get _prettyKeyword =>
      keyword == null || keyword!.isEmpty ? '' : '$keyword ';

  String get _prettyPriority =>
      priority == null || priority!.isEmpty ? '' : '$priority ';

  String get _prettyTags {
    if (tags.isEmpty) return '';
    final buffer = StringBuffer();
    for (final tag in tags) {
      buffer.write(':');
      buffer.write(tag);
    }
    buffer.write(':');
    return buffer.toString();
  }
}
