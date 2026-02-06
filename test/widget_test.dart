import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_scanner_app/main.dart';

void main() {
  testWidgets('App başlatma testi', (WidgetTester tester) async {
    await tester.pumpWidget(const OCRScannerApp());
    expect(find.text('Belge Tarayıcı'), findsOneWidget);
  });
}
