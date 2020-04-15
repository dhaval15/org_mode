import 'package:org_parser/org_parser.dart';
import 'package:org_parser/src/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('structural grammar', () {
    final grammar = OrgGrammar();
    final parser = OrgParser();
    test('parse content', () {
      final result = grammar.parse('''foo
bar
''');
      expect(result.value, ['foo\nbar\n', []]);
    });
    test('parse a header', () {
      final result = grammar.parse('* Title');
      expect(result.value, [
        null,
        [
          [
            ['* ', null, null, 'Title', null],
            null
          ]
        ]
      ]);
    });
    test('parse a todo header', () {
      final result = grammar.parse('* TODO Title');
      expect(result.value, [
        null,
        [
          [
            ['* ', 'TODO', null, 'Title', null],
            null
          ]
        ]
      ]);
    });
    test('parse a complex header', () {
      var result = grammar.parse('** TODO [#A] Title foo bar :biz:baz:');
      expect(result.value, [
        null,
        [
          [
            [
              '** ',
              'TODO',
              ['[#', 'A', ']'],
              'Title foo bar ',
              [
                ':',
                ['biz', 'baz'],
                ':'
              ]
            ],
            null
          ]
        ]
      ]);
      result = parser.parse('** TODO [#A] Title foo bar :biz:baz:');
      final document = result.value as OrgDocument;
      final title =
          document.children[0].headline.title.children[0] as OrgPlainText;
      expect(title.content, 'Title foo bar ');
    });
    test('parse a section', () {
      final result = grammar.parse('''* Title
  Content1
  Content2''');
      expect(result.value, [
        null,
        [
          [
            ['* ', null, null, 'Title', null],
            '  Content1\n  Content2'
          ]
        ]
      ]);
    });
    test('valid headers', () {
      for (final valid in [
        '* ',
        '** DONE',
        '*** Some e-mail',
        '**** TODO [#A] COMMENT Title :tag:a2%:',
      ]) {
        expect(grammar.parse(valid).isSuccess, true);
      }
    });
    test('example document', () {
      const doc = '''An introduction.

* A Headline

  Some text. *bold*

** Sub-Topic 1

** Sub-Topic 2

*** Additional entry''';
      expect(grammar.parse(doc).isSuccess, true);
      final parsed = parser.parse(doc);
      expect(parsed.isSuccess, true);
      final document = parsed.value as OrgDocument;
      final paragraph = document.content.children[0] as OrgParagraph;
      final text = paragraph.body.children[0] as OrgPlainText;
      expect(text.content, 'An introduction.\n\n');
      final topSection = document.children[0];
      final topContent0 = topSection.headline.title.children[0] as OrgPlainText;
      expect(topContent0.content, 'A Headline');
      expect(topSection.children.length, 2);
    });
  });

  group('content grammar parts', () {
    final grammarDefinition = OrgContentGrammarDefinition();
    Parser buildSpecific(Parser Function() start) {
      return grammarDefinition.build(start: start).end();
    }

    test('paragraph', () {
      final parser = buildSpecific(grammarDefinition.paragraph);
      var result = parser.parse('''foo bar
biz baz''');
      expect(result.value, [
        '',
        ['foo bar\nbiz baz']
      ]);
      result = parser.parse('''go to [[http://example.com][example]] for *fun*,
maybe''');
      expect(result.value, [
        '',
        [
          'go to ',
          [
            '[',
            ['[', 'http://example.com', ']'],
            ['[', 'example', ']'],
            ']'
          ],
          ' for ',
          ['*', 'fun', '*'],
          ',\nmaybe'
        ]
      ]);
    });
    test('link', () {
      final parser = buildSpecific(grammarDefinition.link);
      var result = parser.parse('[[http://example.com][example]]');
      expect(result.value, [
        '[',
        ['[', 'http://example.com', ']'],
        ['[', 'example', ']'],
        ']'
      ]);
      result = parser.parse('[[*\\[wtf\\] what?][[lots][of][boxes]\u200b]]');
      expect(result.value, [
        '[',
        ['[', '*[wtf] what?', ']'],
        ['[', '[lots][of][boxes]', ']'],
        ']'
      ]);
    });
    test('markup', () {
      final parser = buildSpecific(grammarDefinition.markups);
      var result = parser.parse('''a/b
c/d''');
      expect(result.isFailure, true, reason: 'bad pre/post chars');
      result = parser.parse('''a /b
c/d''');
      expect(result.isFailure, true, reason: 'bad post char');
      result = parser.parse('''a/b
c/ d''');
      expect(result.isFailure, true, reason: 'bad pre char');
      result = parser.parse('/a/');
      expect(result.value, ['/', 'a', '/']);
      result = parser.parse('/abc/');
      expect(result.value, ['/', 'abc', '/']);
      result = parser.parse('/a b/');
      expect(result.value, ['/', 'a b', '/']);
      result = parser.parse('//');
      expect(result.isFailure, true, reason: 'body is required');
      result = parser.parse('~,~');
      expect(result.value, ['~', ',', '~']);
      result = parser.parse("~'~");
      expect(result.value, ['~', "'", '~']);
    });
    test('affiliated keyword', () {
      final parser = buildSpecific(grammarDefinition.affiliatedKeyword);
      var result = parser.parse('  #+blah');
      expect(result.value, ['  ', '#+blah', '']);
      result = parser.parse('''a   #+blah''');
      expect(result.isFailure, true, reason: 'only leading space is allowed');
    });
    test('block', () {
      final parser = buildSpecific(grammarDefinition.block);
      var result = parser.parse('''#+begin_src sh
  echo 'foo'
  rm bar
#+end_src''');
      expect(result.value, [
        '',
        [
          ['#+begin_src', ' sh\n'],
          '  echo \'foo\'\n  rm bar\n',
          ['', '#+end_src']
        ],
        ''
      ]);
      result = parser.parse('''#+BEGIN_SRC sh
  echo 'foo'
  rm bar
#+EnD_sRC
''');
      expect(result.value, [
        '',
        [
          ['#+BEGIN_SRC', ' sh\n'],
          '  echo \'foo\'\n  rm bar\n',
          ['', '#+EnD_sRC']
        ],
        '\n'
      ]);
    });
    test('greater block', () {
      final parser = buildSpecific(grammarDefinition.greaterBlock);
      var result = parser.parse('''#+begin_quote
  foo *bar*
#+end_quote''');
      expect(result.value, [
        '',
        [
          ['#+begin_quote', '\n'],
          [
            '  foo ',
            ['*', 'bar', '*'],
            '\n'
          ],
          ['', '#+end_quote']
        ],
        ''
      ]);
      result = parser.parse('''#+BEGIN_QUOTE
  foo /bar/
#+EnD_qUOtE
''');
      expect(result.value, [
        '',
        [
          ['#+BEGIN_QUOTE', '\n'],
          [
            '  foo ',
            ['/', 'bar', '/'],
            '\n'
          ],
          ['', '#+EnD_qUOtE']
        ],
        '\n'
      ]);
    });
    test('table', () {
      final parser = buildSpecific(grammarDefinition.table);
      final result = parser.parse('''  | foo | bar | baz |
  |-----+-----+-----|
  |   1 |   2 |   3 |
''');
      expect(result.value, [
        [
          [
            '  ',
            '|',
            [
              [
                ' ',
                ['foo'],
                ' |'
              ],
              [
                ' ',
                ['bar'],
                ' |'
              ],
              [
                ' ',
                ['baz'],
                ' |'
              ]
            ],
            '\n'
          ],
          ['  ', '|-----+-----+-----|\n'],
          [
            '  ',
            '|',
            [
              [
                '   ',
                ['1'],
                ' |'
              ],
              [
                '   ',
                ['2'],
                ' |'
              ],
              [
                '   ',
                ['3'],
                ' |'
              ]
            ],
            '\n'
          ]
        ],
        ''
      ]);
    });
    test('timestamps', () {
      final parser = buildSpecific(grammarDefinition.timestamp);
      var result = parser.parse('''<2020-03-12 Wed>''');
      expect(result.value, [
        '<',
        ['2020', '-', '03', '-', '12', 'Wed'],
        null,
        [],
        '>'
      ]);
      result = parser.parse('''<2020-03-12 Wed 8:34>''');
      expect(result.value, [
        '<',
        ['2020', '-', '03', '-', '12', 'Wed'],
        ['8', ':', '34'],
        [],
        '>'
      ]);
      result = parser.parse('''<2020-03-12 Wed 8:34 +1w>''');
      expect(result.value, [
        '<',
        ['2020', '-', '03', '-', '12', 'Wed'],
        ['8', ':', '34'],
        [
          ['+', '1', 'w']
        ],
        '>'
      ]);
      result = parser.parse('''<2020-03-12 Wed 8:34 +1w --2d>''');
      expect(result.value, [
        '<',
        ['2020', '-', '03', '-', '12', 'Wed'],
        ['8', ':', '34'],
        [
          ['+', '1', 'w'],
          ['--', '2', 'd']
        ],
        '>'
      ]);
      result = parser.parse('''[2020-03-12 Wed 18:34 .+1w --12d]''');
      expect(result.value, [
        '[',
        ['2020', '-', '03', '-', '12', 'Wed'],
        ['18', ':', '34'],
        [
          ['.+', '1', 'w'],
          ['--', '12', 'd']
        ],
        ']'
      ]);
      result = parser.parse('''[2020-03-12 Wed 18:34-19:35 .+1w --12d]''');
      expect(result.value, [
        '[',
        ['2020', '-', '03', '-', '12', 'Wed'],
        [
          ['18', ':', '34'],
          '-',
          ['19', ':', '35']
        ],
        [
          ['.+', '1', 'w'],
          ['--', '12', 'd']
        ],
        ']'
      ]);
      result = parser.parse(
          '''[2020-03-11 Wed 18:34 .+1w --12d]--[2020-03-12 Wed 18:34 .+1w --12d]''');
      expect(result.value, [
        [
          '[',
          ['2020', '-', '03', '-', '11', 'Wed'],
          ['18', ':', '34'],
          [
            ['.+', '1', 'w'],
            ['--', '12', 'd']
          ],
          ']'
        ],
        '--',
        [
          '[',
          ['2020', '-', '03', '-', '12', 'Wed'],
          ['18', ':', '34'],
          [
            ['.+', '1', 'w'],
            ['--', '12', 'd']
          ],
          ']'
        ]
      ]);
      result = parser.parse('''<%%(what (the (f)))>''');
      expect(result.value, [
        '<%%',
        [
          '(',
          [
            'what',
            [
              '(',
              [
                'the',
                [
                  '(',
                  ['f'],
                  ')'
                ]
              ],
              ')'
            ]
          ],
          ')'
        ],
        '>'
      ]);
      result = parser.parse('''<%%(what (the (f))>''');
      expect(result.isFailure, true, reason: 'Invalid sexp');
      result = parser.parse('''[2020-03-11 Wed 18:34:56 .+1w --12d]''');
      expect(result.isFailure, true, reason: 'Seconds not supported');
    });
    test('fixed-width area', () {
      final parser = buildSpecific(grammarDefinition.fixedWidthArea);
      var result = parser.parse('  : foo');
      expect(result.value, [
        [
          ['  ', ': ', 'foo']
        ],
        ''
      ]);
      result = parser.parse('''  : foo
  : bar''');
      expect(result.value, [
        [
          ['  ', ': ', 'foo\n'],
          ['  ', ': ', 'bar']
        ],
        ''
      ]);
    });
    test('list', () {
      final parser = buildSpecific(grammarDefinition.list);
      var result = parser.parse('- foo');
      expect(result.value, [
        [
          [
            '',
            [
              '- ',
              null,
              null,
              ['foo']
            ]
          ]
        ],
        ''
      ]);
      result = parser.parse('''- foo
  - bar''');
      expect(result.value, [
        [
          [
            '',
            [
              '- ',
              null,
              null,
              [
                'foo\n',
                [
                  [
                    [
                      '  ',
                      [
                        '- ',
                        null,
                        null,
                        ['bar']
                      ]
                    ]
                  ],
                  ''
                ]
              ]
            ]
          ]
        ],
        ''
      ]);
      result = parser.parse('''- foo

  bar''');
      expect(result.value, [
        [
          [
            '',
            [
              '- ',
              null,
              null,
              ['foo\n\n  bar']
            ]
          ]
        ],
        ''
      ]);
      result = parser.parse(
        '  - foo\n'
        ' \n'
        '    bar',
      );
      expect(result.value, [
        [
          [
            '  ',
            [
              '- ',
              null,
              null,
              ['foo\n \n    bar']
            ]
          ]
        ],
        ''
      ]);
      result = parser.parse('''30. [@30] foo
   - bar :: baz
     blah
   - [ ] *bazinga*''');
      expect(result.value, [
        [
          [
            '',
            [
              ['30', '.', ' '],
              ['[@', '30', ']'],
              null,
              [
                'foo\n',
                [
                  [
                    [
                      '   ',
                      [
                        '- ',
                        null,
                        ['bar', ' :: '],
                        ['baz\n     blah\n']
                      ]
                    ],
                    [
                      '   ',
                      [
                        '- ',
                        ['[', ' ', ']'],
                        null,
                        [
                          ['*', 'bazinga', '*']
                        ]
                      ]
                    ]
                  ],
                  ''
                ]
              ]
            ]
          ]
        ],
        ''
      ]);
      result = parser.parse('''- foo
  #+begin_src sh
    echo bar
  #+end_src''');
      expect(result.value, [
        [
          [
            '',
            [
              '- ',
              null,
              null,
              [
                'foo\n',
                [
                  '  ',
                  [
                    ['#+begin_src', ' sh\n'],
                    '    echo bar\n',
                    ['  ', '#+end_src']
                  ],
                  ''
                ]
              ]
            ]
          ]
        ],
        ''
      ]);
    });
    test('drawer', () {
      final parser = buildSpecific(grammarDefinition.drawer);
      var result = parser.parse(''':foo:
:end:''');
      expect(result.value, [
        '',
        [
          [':', 'foo', ':', '\n'],
          [],
          ['', ':end:']
        ],
        ''
      ]);
      result = parser.parse('''  :foo:
  :bar: baz
  :end:

''');
      expect(result.value, [
        '  ',
        [
          [':', 'foo', ':', '\n'],
          [
            [
              '  ',
              [':', 'bar', ':'],
              ' baz',
              '\n'
            ]
          ],
          ['  ', ':end:']
        ],
        '\n\n'
      ]);
      result = parser.parse(''':foo:
:bar:
:end:
:end:''');
      expect(result.isFailure, true,
          reason: 'Nested drawer disallowed; the trailing ":end:" is '
              'a separate paragraph, which fails the drawer-specific parser');
    });
    test('property', () {
      final parser = buildSpecific(grammarDefinition.property);
      var result = parser.parse(':foo: bar');
      expect(result.value, [
        '',
        [':', 'foo', ':'],
        ' bar',
        ''
      ]);
      result = parser.parse(':foo:');
      expect(result.isFailure, true, reason: 'Value required');
      result = parser.parse(':foo:blah');
      expect(result.isFailure, true, reason: 'Delimiting space required');
      result = parser.parse(''':foo:
bar''');
      expect(result.isFailure, true, reason: 'Value must be on same line');
    });
  });

  group('content grammar complete', () {
    final parser = OrgContentGrammar();
    test('paragraph', () {
      final result = parser.parse('''foo bar *biz*

  #+begin_quote
    blah
  #+end_quote
bazinga''');
      expect(result.value, [
        [
          '',
          [
            'foo bar ',
            ['*', 'biz', '*'],
            '\n\n'
          ]
        ],
        [
          '  ',
          [
            ['#+begin_quote', '\n'],
            ['    blah\n'],
            ['  ', '#+end_quote']
          ],
          '\n'
        ],
        [
          '',
          ['bazinga']
        ]
      ]);
    });
    test('link', () {
      var result = parser.parse('a http://example.com b');
      expect(result.value, [
        [
          '',
          ['a ', 'http://example.com', ' b']
        ]
      ]);
      result = parser.parse('a https://example.com b');
      expect(result.value, [
        [
          '',
          ['a ', 'https://example.com', ' b']
        ]
      ]);
      result = parser.parse('a [[foo][bar]] b');
      expect(result.value, [
        [
          '',
          [
            'a ',
            [
              '[',
              ['[', 'foo', ']'],
              ['[', 'bar', ']'],
              ']'
            ],
            ' b'
          ]
        ]
      ]);
      result = parser.parse('a [[foo::1][bar]] b');
      expect(result.value, [
        [
          '',
          [
            'a ',
            [
              '[',
              ['[', 'foo::1', ']'],
              ['[', 'bar', ']'],
              ']'
            ],
            ' b'
          ]
        ]
      ]);
    });
    test('affiliated keyword', () {
      var result = parser.parse('''#+blah
foo''');
      expect(result.value, [
        ['', '#+blah', '\n'],
        [
          '',
          ['foo']
        ]
      ]);
      result = parser.parse('''   #+blah
foo''');
      expect(result.value, [
        ['   ', '#+blah', '\n'],
        [
          '',
          ['foo']
        ]
      ]);
      // TODO(aaron): Figure out why this fails without the leading 'a'
      result = parser.parse('''a
#+blah
foo''');
      expect(result.value, [
        [
          '',
          ['a\n']
        ],
        ['', '#+blah', '\n'],
        [
          '',
          ['foo']
        ]
      ]);
    });
    test('list', () {
      final result = parser.parse('''- foo


  bar''');
      expect(result.value, [
        [
          [
            [
              '',
              [
                '- ',
                null,
                null,
                ['foo\n\n']
              ]
            ]
          ],
          '\n'
        ],
        [
          '  ',
          ['bar']
        ]
      ]);
    });
    test('drawer', () {
      final result = parser.parse(''':foo:
:bar: baz
:end:
#+bazinga: bozo''');
      expect(result.value, [
        [
          '',
          [
            [':', 'foo', ':', '\n'],
            [
              [
                '',
                [':', 'bar', ':'],
                ' baz',
                '\n'
              ]
            ],
            ['', ':end:']
          ],
          '\n'
        ],
        ['', '#+bazinga:', ' bozo']
      ]);
    });
  });
}