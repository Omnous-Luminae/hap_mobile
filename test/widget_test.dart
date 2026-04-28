import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hap_mobile/main.dart';
import 'package:hap_mobile/providers/auth_provider.dart';
import 'package:hap_mobile/screens/auth/login_screen.dart';

class FakeAuthProvider extends AuthProvider {
  FakeAuthProvider({this.loginResult = false});

  final bool loginResult;

  String? lastEmail;
  String? lastPassword;

  @override
  Future<bool> login(String email, String password) async {
    lastEmail = email;
    lastPassword = password;
    return loginResult;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows splash branding then redirects to login',
      (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => FakeAuthProvider(),
        child: const HapApp(),
      ),
    );

    expect(find.text('HAP'), findsOneWidget);
    expect(find.text('House After Party'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    expect(find.text('HAP Mobile'), findsOneWidget);
    expect(find.text('Connectez-vous à votre compte'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('login form validates input and forwards credentials',
      (tester) async {
    final auth = FakeAuthProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.tap(find.text('Se connecter'));
    await tester.pump();

    expect(find.text('Email requis'), findsOneWidget);
    expect(find.text('Mot de passe requis'), findsOneWidget);
    expect(auth.lastEmail, isNull);
    expect(auth.lastPassword, isNull);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      '  test@example.com  ',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Se connecter'));
    await tester.pump();

    expect(auth.lastEmail, 'test@example.com');
    expect(auth.lastPassword, 'password123');
  });

  testWidgets('login screen opens the registration screen', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => FakeAuthProvider(),
        child: const HapApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text("S'inscrire"));
    await tester.tap(find.text("S'inscrire"));
    await tester.pumpAndSettle();

    expect(find.text('Créer un compte'), findsOneWidget);
  });
}
