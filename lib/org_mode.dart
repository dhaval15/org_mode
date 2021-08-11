library org_mode;

import 'dart:io';

export 'src/grammar/grammar.dart';
export 'src/parser/parser.dart';
export 'src/org/org.dart';
export 'src/util/timestamp.dart';
export 'src/util/day.dart';
export 'src/extras/extras.dart';

import 'src/org/org.dart';

void main() {
  final data = File(
          '/home/dhaval/Dev/space/habbit/test_dir/daily/May_2021/Friday_21.org')
      .readAsStringSync();
  print(data);
  final doc = OrgDocument.parse(data);
  print('---------------------------');
  print(doc.sections.first.headline.keyword);
}
