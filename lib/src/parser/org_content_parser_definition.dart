import 'package:petitparser/petitparser.dart';
import '../grammar/grammar.dart';
import '../org/org.dart';
import '../util/util.dart';

typedef OrgMetaListener = void Function(OrgMeta meta);

class OrgContentParserDefinition extends OrgContentGrammarDefinition {
  final OrgMetaListener onMeta;
  OrgContentParserDefinition(this.onMeta);

  @override
  Parser start() =>
      super.start().castList<OrgNode>().map((elems) => OrgContent(elems));

  @override
  Parser paragraph() => super.paragraph().map((items) {
        final indent = items[0] as String;
        final bodyElements = items[1] as List;
        final body = OrgContent(bodyElements.cast<OrgNode>());
        return OrgParagraph(indent, body);
      });

  @override
  Parser plainText([Parser? limit]) =>
      super.plainText(limit).map((value) => OrgPlainText(value as String));

  @override
  Parser plainLink() =>
      super.plainLink().map((value) => OrgLink(value as String, null));

  @override
  Parser regularLink() => super.regularLink().castList().map((values) {
        final location = values[1] as String;
        final description = values.length > 3 ? values[2] as String? : null;
        return OrgLink(location, description);
      });

  @override
  Parser linkPart() => super.linkPart().castList().pick(1);

  @override
  Parser linkDescription() => super.linkDescription().castList().pick(1);

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

  Parser mapMarkup(Parser parser, OrgStyle style) => parser.map((values) {
        final leading = values[0] as String;
        final content = values[1] as String;
        final trailing = values[2] as String;
        return OrgMarkup(leading, content, trailing, style);
      });

  @override
  Parser entity() => super.entity().map((values) {
        final leading = values[0] as String;
        final name = values[1] as String;
        final trailing = values[2] as String;
        return OrgEntity(leading, name, trailing);
      });

  @override
  Parser macroReference() => super
      .macroReference()
      .flatten('Macro reference expected')
      .map((value) => OrgMacroReference(value));

  @override
  Parser affiliatedKeyword() => super.affiliatedKeyword().map((items) {
        final indent = items[0] as String;
        final keyword = items[1] as String;
        final trailing = items[2] as String;
        final meta = OrgMeta(indent, keyword, trailing);
        onMeta.call(meta);
        return meta;
      });

  @override
  Parser fixedWidthArea() => super.fixedWidthArea().castList().map((items) {
        final body = items[0] as List;
        final firstLine = body[0] as List;
        final indent = firstLine[0] as String;
        final content = firstLine.skip(1).join() +
            body.skip(1).expand((line) => line as List).join();
        final trailing = items[1] as String;
        return OrgFixedWidthArea(indent, content, trailing);
      });

  @override
  Parser namedBlock(String name) => super.namedBlock(name).map((parts) {
        final indent = parts[0] as String;
        final body = parts[1] as List;
        final header = body[0] as String;
        final content = body[1] as String;
        final footer = body[2] as String;
        final trailing = parts[2] as String;
        OrgNode bodyContent;
        switch (name) {
          case 'example':
          case 'export':
            bodyContent = OrgMarkup.just(content, OrgStyle.verbatim);
            break;
          default:
            bodyContent = OrgPlainText(content);
        }
        return OrgBlock(indent, header, bodyContent, footer, trailing);
      });

  @override
  Parser srcBlock() => super.srcBlock().map((parts) {
        final indent = parts[0] as String;
        final body = parts[1] as List;
        final headerToken = body[0] as Token;
        final headerParts = headerToken.value as List;
        final language = headerParts[1] as String?;
        final header = headerToken.input;
        final content = body[1] as String;
        final footer = body[2] as String;
        final trailing = parts[2] as String;
        final bodyContent = OrgPlainText(content);
        return OrgSrcBlock(
          language,
          indent,
          header,
          bodyContent,
          footer,
          trailing,
        );
      });

  @override
  Parser srcBlockStart() => super.srcBlockStart().token();

  @override
  Parser srcBlockLanguageToken() =>
      super.srcBlockLanguageToken().castList().pick(1);

  @override
  Parser namedBlockStart(String name) =>
      super.namedBlockStart(name).flatten('Named block "$name" start expected');

  @override
  Parser namedBlockEnd(String name) =>
      super.namedBlockEnd(name).flatten('Named block "$name" end expected');

  @override
  Parser greaterBlock() => super.greaterBlock().map((parts) {
        final indent = parts[0] as String;
        final body = parts[1] as List;
        final header = body[0] as String;
        final content = body[1] as OrgContent;
        final footer = body[2] as String;
        final trailing = parts[2] as String;
        return OrgBlock(indent, header, content, footer, trailing);
      });

  @override
  Parser namedGreaterBlockContent(String name) => super
      .namedGreaterBlockContent(name)
      .castList<OrgNode>()
      .map((elems) => OrgContent(elems));

  @override
  Parser table() => super.table().map((items) {
        final rows = items[0] as List;
        final trailing = items[1] as String;
        return OrgTable(rows.cast<OrgTableRow>(), trailing);
      });

  @override
  Parser tableDotElDivider() => super
      .tableDotElDivider()
      .castList()
      .pick(0)
      .map((indent) => OrgTableDividerRow(indent as String));

  @override
  Parser tableRowRule() => super
      .tableRowRule()
      .castList()
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
  Parser tableCell() => super.tableCell().castList().pick(1);

  @override
  Parser tableCellContents() => super
      .tableCellContents()
      .castList<OrgNode>()
      .map((elems) => OrgContent(elems));

  @override
  Parser timestamp() => super.timestamp().map((value) {
        final list = value as List;
        final isActive = list[0] == '<';
        final dateList = list[1] as List?;
        final day = _parseDay(dateList);
        final timeList = list[2] as List?;
        final time = _parseTime(timeList);
        return OrgTimestamp(
            timestamp: Timestamp(day, time, isActive: isActive));
      });

