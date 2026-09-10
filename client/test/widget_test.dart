import 'package:flutter_test/flutter_test.dart';

import 'package:daurin_app/main.dart';

void main() {
  testWidgets('landing page displays the main actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const Main());
    await tester.pump();

    expect(find.text('Selamat Datang di Daurin'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Daftar'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
  });
}
