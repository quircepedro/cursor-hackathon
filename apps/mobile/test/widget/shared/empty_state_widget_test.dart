import 'package:flutter_test/flutter_test.dart';
import 'package:votio_mobile/shared/widgets/feedback/empty_state_widget.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('EmptyStateWidget', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const EmptyStateWidget(title: 'Nothing here'),
        ),
      );
      expect(find.text('Nothing here'), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const EmptyStateWidget(
            title: 'Empty',
            subtitle: 'Try again later',
          ),
        ),
      );
      expect(find.text('Try again later'), findsOneWidget);
    });
  });
}
