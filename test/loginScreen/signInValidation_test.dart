import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drivers_app/authentication/login_screen.dart';

void main() {
  group('LoginScreen', () {
    testWidgets('Email vazio', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.text('Insira um email válido.'), findsOneWidget);
    });

    testWidgets('Email inválido (sem @)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.enterText(find.byType(TextField).first, 'emailinvalido');
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.text('Insira um email válido.'), findsOneWidget);
    });

    testWidgets('Email inválido (com @ e domínio, mas sem extensão)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.enterText(find.byType(TextField).first, 'email@dominio');
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.text('Insira um email válido.'), findsOneWidget);
    });

    testWidgets('Email válido (com @, domínio e extensão)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.enterText(find.byType(TextField).first, 'emailvalido@example.com');
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.text('Insira um email válido.'), findsNothing);
    });

    testWidgets('Senha vazia', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.enterText(find.byType(TextField).first, 'emailvalido@example.com');
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.text('Sua senha deve ter pelo menos 6 caracteres.'), findsOneWidget);
    });

    testWidgets('Senha curta (menos de 6 caracteres)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.enterText(find.byType(TextField).first, 'emailvalido@example.com');
      await tester.enterText(find.byType(TextField).last, 'senha');
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.text('Sua senha deve ter pelo menos 6 caracteres.'), findsOneWidget);
    });

    testWidgets('Senha válida (6 caracteres)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.enterText(find.byType(TextField).first, 'emailvalido@example.com');
      await tester.enterText(find.byType(TextField).last, 'senhavalida');
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.text('Sua senha deve ter pelo menos 6 caracteres.'), findsNothing);
    });

    testWidgets('Senha válida (mais de 6 caracteres)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.enterText(find.byType(TextField).first, 'emailvalido@example.com');
      await tester.enterText(find.byType(TextField).last, 'senhavalidamuito');
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.text('Sua senha deve ter pelo menos 6 caracteres.'), findsNothing);
    });

    testWidgets('Email e senha vazios', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.text('Insira um email válido.'), findsOneWidget);
    });

    testWidgets('Email inválido e senha vazia', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.enterText(find.byType(TextField).first, 'emailinvalido');
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.text('Insira um email válido.'), findsOneWidget);
    });

    testWidgets('Email válido e senha curta', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.enterText(find.byType(TextField).first, 'emailvalido@example.com');
      await tester.enterText(find.byType(TextField).last, 'senha');
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.text('Sua senha deve ter pelo menos 6 caracteres.'), findsOneWidget);
    });

    testWidgets('Email inválido e senha válida', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.enterText(find.byType(TextField).first, 'emailinvalido');
      await tester.enterText(find.byType(TextField).last, 'senhavalida');
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.text('Insira um email válido.'), findsOneWidget);
    });

    testWidgets('Email válido e senha válida', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.enterText(find.byType(TextField).first, 'emailvalido@example.com');
      await tester.enterText(find.byType(TextField).last, 'senhavalida');
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.text('Insira um email válido.'), findsNothing);
    });

    testWidgets('Email e senha com caracteres especiais', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.enterText(find.byType(TextField).first, 'emailvalido@example.com');
      await tester.enterText(find.byType(TextField).last, 'senhavalida!@#\$%^&*');
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.text('Insira um email válido.'), findsNothing);
    });
  });
}
