import 'package:flutter_test/flutter_test.dart';

import 'package:tiffin_service_app/main.dart';

void main() {
  testWidgets('App Welcome Screen Smoke Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TiffinServiceApp());

    // Verify that "Atithi" is shown on welcome screen
    expect(find.textContaining('Atithi'), findsWidgets);
  });
}
