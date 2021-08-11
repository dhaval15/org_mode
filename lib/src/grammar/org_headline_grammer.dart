import '../util/util.dart';
import 'package:petitparser/petitparser.dart';

import 'grammar.dart';

class OrgHeadlineGrammarDefinition extends GrammarDefinition {
  final List<String> todoKeywords;

  OrgHeadlineGrammarDefinition(this.todoKeywords);

  @override
  Parser start() => headline();

  Parser headline() => drop(ref0(_headline), [-1]);

  Parser _headline() =>
      ref0(stars).trim() &
      ref0(todoKeyword).trim().optional() &
      ref0(priority).trim().optional() &
      ref0(title).optional() &
      ref0(tags).optional() &
      lineEnd();

  Parser stars() =>
      (lineStart() & char('*').plus() & char(' ')).flatten('Stars expected');

  Parser todoKeyword() {
    return todoKeywords.fold<Parser<dynamic>>(string('TODO'),
        (previousValue, element) => previousValue.or(string(element)));
  }

  Parser priority() => string('[#') & letter() & char(']');

  Parser title() {
    final limit = ref0(tags) | lineEnd();
    return _textRun(limit).plusLazy(limit);
  }

  Parser tags() =>
      string(' :') &
      ref0(tag).separatedBy(char(':'), includeSeparators: false) &
      char(':') &
      lineEnd().and();

  Parser tag() => pattern('a-zA-Z0-9_@#%').plus().flatten('Tags expected');
}

Parser _textRun([Parser? limit]) {
  final definition = OrgContentGrammarDefinition();
  final args = limit == null ? const <Object>[] : [limit];
  return definition.build(start: definition.textRun, arguments: args);
}
