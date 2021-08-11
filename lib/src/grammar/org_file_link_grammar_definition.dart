import 'package:petitparser/petitparser.dart';

class OrgFileLinkGrammarDefinition extends GrammarDefinition {
  @override
  Parser start() =>
      ref0(scheme) &
      ref0(body) &
      (string('::') & ref0(extra)).pick(1).optional();

  Parser scheme() =>
      (string('file:') | anyOf('/.').and()).flatten('Expected link scheme');

  Parser body() =>
      any().plusLazy(string('::') | endOfInput()).flatten('Expected link body');

  Parser extra() => any().star().flatten('Expected link extra');
}
