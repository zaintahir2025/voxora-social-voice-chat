import 'package:flutter_test/flutter_test.dart';
import 'package:voxora/main.dart';

void main() {
  testWidgets('App boots', (tester) async {
    await tester.pumpWidget(const VoxoraApp());
    // Without Supabase config, shows setup screen
    expect(find.text('Backend configuration required'), findsOneWidget);
  });
}
