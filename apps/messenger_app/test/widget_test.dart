import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:messenger_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows login and registration controls', (tester) async {
    await tester.pumpWidget(const MyMessengerApp());
    await tester.pumpAndSettle();

    expect(find.text('My Messenger'), findsOneWidget);
    expect(find.text('Login'), findsWidgets);
    expect(find.text('Register'), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble), findsOneWidget);
  });

  testWidgets('registration mode is open and does not ask for invite', (tester) async {
    await tester.pumpWidget(const MyMessengerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();

    expect(find.text('Invite code'), findsNothing);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Open demo account'), findsOneWidget);
  });
}
