import 'package:flutter_test/flutter_test.dart';
import 'package:my_todo_app/main.dart';

void main() {
  testWidgets('App displays intro screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Daily Planner'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
