import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stocknews/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App launches', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const StockNewsApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(''), findsOneWidget);
    expect(find.text('沪股通'), findsOneWidget);
    expect(find.text('深股通'), findsOneWidget);
  });
}
