import 'package:petitparser/petitparser.dart';
import '../util/util.dart';

class OrgContentGrammarDefinition extends GrammarDefinition {
  @override
  Parser start() => ref0(element).star().end();

  Parser element() =>
      ref0(block) |
      ref0(greaterBlock) |
      ref0(latexBlock) |
      ref0(affiliatedKeyword) |
      ref0(fixedWidthArea) |
      ref0(table) |
      ref0(list) |
      ref0(planningLine) |
      ref0(drawer) |
      ref0(footnote) |
      ref0(paragraph);

  Parser paragraph() =>
      ref0(indent).flatten('Paragraph indent expected') &
      ref1(textRun, ref0(nonParagraphElements)).plusLazy(ref0(paragraphEnd));

  Parser nonParagraphElements() =>
      element()..replace(ref0(paragraph), noOpFail());

  Parser paragraphEnd() => endOfInput() | ref0(nonParagraphElements);

  Parser textRun([Parser? limit]) => ref0(object) | ref1(plainText, limit);

  Parser object() =>
      ref0(link) |
      ref0(markups) |
      ref0(entity) |
      ref0(timestamp) |
      ref0(keyword) |
      ref0(macroReference) |
      ref0(footnoteReference) |
      ref0(latexInline);

  Parser plainText([Parser? limit]) {
    var fullLimit = ref0(object) | endOfInput();
    if (limit != null) {
      fullLimit |= limit;
    }
    return any().plusLazy(fullLimit).flatten('Plain text expected');
  }

  Parser link() => ref0(regularLink) | ref0(plainLink);

  Parser plainLink() => ref0(_plainLink).flatten('Plain link expected');

  Parser _plainLink() => ref0(protocol) & char(':') & ref0(path2);

  // Built-in link types only
  Parser protocol() =>
      string('https') |
      string('http') |
      string('doi') |
      string('file') |
      string('attachment') |
      string('docview') |
      string('id') |
      string('news') |
      string('mailto') |
      string('mhe') |
      string('rmail') |
      string('gnus') |
      string('bbdb') |
      string('irc') |
      string('help') |
      string('info') |
      string('shell') |
      string('elisp');

  Parser path2() => (whitespace() | anyOf('()<>')).neg().plus();

  /*
    Default value of org-link-brackets-re (org-20200302):

    \[\[\(\(?:[^][\]\|\\\(?:\\\\\)*[][]\|\\+[^][]\)+\)]\(?:\[\(\(?:.\|\n\)+?\)]\)?]

    Or in rx form:

    (seq "[["
     (group
      (one-or-more
       (or (not (any "[\\]"))
           (seq "\\"
                (zero-or-more "\\\\")
                (any "[]"))
           (seq (one-or-more "\\")
                (not (any "[]"))))))
     "]"
     (opt "["
          (group
           (+? anything))
          "]")
     "]")
   */

  Parser regularLink() =>
      char('[') & ref0(linkPart) & ref0(linkDescription).optional() & char(']');

  Parser linkPart() => char('[') & ref0(linkPartBody) & char(']');

  Parser linkPartBody() =>
      // Join instead of flatten to drop escape chars
      ref0(linkChar).plusLazy(char(']')).map((items) => items.join());

  Parser linkChar() => ref0(linkEscape).castList().pick(1) | any();

