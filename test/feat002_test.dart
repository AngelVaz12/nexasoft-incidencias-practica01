// FEAT-002: filtros combinables (texto + estado + prioridad).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexasoft_incidencias/main.dart';
import 'package:nexasoft_incidencias/services/gestor_incidencias.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  Future<GestorIncidencias> abrirApp() async {
    final g = GestorIncidencias();
    await g.iniciar();
    return g;
  }

  group('FEAT-002 logica de filtros', () {
    test('sin texto ni filtros devuelve todos los registros', () async {
      final g = await abrirApp();
      expect(g.consultar().length, 10);
    });

    test('filtro de estado Pendiente', () async {
      final g = await abrirApp();
      final r = g.consultar(estado: 'Pendiente');
      expect(r.length, 5);
      expect(r.every((x) => x.estado == 'Pendiente'), isTrue);
    });

    test('filtro de prioridad Alta', () async {
      final g = await abrirApp();
      await g.cambiarPrioridad('INC-101', 'Alta');
      await g.cambiarPrioridad('INC-106', 'Alta');
      expect(g.consultar(prioridad: 'Alta').map((x) => x.id), ['INC-101', 'INC-106']);
    });

    test('texto + estado + prioridad aplican todas las condiciones', () async {
      final g = await abrirApp();
      await g.cambiarPrioridad('INC-103', 'Alta'); // Pantalla azul..., Pendiente
      // INC-110 "Pantalla de inventario..." tambien es Pendiente pero queda en Media
      final r = g.consultar(texto: 'pantalla', estado: 'Pendiente', prioridad: 'Alta');
      expect(r.map((x) => x.id), ['INC-103']);
    });

    test('combinacion sin coincidencias devuelve lista vacia', () async {
      final g = await abrirApp();
      expect(g.consultar(texto: 'wifi', estado: 'Resuelta'), isEmpty);
    });

    test('los totales no dependen de la busqueda ni de los filtros', () async {
      final g = await abrirApp();
      g.consultar(texto: 'wifi', estado: 'En proceso', prioridad: 'Baja');
      expect(g.contar('Pendiente'), 5);
      expect(g.contar('En proceso'), 2);
      expect(g.contar('Resuelta'), 3);
    });
  });

  testWidgets('FEAT-002 interfaz: sin resultados muestra mensaje y Limpiar restablece', (tester) async {
    tester.view.physicalSize = const Size(900, 1100);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Future<void> esperar() async {
      for (var i = 0; i < 40; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
      }
      await tester.pump(const Duration(seconds: 1));
    }

    await tester.pumpWidget(const NexaSoftApp());
    await esperar();
    expect(find.text('10 de 10 registros'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'wifi');
    await tester.tap(find.byKey(const Key('filtro-estado')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resuelta').last);
    await tester.pumpAndSettle();
    expect(find.text('Ninguna incidencia cumple la búsqueda y los filtros.'), findsOneWidget);
    expect(find.text('0 de 10 registros'), findsOneWidget);

    await tester.tap(find.text('Limpiar filtros'));
    await tester.pumpAndSettle();
    expect(find.text('10 de 10 registros'), findsOneWidget);
    expect(find.text('wifi'), findsNothing);
  });
}
