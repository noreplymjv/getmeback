import 'package:flutter_test/flutter_test.dart';
import 'package:getmeback/main.dart';

void main() {
  testWidgets('App launches with GetMeBack title', (WidgetTester tester) async {
    await tester.pumpWidget(const GetMeBackApp());
    await tester.pump();

    expect(find.text('GetMeBack'), findsOneWidget);
    expect(find.text('Create Target'), findsOneWidget);
  });
}
