import 'package:flutter_test/flutter_test.dart';
import 'package:stockmaster/app.dart'; // Asegúrate de que esta ruta sea correcta

void main() {
  testWidgets('App starts', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(const MyApp());

    // Verify that the app starts
    expect(find.text('StockMaster'), findsOneWidget);
  });
}