import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ezeal/main.dart';

void main() {
  testWidgets('Ezeal Landing Page smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    // Verify that the landing page renders with the correct welcome title.
    expect(find.text('Welcome to Ezeal'), findsOneWidget);
  });
}