  @override
  Parser keyword() =>
      super.keyword().map((value) => OrgKeyword(value as String));

  @override
  Parser planningLine() => super.planningLine().map((values) {
        final filtered = [
          values[1][0],
          ...values[1][1],
        ].where((element) => element is OrgTimestamp || element is OrgKeyword);
        final timestamps = <OrgTimestamp>[];
        OrgKeyword? key;
        for (final e in filtered) {
          if (e is OrgKeyword) {
            key = e;
          }
          if (e is OrgTimestamp) {
            if (key != null) {
              timestamps.add(e.withKeyword(key.content));
              key = null;
            } else {
              timestamps.add(e);
            }
          }
        }
        return OrgPlanningLine(
          timestamps: timestamps,
        );
      });

  @override
  Parser list() => super.list().map((items) {
        final listItems = items[0] as List;
        final trailing = items[1] as String;
        return OrgList(listItems.cast<OrgListItem>(), trailing);
      });

  @override
  Parser listItemOrdered() => super.listItemOrdered().map((values) {
        final indent = values[0] as String;
        final rest = values[1] as List;
        final bullet = rest[0] as String;
        final counterSet = rest[1] as String?;
        final checkBox = rest[2] as String?;
        final body = rest[3] as OrgContent?;
        return OrgListOrderedItem(indent, bullet, counterSet, checkBox, body);
      });

  @override
  Parser listItemUnordered() => super.listItemUnordered().map((values) {
        final indent = values[0] as String;
        final rest = values[1] as List;
        final bullet = rest[0] as String;
        final checkBox = rest[1] as String?;
        final tagParts = rest[2] as List?;
        OrgContent? tag;
        String? tagDelimiter;
        if (tagParts != null) {
          final tagList = tagParts[0] as List;
          tag = OrgContent(tagList.cast<OrgNode>());
          tagDelimiter = tagParts[1] as String;
        }
        final body = rest[3] as OrgContent?;
        return OrgListUnorderedItem(
          indent,
          bullet,
          checkBox,
          tag,
          tagDelimiter,
          body,
        );
      });

  @override
  Parser listItemContents() => super
      .listItemContents()
      .castList<OrgNode>()
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
  Parser drawer() => super.drawer().map((values) {
        final indent = values[0] as String;
        final body = values[1] as List;
        final header = body[0] as String;
        final content = body[1] as OrgContent;
        final footer = body[2] as String;
        final trailing = values[2] as String;
        return OrgDrawer(indent, header, content, footer, trailing);
      });

  @override
  Parser drawerStart() => super.drawerStart().flatten('Drawer start expected');

  @override
  Parser drawerContent() => super
      .drawerContent()
      .castList<OrgNode>()
      .map((elems) => OrgContent(elems));

  @override
  Parser drawerEnd() => super.drawerEnd().flatten('Drawer end expected');

  @override
  Parser property() => super.property().map((values) {
        final indent = values[0] as String;
        final key = values[1] as String;
        final value = values[2] as String;
        final trailing = values[3] as String;
        return OrgProperty(indent, key, value, trailing);
      });

  @override
  Parser propertyKey() => super.propertyKey().flatten('Property key expected');

  @override
  Parser footnoteReferenceNamed() =>
      super.footnoteReferenceNamed().map((values) {
        final leading = values[0] as String;
        final name = values[1] as String;
        final trailing = values[2] as String;
        return OrgFootnoteReference.named(leading, name, trailing);
      });

  @override
  Parser footnoteReferenceInline() =>
      super.footnoteReferenceInline().map((values) {
        final leading = values[0] as String;
        final name = values[1] as String?;
        final delimiter = values[2] as String?;
        final content = values[3] as OrgContent?;
        final trailing = values[4] as String;
        return OrgFootnoteReference(
          leading,
          name,
          delimiter,
          content,
          trailing,
        );
      });

  @override
  Parser footnoteDefinition() => super
      .footnoteDefinition()
      .castList<OrgNode>()
      .map((elems) => OrgContent(elems));

  @override
  Parser footnote() => super.footnote().map((values) {
        final marker = values[0] as OrgFootnoteReference;
        var content = values[1] as OrgContent;
        final trailing = values[2] as String;
        if (trailing.isNotEmpty) {
          content = OrgContent(content.children + [OrgPlainText(trailing)]);
        }
        return OrgFootnote(marker, content);
      });

  @override
  Parser footnoteBody() => super
      .footnoteBody()
      .castList<OrgNode>()
      .map((elems) => OrgContent(elems));

  @override
  Parser latexBlock() => super.latexBlock().map((values) {
        final leading = values[0] as String;
        final body = values[1] as List;
        final blockStart = body[0] as List;
        final begin = blockStart.join('');
        final environment = blockStart[1] as String;
        final content = body[1] as String;
        final end = body[2] as String;
        final trailing = values[2] as String;
        return OrgLatexBlock(
          environment,
          leading,
          begin,
          content,
          end,
          trailing,
        );
      });

  @override
  Parser latexInline() => super.latexInline().map((values) {
        final leading = values[0] as String;
        final body = values[1] as String;
        final trailing = values[2] as String;
        return OrgLatexInline(leading, body, trailing);
      });
}

Day _parseDay(List? list) {
  if (list == null) return Day.none;
  final year = int.parse(list[0]);
  final month = int.parse(list[2]);
  final day = int.parse(list[4]);
  return Day(day, month, year);
}

Time _parseTime(List? list) {
  if (list == null) return Time.none;
  final hour = int.parse(list[0]);
  final minute = int.parse(list[2]);
  return Time(hour, minute);
}
