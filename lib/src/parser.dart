import 'package:org_parser/org_parser.dart';
import 'package:org_parser/src/org.dart';
import 'package:petitparser/petitparser.dart';

class OrgParser extends GrammarParser {
  OrgParser() : super(OrgParserDefinition());
}

class OrgParserDefinition extends OrgGrammarDefinition {
  @override
  Parser document() => super.document().map((items) {
        final firstContent = items[0] as OrgContent;
        final sections = items[1] as List;
        return [firstContent, _nestSections(sections.cast<OrgSection>())];
      });

  List<OrgSection> _nestSections(List<OrgSection> sections) {
    if (sections.length < 2) {
      return sections;
    }
    final result = <OrgSection>[];
    for (var i = 0; i < sections.length; i++) {
      final parent = sections[i];
      final children = sections
          .sublist(i + 1)
          .takeWhile((item) => item is OrgSection && item.level > parent.level)
          .cast<OrgSection>()
          .toList();
      if (children.isNotEmpty) {
        result.add(parent.copyWith(children: _nestSections(children)));
        i += children.length;
      } else {
        result.add(parent);
      }
    }
    return result;
  }

  @override
  Parser section() => super.section().map((items) {
        final headline = items[0] as OrgHeadline;
        final content = items[1] as OrgContent;
        return OrgSection(headline, content);
      });

  @override
  Parser headline() => super.headline().map((items) {
        final stars = items[0] as String;
        final keyword = items[1] as String;
        final priority = items[2] as String;
        final rawTitle = items[3] as String;
        final titleElements = OrgContentParser.textRunParser()
            .star()
            .castList<OrgContentElement>()
            .parse(rawTitle)
            .value;
        final title = OrgContent(titleElements);
        final tags = items[4] as List;
        return OrgHeadline(
          stars,
          keyword,
          priority,
          title,
          rawTitle,
          tags?.cast<String>(),
        );
      });

  @override
  Parser priority() => super.priority().flatten('Priority expected');

  @override
  Parser tags() => super.tags().pick(1);

  @override
  Parser content() => super
      .content()
      .map((content) => OrgContentParser().parse(content as String).value);
}

class OrgContentParser extends GrammarParser {
  OrgContentParser() : super(OrgContentParserDefinition());

  static Parser textRunParser() {
    final definition = OrgContentParserDefinition();
    return definition.build(start: definition.textRun);
  }
}

class OrgContentParserDefinition extends OrgContentGrammarDefinition {
  @override
  Parser start() => super
      .start()
      .castList<OrgContentElement>()
      .map((elems) => OrgContent(elems));

  @override
  Parser paragraph() => super.paragraph().map((items) {
        final indent = items[0] as String;
        final bodyElements = items[1] as List;
        final body = OrgContent(bodyElements.cast<OrgContentElement>());
        return OrgParagraph(indent, body);
      });

  @override
  Parser plainText([Parser limit]) =>
      super.plainText(limit).map((value) => OrgPlainText(value as String));

  @override
  Parser plainLink() =>
      super.plainLink().map((value) => OrgLink(value as String, null));

  @override
  Parser regularLink() => super.regularLink().castList().map((values) {
        final location = values[1] as String;
        final description = values.length > 3 ? values[2] as String : null;
        return OrgLink(location, description);
      });

  @override
  Parser linkPart() => super.linkPart().pick(1);

  @override
  Parser linkDescription() => super.linkDescription().pick(1);

  @override
  Parser bold() => mapMarkup(super.bold(), OrgStyle.bold);

  @override
  Parser verbatim() => mapMarkup(super.verbatim(), OrgStyle.verbatim);

  @override
  Parser italic() => mapMarkup(super.italic(), OrgStyle.italic);

  @override
  Parser strikeThrough() =>
      mapMarkup(super.strikeThrough(), OrgStyle.strikeThrough);

  @override
  Parser underline() => mapMarkup(super.underline(), OrgStyle.underline);

  @override
  Parser code() => mapMarkup(super.code(), OrgStyle.code);

  Parser mapMarkup(Parser parser, OrgStyle style) =>
      parser.flatten('Markup expected').map((value) => OrgMarkup(value, style));

  @override
  Parser affiliatedKeyword() => super.affiliatedKeyword().map((items) {
        final indent = items[0] as String;
        final keyword = items[1] as String;
        final trailing = items[2] as String;
        return OrgMeta(indent, keyword, trailing);
      });

