import 'package:flutter_test/flutter_test.dart';
import 'package:fortress_studio_app/main.dart';

void main() {
  testWidgets('FortressStudioApp renders shell', (WidgetTester tester) async {
    await tester.pumpWidget(const FortressStudioApp());
    await tester.pump();
    expect(find.byType(MainShell), findsOneWidget);
  });
}
