import '../parser/parser.dart';

class OrgFileLink {
  factory OrgFileLink.parse(String text) =>
      orgFileLink.parse(text).value as OrgFileLink;

  OrgFileLink(this.scheme, this.body, this.extra);
  final String? scheme;
  final String body;
  final String? extra;

  bool get isRelative =>
      body.startsWith('.') || scheme != null && !body.startsWith('/');
}

final orgFileLink = OrgFileLinkParserDefinition().build();
