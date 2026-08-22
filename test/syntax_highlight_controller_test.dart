import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naiweaver/core/widgets/syntax_highlight_controller.dart';

void main() {
  /// Builds the span tree for [text] and returns the flattened plain text of
  /// each leaf span in order.
  List<TextSpan> spansFor(WidgetTester tester, String text) {
    final controller = SyntaxHighlightController(text: text);
    final context = tester.element(find.byType(SizedBox));
    final root = controller.buildTextSpan(
      context: context,
      style: const TextStyle(color: Colors.white),
      withComposing: false,
    );
    final leaves = <TextSpan>[];
    root.visitChildren((span) {
      if (span is TextSpan && span.text != null) leaves.add(span);
      return true;
    });
    return leaves;
  }

  String joined(List<TextSpan> spans) => spans.map((s) => s.text).join();

  Future<void> pump(WidgetTester tester) =>
      tester.pumpWidget(const MaterialApp(home: SizedBox()));

  testWidgets('round-trips plain text unchanged', (tester) async {
    await pump(tester);
    const text = '1girl, long hair, artist:test';
    expect(joined(spansFor(tester, text)), text);
  });

  testWidgets('highlights the full N::tag:: unit including closing delimiter',
      (tester) async {
    await pump(tester);
    const text = '2::black hair::, smile';
    final spans = spansFor(tester, text);
    expect(joined(spans), text);
    expect(spans[0].text, '2::');
    expect(spans[0].style?.color, isNot(Colors.white));
    expect(spans[1].text, 'black hair');
    expect(spans[1].style?.color, isNot(Colors.white));
    expect(spans[2].text, '::');
    expect(spans[2].style?.color, isNot(Colors.white));
    // Trailing text is plain.
    expect(spans[3].style?.color, Colors.white);
  });

  testWidgets('supports negative and fractional weights', (tester) async {
    await pump(tester);
    for (final text in ['-1::glasses::', '1.5::smile::', '-0.5::blur::']) {
      final spans = spansFor(tester, text);
      expect(joined(spans), text);
      expect(spans.first.style?.color, isNot(Colors.white),
          reason: 'weight prefix of "$text" should be highlighted');
    }
  });

  testWidgets('leaves an unterminated weight prefix as prefix-only highlight',
      (tester) async {
    await pump(tester);
    const text = '2::black ha';
    final spans = spansFor(tester, text);
    expect(joined(spans), text);
    expect(spans[0].text, '2::');
    expect(spans[1].style?.color, Colors.white);
  });

  // Regression: a weight prefix inside brackets used to make buildTextSpan
  // spin forever (the bracket run-collector broke at the match but nothing
  // consumed it), freezing the app as soon as e.g. `{2::` was typed.
  testWidgets('terminates on weight prefixes inside brackets', (tester) async {
    await pump(tester);
    for (final text in [
      '{2::tag::}',
      '[1.5::tag::]',
      '{{nested, 2::deep::}}',
      '{2::unterminated',
    ]) {
      expect(joined(spansFor(tester, text)), text,
          reason: '"$text" should render all characters exactly once');
    }
  });

  // Regression (issue #38): `_strengthPrefix` was anchored with `^`, and
  // `matchAsPrefix` only ever matches an anchored pattern at index 0 of the
  // whole string — so a weight anywhere but the very start of the prompt was
  // never highlighted.
  testWidgets('highlights weights that are not at the start of the prompt',
      (tester) async {
    await pump(tester);
    const text = '1girl, smile, 2::black hair::, looking at viewer';
    final spans = spansFor(tester, text);
    expect(joined(spans), text);

    final weightSpan = spans.firstWhere((s) => s.text == '2::',
        orElse: () => const TextSpan(text: ''));
    expect(weightSpan.text, '2::',
        reason: 'mid-prompt weight prefix should be its own span');
    expect(weightSpan.style?.color, isNot(Colors.white));

    // The body of the mid-prompt weight is highlighted too.
    final body = spans.firstWhere((s) => s.text == 'black hair',
        orElse: () => const TextSpan(text: ''));
    expect(body.style?.color, isNot(Colors.white));
  });

  testWidgets('highlights several weights across one prompt', (tester) async {
    await pump(tester);
    const text = '2::a::, plain, -1::b::, 1.5::c::';
    final spans = spansFor(tester, text);
    expect(joined(spans), text);
    for (final prefix in ['2::', '-1::', '1.5::']) {
      expect(spans.any((s) => s.text == prefix && s.style?.color != Colors.white),
          isTrue,
          reason: '"$prefix" should be highlighted');
    }
  });

  // NAI tints positive and negative weights differently; they used to share
  // one green.
  testWidgets('positive and negative weights use different colors',
      (tester) async {
    await pump(tester);
    final positive = spansFor(tester, 'girl, 2::tag::')
        .firstWhere((s) => s.text == '2::');
    final negative = spansFor(tester, 'girl, -1::tag::')
        .firstWhere((s) => s.text == '-1::');
    expect(positive.style?.color, isNot(negative.style?.color));
  });

  // A bare number must not be mistaken for a weight now that the pattern is
  // unanchored — the `::` is still required.
  testWidgets('plain numbers are not treated as weights', (tester) async {
    await pump(tester);
    for (final text in ['2024, 1girl', 'group of 3, smile', '1.5 meters']) {
      final spans = spansFor(tester, text);
      expect(joined(spans), text);
      expect(spans.every((s) => s.style?.color == Colors.white), isTrue,
          reason: '"$text" contains no weights and should be unstyled');
    }
  });

  testWidgets('still colors brace and bracket emphasis', (tester) async {
    await pump(tester);
    const text = '{{1girl}}, [background]';
    final spans = spansFor(tester, text);
    expect(joined(spans), text);
    expect(spans.first.style?.color, isNot(Colors.white));
  });

  testWidgets('disabled controller returns unstyled text', (tester) async {
    await pump(tester);
    final controller =
        SyntaxHighlightController(text: '2::tag::', enabled: false);
    final context = tester.element(find.byType(SizedBox));
    final root = controller.buildTextSpan(
      context: context,
      style: const TextStyle(color: Colors.white),
      withComposing: false,
    );
    expect(root.toPlainText(), '2::tag::');
  });
}
