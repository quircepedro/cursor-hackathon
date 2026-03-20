import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:votio_mobile/shared/widgets/buttons/primary_button.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('PrimaryButton', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          PrimaryButton(label: 'Test Button', onPressed: () {}),
        ),
      );
      expect(find.text('Test Button'), findsOneWidget);
    });

    testWidgets('shows loading spinner when isLoading is true', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          PrimaryButton(label: 'Test Button', onPressed: () {}, isLoading: true),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Test Button'), findsNothing);
    });

    testWidgets('is disabled when enabled is false', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          PrimaryButton(label: 'Test', onPressed: () {}, enabled: false),
        ),
      );
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });
  });
}
