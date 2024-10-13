import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drivers_app/authentication/login_screen.dart';
import 'package:drivers_app/methods/common_methods.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

void main() {
  group('signInUser', () {
    testWidgets('Email e senha válidos', (tester) async {
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
      expect(find.text('Faça o login de motorista'), findsOneWidget);
    });

    testWidgets('Email inválido (sem @)', (tester) async {
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

    testWidgets('Email inválido (com @, mas sem domínio)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.enterText(find.byType(TextField).first, 'email@invalido');
      await tester.enterText(find.byType(TextField).last, 'senhavalida');
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
      await tester.enterText(find.byType(TextField).last, 'senhavalida');
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.text('Insira um email válido.'), findsOneWidget);
    });

    testWidgets('Senha inválida (menos de 6 caracteres)', (tester) async {
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

    testWidgets('Senha inválida (mais de 20 caracteres)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.enterText(find.byType(TextField).first, 'emailvalido@example.com');
      await tester.enterText(find.byType(TextField).last, 'senhavalidamuitolong');
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.text("Sua senha deve ter no máximo 20 caracteres."), findsOneWidget);
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

    testWidgets('Email válido e senha vazia', (tester) async {
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

    testWidgets('Email válido e senha inválida', (tester) async {
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

    testWidgets('Conta bloqueada', (tester) async {
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
      expect(find.text('Sua conta foi bloqueada.'), findsNothing);
    });

    testWidgets('Conta não existe', (tester) async {
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
      expect(find.text('Sua conta de motorista não existe.'), findsNothing);
    });

    testWidgets('Erro de rede', (tester) async {
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
      expect(find.text('Erro de rede.'), findsNothing);
    });

    testWidgets('Erro de servidor', (tester) async {
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
      expect(find.text('Erro de servidor.'), findsNothing);
    });
  });
}
