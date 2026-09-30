import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_pdf_reader/screens/loading_view.dart';

void main() {
  testWidgets('LoadingView renders generic title when no documentFileName is given', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LoadingView(),
        ),
      ),
    );

    expect(find.text('Loading document...'), findsOneWidget);
    expect(find.text('Preparing pages, please wait...'), findsOneWidget);
    expect(find.byKey(const Key('loading_icon_rotation')), findsOneWidget);
    expect(find.byIcon(Icons.sync_rounded), findsOneWidget);
  });

  testWidgets('LoadingView renders documentFileName when provided', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LoadingView(documentFileName: 'my_sample_book.epub'),
        ),
      ),
    );

    expect(find.text('Loading my_sample_book.epub...'), findsOneWidget);
    expect(find.text('Preparing pages, please wait...'), findsOneWidget);
    expect(find.byKey(const Key('loading_icon_rotation')), findsOneWidget);
  });

  testWidgets('LoadingView rotates the icon over time', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LoadingView(),
        ),
      ),
    );

    final transitionFinder = find.byKey(const Key('loading_icon_rotation'));
    final initialTransition = tester.widget<RotationTransition>(transitionFinder);
    final initialTurns = initialTransition.turns.value;

    // Advance time by 350ms (quarter of 1400ms duration)
    await tester.pump(const Duration(milliseconds: 350));

    final advancedTransition = tester.widget<RotationTransition>(transitionFinder);
    final advancedTurns = advancedTransition.turns.value;

    expect(advancedTurns, isNot(equals(initialTurns)));
  });

  testWidgets('LoadingView renders and triggers Cancel button when onCancel provided', (
    WidgetTester tester,
  ) async {
    bool cancelled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoadingView(
            documentFileName: 'test.pdf',
            onCancel: () {
              cancelled = true;
            },
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('loading_cancel_button')), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    await tester.tap(find.byKey(const Key('loading_cancel_button')));
    expect(cancelled, isTrue);
  });

  testWidgets('LoadingView does not render Cancel button when onCancel is null', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LoadingView(documentFileName: 'test.pdf'),
        ),
      ),
    );

    expect(find.byKey(const Key('loading_cancel_button')), findsNothing);
  });
}
