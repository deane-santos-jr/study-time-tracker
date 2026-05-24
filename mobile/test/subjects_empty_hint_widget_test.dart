import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/src/presentation/modules/study/dashboard/widgets/subjects_empty_hint.dart';

void main() {
  Future<void> pumpHint(WidgetTester tester, {required bool hasActiveTerm}) {
    return tester.pumpWidget(
      MaterialApp(
        theme: defaultTheme,
        home: Scaffold(
          body: SubjectsEmptyHint(hasActiveTerm: hasActiveTerm),
        ),
      ),
    );
  }

  testWidgets(
    'shows "no subjects yet" + add-a-term guidance when no active term',
    (tester) async {
      await pumpHint(tester, hasActiveTerm: false);

      expect(find.text('no subjects yet'), findsOneWidget);
      expect(
        find.textContaining("'+ add a term'"),
        findsOneWidget,
        reason: 'should point users to the pill affordance above',
      );
    },
  );

  testWidgets(
    'shows in-term copy + menu guidance when a term is active',
    (tester) async {
      await pumpHint(tester, hasActiveTerm: true);

      expect(find.text('no subjects in this term yet'), findsOneWidget);
      expect(
        find.textContaining('manage the term'),
        findsOneWidget,
        reason: 'should direct users to the manage-terms menu action',
      );
      expect(
        find.text('no subjects yet'),
        findsNothing,
        reason: 'no-active-term copy must not leak into the active-term case',
      );
    },
  );
}