  @override
  Parser fixedWidthArea() => super.fixedWidthArea().castList().map((items) {
        final firstLine = items[0] as List;
        final indent = firstLine[0] as String;
        final body = firstLine.skip(1).join() +
            items.skip(1).expand((line) => line as List).join();
        return OrgFixedWidthArea(indent, body);
      });

  @override
  Parser namedBlock(String name) => super.namedBlock(name).map((parts) {
        final indent = parts[0] as String;
        final header = parts[1] as String;
        final body = parts[2] as String;
        final footer = parts[3] as String;
        OrgContentElement bodyContent;
        switch (name) {
          case 'example':
          case 'export':
            bodyContent = OrgMarkup(body, OrgStyle.verbatim);
            break;
          case 'src':
            bodyContent = OrgMarkup(body, OrgStyle.code);
            break;
          default:
            bodyContent = OrgPlainText(body);
        }
        return OrgBlock(indent, header, bodyContent, footer);
      });

  @override
  Parser namedBlockStart(String name) =>
      super.namedBlockStart(name).flatten('Named block "$name" start expected');

  @override
  Parser namedBlockEnd(String name) =>
      super.namedBlockEnd(name).flatten('Named block "$name" end expected');

  @override
  Parser greaterBlock() => super.greaterBlock().map((parts) {
        final indent = parts[0] as String;
        final header = parts[1] as String;
        final body = parts[2] as OrgContent;
        final footer = parts[3] as String;
        return OrgBlock(indent, header, body, footer);
      });

  @override
  Parser namedGreaterBlockContent(String name) => super
      .namedGreaterBlockContent(name)
      .castList<OrgContentElement>()
      .map((elems) => OrgContent(elems));

  @override
  Parser table() =>
      super.table().castList<OrgTableRow>().map((rows) => OrgTable(rows));

  @override
  Parser tableDotElDivider() => super
      .tableDotElDivider()
      .pick(0)
      .map((indent) => OrgTableDividerRow(indent as String));

  @override
  Parser tableRowRule() => super
      .tableRowRule()
      .pick(0)
      .map((item) => OrgTableDividerRow(item as String));

  @override
  Parser tableRowStandard() => super.tableRowStandard().map((items) {
        final indent = items[0] as String;
        final cells = items[2] as List;
        final trailing = items[3] as String;
        if (trailing.trim().isNotEmpty) {
          cells.add(OrgContent([OrgPlainText(trailing.trim())]));
        }
        return OrgTableCellRow(indent, cells.cast<OrgContent>());
      });

  @override
  Parser tableCell() => super.tableCell().pick(1);

  @override
  Parser tableCellContents() => super
      .tableCellContents()
      .castList<OrgContentElement>()
      .map((elems) => OrgContent(elems));

  @override
  Parser timestamp() => super
      .timestamp()
      .flatten('Timestamp expected')
      .map((value) => OrgTimestamp(value));

  @override
  Parser keyword() =>
      super.keyword().map((value) => OrgKeyword(value as String));

  @override
  Parser list() =>
      super.list().castList<OrgListItem>().map((items) => OrgList(items));

  @override
  Parser listItemOrdered() => super.listItemOrdered().map((values) {
        final indent = values[0] as String;
        final rest = values[1] as List;
        final bullet = rest[0] as String;
        final counterSet = rest[1] as String;
        final checkBox = rest[2] as String;
        final body = rest[3] as OrgContent;
        return OrgListOrderedItem(indent, bullet, counterSet, checkBox, body);
      });

  @override
  Parser listItemUnordered() => super.listItemUnordered().map((values) {
        final indent = values[0] as String;
        final rest = values[1] as List;
        final bullet = rest[0] as String;
        final checkBox = rest[1] as String;
        final tag = rest[2] as String;
        final body = rest[3] as OrgContent;
        return OrgListUnorderedItem(indent, bullet, checkBox, tag, body);
      });

  @override
  Parser listItemContents() => super
      .listItemContents()
      .castList<OrgContentElement>()
      .map((elems) => OrgContent(elems));

  @override
  Parser listOrderedBullet() =>
      super.listOrderedBullet().flatten('Ordered list bullet expected');

  @override
  Parser listCounterSet() =>
      super.listCounterSet().flatten('Counter set expected');

  @override
  Parser listCheckBox() => super.listCheckBox().flatten('Check box expected');

  @override
  Parser listTag() => super.listTag().flatten('List tag expected');
}