  Parser linkEscape() => char(r'\') & anyOf(r'[]\');

  Parser linkDescription() =>
      char('[') &
      // Join instead of flatten to drop escape chars
      ref0(anyChar).plusLazy(string(']]')).map((items) => items.join()) &
      char(']');

  Parser anyChar() => ref0(escape).castList().pick(0) | any();

  Parser escape() => any() & char('\u200b'); // zero-width space

  Parser markups() =>
      ref0(bold) |
      ref0(verbatim) |
      ref0(italic) |
      ref0(strikeThrough) |
      ref0(underline) |
      ref0(code);

  Parser bold() => ref1(markup, '*');

  Parser verbatim() => ref1(markup, '=');

  Parser italic() => ref1(markup, '/');

  Parser strikeThrough() => ref1(markup, '+');

  Parser underline() => ref1(markup, '_');

  Parser code() => ref1(markup, '~');

  Parser markup(String marker) => resultPredicate(
        drop(ref1(_markup, marker), [0, -1]),
        (result, from, to) {
          for (var count = 0, i = from; i < to; i++) {
            // Ensure at most one LF (U+000A) in markup span
            if (result.codeUnitAt(i) == 0x000A && ++count > 1) {
              return false;
            }
          }
          return true;
        },
      );

  Parser _markup(String marker) =>
      (startOfInput() | was(ref0(preMarkup))) &
      char(marker) &
      ref1(markupContents, marker).flatten('Markup content expected') &
      char(marker) &
      (ref0(postMarkup).and() | endOfInput());

  Parser markupContents(String marker) =>
      ref0(markupBorder).and() & ref1(markupBody, marker) & ref0(markupBorder);

  // The following markupBorder and pre/postMarkup definitions differ from the
  // org-syntax.org document; they have been updated based on the definition of
  // `org-emphasis-regexp-components' in org-20200302.

  Parser markupBorder() => whitespace().neg();

  // TODO(aaron): Simplify this?
  Parser markupBody(String marker) => ref0(anyChar)
      .starLazy(
        ref0(markupBorder) & char(marker) & (ref0(postMarkup) | endOfInput()),
      )
      // Join instead of flatten to drop escape chars
      .map((items) => items.join());

  Parser preMarkup() => whitespace() | anyOf('-(\'"{');

  Parser postMarkup() => whitespace() | anyOf('-.,:!?;\'")}[');

  // Adapted from `org-fontify-entities' in org-20200716

  Parser entity() =>
      char(r'\') &
      ref0(entityBody).flatten('Entity body expected') &
      ref0(entityEnd).flatten('Entity end expected');

  Parser entityBody() =>
      string('there4') |
      (string('sup') & anyOf('123')) |
      (string('frac') & anyOf('13') & anyOf('24')) |
      pattern('a-zA-Z').plus();

  Parser entityEnd() =>
      // TODO(aaron): PetitParser's letter() is not the same as Emacs's [:alpha:]
      lineEnd().and() | string('{}') | (letter() | char('\n')).not();

  Parser macroReference() =>
      string('{{{') &
      ref0(macroReferenceKey).flatten('Macro reference key expected') &
      // TODO(aaron): Actually parse arguments
      ref0(macroReferenceArgs)
          .optional()
          .flatten('Macro reference args expected') &
      string('}}}');

  // See `org-element-macro-parser'
  Parser macroReferenceKey() =>
      pattern('a-zA-Z') & pattern('-A-Za-z0-9_').plus();

  Parser macroReferenceArgs() =>
      char('(') & any().starLazy(char(')')) & char(')');

  Parser affiliatedKeyword() => indented(
        ref0(affiliatedKeywordBody).flatten('Affiliated keyword body expected'),
      );

  // TODO(aaron): Actually parse real keywords
  Parser affiliatedKeywordBody() => string('#+') & whitespace().neg().plus();

  Parser fixedWidthArea() => ref0(fixedWidthLine).plus() & ref0(blankLines);

  Parser fixedWidthLine() =>
      ref0(indent).flatten('Fixed-width line indent expected') &
      string(': ') &
      ref0(lineTrailing).flatten('Trailing line content expected');

  // TODO(aaron): Handle arbitrary blocks? See LatexBlockParser
  Parser block() =>
      ref1(namedBlock, 'comment') |
      ref1(namedBlock, 'example') |
      ref1(namedBlock, 'export') |
      ref0(srcBlock) |
      ref1(namedBlock, 'verse');

  Parser srcBlock() => indented(
        ref0(srcBlockStart) &
            ref1(namedBlockContent, 'src') &
            ref1(namedBlockEnd, 'src'),
      );

  Parser namedBlock(String name) => indented(
        ref1(namedBlockStart, name) &
            ref1(namedBlockContent, name) &
            ref1(namedBlockEnd, name),
      );

  Parser srcBlockStart() =>
      stringIgnoreCase('#+begin_src') &
      ref0(srcBlockLanguageToken).optional() &
      ref0(lineTrailing).flatten('Trailing line content expected');

  Parser srcBlockLanguageToken() =>
      ref0(insignificantWhitespace)
          .plus()
          .flatten('Separating whitespace expected') &
      whitespace().neg().plus().flatten('Language token expected');

  Parser namedBlockStart(String name) =>
      stringIgnoreCase('#+begin_$name') &
      ref0(lineTrailing).flatten('Trailing line content expected');

  Parser namedBlockContent(String name) => ref1(namedBlockEnd, name)
      .neg()
      .star()
      .flatten('Named block content expected');

  Parser namedBlockEnd(String name) =>
      ref0(indent).flatten('Block end indent expected') &
      stringIgnoreCase('#+end_$name');

  Parser greaterBlock() =>
      ref1(namedGreaterBlock, 'quote') | ref1(namedGreaterBlock, 'center');

  Parser namedGreaterBlock(String name) => indented(
        ref1(namedBlockStart, name) &
            namedGreaterBlockContent(name) &
            ref1(namedBlockEnd, name),
      );

  Parser namedGreaterBlockContent(String name) {
    final end = ref1(namedBlockEnd, name);
    return ref1(textRun, end).starLazy(end);
  }

  Parser indent() => lineStart() & ref0(insignificantWhitespace).star();

  Parser indented(Parser parser) =>
      ref0(indent).flatten('Indent expected') &
      parser &
      (ref0(lineTrailing) & ref0(blankLines))
          .flatten('Trailing line content expected');

  Parser blankLines() =>
      Token.newlineParser().star().flatten('Blank lines expected');

  Parser lineTrailing() => any().starLazy(lineEnd()) & lineEnd();

  Parser lineTrailingWhitespace() =>
      ref0(insignificantWhitespace).starLazy(lineEnd()) & lineEnd();

  Parser insignificantWhitespace() => anyOf(' \t');

  Parser table() => ref0(tableLine).plus() & blankLines();

  Parser tableLine() => ref0(tableRow) | ref0(tableDotElDivider);

  Parser tableRow() => ref0(tableRowRule) | ref0(tableRowStandard);

  Parser tableRowStandard() =>
      ref0(indent).flatten('Table row indent expected') &
      char('|') &
      ref0(tableCell).star() &
      ref0(lineTrailing).flatten('Trailing line content expected');

  Parser tableCell() =>
      ref0(tableCellLeading).flatten('Cell leading content expected') &
      ref0(tableCellContents) &
      ref0(tableCellTrailing).flatten('Cell trailing content expected');

  Parser tableCellLeading() => char(' ').star();

  Parser tableCellTrailing() => char(' ').star() & char('|');

  Parser tableCellContents() {
    final end = ref0(tableCellTrailing) | lineEnd();
    return ref1(textRun, end).starLazy(end);
  }

  Parser tableRowRule() =>
      ref0(indent).flatten('Table row rule indent expected') &
      (string('|-') & ref0(lineTrailing))
          .flatten('Trailing line content expected');

  Parser tableDotElDivider() =>
      ref0(indent).flatten('Table.el divider indent expected') &
      (string('+-') & anyOf('+-').star()).flatten('Table divider expected') &
      ref0(lineTrailing).flatten('Trailing line content expected');

  Parser timestamp() =>
      ref0(timestampDiary) |
      ref1(timestampRange, true) |
      ref1(timestampRange, false) |
      ref1(timestampSimple, true) |
      ref1(timestampSimple, false);

  Parser timestampDiary() => string('<%%') & ref0(sexp) & char('>');

  // TODO(aaron): Bother with a real Elisp parser here?
  Parser sexp() => ref0(sexpAtom) | ref0(sexpList);

  Parser sexpAtom() =>
      (anyOf('()') | whitespace()).neg().plus().flatten('Expected atom');

  Parser sexpList() => char('(') & ref0(sexp).trim().star() & char(')');

  Parser timestampSimple(bool active) =>
      (active ? char('<') : char('[')) &
      ref0(date) &
      ref0(time).trim().optional() &
      ref0(repeaterOrDelay).trim().repeat(0, 2) &
      (active ? char('>') : char(']'));

  Parser timestampRange(bool active) =>
      ref1(timestampTimeRange, active) | ref1(timestampDateRange, active);

  Parser timestampTimeRange(bool active) =>
      (active ? char('<') : char('[')) &
      ref0(date) &
      (ref0(time) & char('-') & ref0(time)).trim() &
      ref0(repeaterOrDelay).trim().repeat(0, 2) &
      (active ? char('>') : char(']'));

  Parser timestampDateRange(bool active) =>
      ref1(timestampSimple, active) &
      char('-').repeat(1, 3).flatten('Expected timestamp separator') &
      ref1(timestampSimple, active);

  Parser date() =>
      ref0(year) &
      char('-') &
      ref0(month) &
      char('-') &
      ref0(day) &
      dayName().trim();

  Parser year() => digit().times(4).flatten('Expected year');

  Parser month() => digit().times(2).flatten('Expected month');

  Parser day() => digit().times(2).flatten('Expected day');

  Parser dayName() => (whitespace() | anyOf('+-]>\n') | digit())
      .neg()
      .plus()
      .flatten('Expected day name');

  Parser time() => ref0(hours) & char(':') & ref0(minutes);

  Parser hours() => digit().repeat(1, 2).flatten('Expected hours');

  Parser minutes() => digit().times(2).flatten('Expected minutes');

  Parser repeaterOrDelay() =>
      ref0(repeaterMark) &
      digit().plus().flatten('Expected number') &
      ref0(repeaterUnit);

  Parser repeaterMark() =>
      string('++') | string('.+') | string('--') | anyOf('+-');

  Parser repeaterUnit() => anyOf('hdwmy');

  Parser keyword() => ref0(_keyword).flatten('Expected keyword');

  Parser _keyword() =>
      string('CREATED_AT:') |
      string('UPDATED_AT:') |
      string('SCHEDULED:') |
      string('DEADLINE:') |
      string('CLOCK:') |
      string('CLOSED:');

  Parser planningLine() => indented(ref0(_planningLine));

  Parser _planningLine() {
    final limit = lineEnd() | endOfInput();
    return ref0(keyword) & ref1(textRun, limit).plusLazy(limit);
  }

  Parser list() => ref0(listItem).plus() & ref0(blankLines);

  Parser listItem() => ref0(listItemUnordered) | ref0(listItemOrdered);

  Parser listItemUnordered() =>
      (ref0(indent) & ref0(listUnorderedBullet).and())
          .flatten('List item (unordered) indent expected') &
      indentedRegion(
        parser: ref0(listUnorderedBullet).flatten('Unordered bullet expected') &
            ref0(listCheckBox).trim(char(' ')).optional() &
            ref0(listTag).trim(char(' ')).optional() &
            ref0(listItemContents),
        indentAdjust: 1,
        maxSeparatingLineBreaks: 2,
      );

  Parser listUnorderedBullet() => anyOf('*-+') & char(' ');

  Parser listTag() {
    final end = string(' ::') & (lineEnd() | char(' '));
    final limit = end | lineEnd();
    return ref1(textRun, limit).plusLazy(limit) &
        end.flatten('List tag end expected');
  }

  Parser listItemOrdered() =>
      (ref0(indent) & ref0(listOrderedBullet).and())
          .flatten('List item (ordered) indent expected') &
      indentedRegion(
        parser: ref0(listOrderedBullet) &
            ref0(listCounterSet).trim(char(' ')).optional() &
            ref0(listCheckBox).trim(char(' ')).optional() &
            ref0(listItemContents),
        indentAdjust: 1,
        maxSeparatingLineBreaks: 2,
      );

  Parser listOrderedBullet() =>
      (digit().plus().flatten('Bullet number expected') | letter()) &
      anyOf('.)') &
      char(' ');

  Parser listCounterSet() =>
      string('[@') &
      digit().plus().flatten('Counter set number expected') &
      char(']');

  Parser listCheckBox() => char('[') & anyOf(' -X') & char(']');

  Parser listItemContents() {
    final end =
        ref0(listItemAnyStart) | ref0(nonParagraphElements) | endOfInput();
    return (ref0(element) | ref1(textRun, end)).star();
  }

  Parser listItemAnyStart() =>
      ref0(indent) & (ref0(listUnorderedBullet) | ref0(listOrderedBullet));

  Parser drawer() => indented(
        ref0(drawerStart) & ref0(drawerContent) & ref0(drawerEnd),
      );

  Parser drawerStart() =>
      char(':') &
      pattern('a-zA-Z0-9_@#%')
          .plusLazy(char(':'))
          .flatten('Drawer start expected') &
      char(':') &
      lineTrailingWhitespace().flatten('Trailing whitespace expected');

  Parser drawerContent() {
    final end = ref0(drawerEnd);
    return (ref0(property) | ref0(nonDrawerElements) | ref1(textRun, end))
        .starLazy(end);
  }

  Parser nonDrawerElements() =>
      nonParagraphElements()..replace(ref0(drawer), noOpFail());

  Parser drawerEnd() =>
      ref0(indent).flatten('Drawer end indent expected') &
      (stringIgnoreCase(':END:') & ref0(insignificantWhitespace).star())
          .flatten('Drawer end expected');

  Parser property() =>
      ref0(indent).flatten('Property indent expected') &
      ref0(propertyKey) &
      ref0(propertyValue) &
      (lineEnd() & ref0(blankLines)).flatten('Trailing whitespace expected');

  Parser propertyKey() =>
      char(':') &
      any()
          .plusLazy(
            char(':') & ref0(insignificantWhitespace).plus() & lineEnd().not(),
          )
          .flatten('Property name expected') &
      char(':');

  Parser propertyValue() =>
      any().plusLazy(lineEnd()).flatten('Property value expected');

  Parser footnoteReference() =>
      ref0(footnoteReferenceNamed) | ref0(footnoteReferenceInline);

  Parser footnoteReferenceNamed() =>
      string('[fn:') & ref0(footnoteName) & char(']');

  Parser footnoteReferenceInline() =>
      string('[fn:') &
      ref0(footnoteName).optional() &
      char(':') &
      ref0(footnoteDefinition) &
      char(']');

  Parser footnoteName() =>
      pattern('-_A-Za-z0-9').plus().flatten('Footnote name expected');

  Parser footnoteDefinition() => textRun(char(']')).plusLazy(char(']'));

  Parser footnote() => drop(ref0(_footnote), [0]);

  Parser _footnote() =>
      lineStart() &
      ref0(footnoteReferenceNamed) &
      ref0(footnoteBody) &
      Token.newlineParser()
          .repeat(0, 3)
          .flatten('Footnote trailing content expected');

  Parser footnoteBody() {
    final end = endOfInput() |
        lineStart() & ref0(footnoteReferenceNamed) |
        Token.newlineParser().repeat(3);
    return ref1(textRun, end).plusLazy(end);
  }

  Parser latexBlock() => indented(LatexBlockParser());

  Parser latexInline() =>
      ref2(_latexInline, r'$$', r'$$') |
      ref2(_latexInline, r'\(', r'\)') |
      ref2(_latexInline, r'\[', r'\]') |
      drop(_markup(r'$'), [0, -1]);

  Parser _latexInline(String start, String end) =>
      string(start) &
      string(end).neg().plusLazy(string(end)).flatten('LaTeX body expected') &
      string(end);
}
