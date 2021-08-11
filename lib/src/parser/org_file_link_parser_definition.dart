import 'package:petitparser/petitparser.dart';
import '../grammar/grammar.dart';
import '../org/org.dart';

class OrgFileLinkParserDefinition extends OrgFileLinkGrammarDefinition {
  @override
  Parser start() => super.start().map((values) {
        final scheme = values[0] as String;
        final body = values[1] as String;
        final extra = values[2] as String?;
        return OrgFileLink(
          scheme.isEmpty ? null : scheme,
          body,
          extra,
        );
      });
}
