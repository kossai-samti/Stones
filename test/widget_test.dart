import 'package:flutter_test/flutter_test.dart';
import 'package:stone/main.dart';

void main() {
  testWidgets('app launches', (tester) async {
    await tester.pumpWidget(const LithaApp());
    expect(find.byType(LithaApp), findsOneWidget);
  });
}
