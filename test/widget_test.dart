import 'package:flutter_test/flutter_test.dart';
import 'package:apptest/main.dart';

void main() {
  testWidgets('App shows permission request on launch', (tester) async {
    await tester.pumpWidget(const AppTestApp());
    // Should show permission gate before files
    expect(find.text('File Manager needs storage access'), findsOneWidget);
    expect(find.text('Grant Access'), findsOneWidget);
  });
}