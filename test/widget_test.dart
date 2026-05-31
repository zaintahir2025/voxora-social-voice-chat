import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxora/config/theme.dart';
import 'package:voxora/main.dart';
import 'package:voxora/screens/auth_screen.dart';
import 'package:voxora/screens/setup_screen.dart';

void main() {
  testWidgets('App boots', (tester) async {
    await tester.pumpWidget(const VoxoraApp());
    // Without Supabase config, shows setup screen
    expect(find.text('Backend Configuration Required'), findsOneWidget);
    expect(find.textContaining('SUPABASE_URL'), findsWidgets);
  });

  testWidgets('Setup screen fits narrow phones', (tester) async {
    await _pumpAtSize(tester, const SetupScreen(), const Size(390, 844));

    final cardRect = tester.getRect(find.byType(Card));
    expect(cardRect.left, greaterThanOrEqualTo(0));
    expect(cardRect.right, lessThanOrEqualTo(390));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Auth sign up form avoids narrow phone overflow', (tester) async {
    await _pumpAtSize(tester, const AuthScreen(), const Size(360, 780));

    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    expect(find.text('Create Account'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpAtSize(WidgetTester tester, Widget child, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: VoxoraTheme.light(),
      darkTheme: VoxoraTheme.dark(),
      themeMode: ThemeMode.dark,
      home: child,
    ),
  );
  await tester.pumpAndSettle();
}
