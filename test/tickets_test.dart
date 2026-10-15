// Pruebas automatizadas de los tickets de la Practica 01.
// Reproducen BUG-001, BUG-002 y BUG-003 sobre la logica real de la app
// (GestorIncidencias + AlmacenLocal) usando un almacenamiento en memoria.
import 'package:flutter_test/flutter_test.dart';
import 'package:nexasoft_incidencias/services/gestor_incidencias.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Cada prueba empieza con el almacenamiento vacio (datos semilla del JSON).
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  // Simula "cerrar y volver a abrir la app": un gestor nuevo lee del almacenamiento.
  Future<GestorIncidencias> abrirApp() async {
    final g = GestorIncidencias();
    await g.iniciar();
    return g;
  }

  group('BUG-001 cambio de estado se pierde', () {
    test('el nuevo estado se conserva tras reiniciar', () async {
      final g = await abrirApp();
      expect(g.porId('INC-101')!.estado, 'Pendiente');
      await g.cambiarEstado('INC-101', 'Resuelta');
      expect(g.porId('INC-101')!.estado, 'Resuelta');
      final reabierta = await abrirApp();
      expect(reabierta.porId('INC-101')!.estado, 'Resuelta');
    });

    test('cambiar un registro no altera los demas', () async {
      final g = await abrirApp();
      final antes = {for (final x in g.incidencias) x.id: x.estado};
      await g.cambiarEstado('INC-101', 'Resuelta');
      final reabierta = await abrirApp();
      for (final x in reabierta.incidencias) {
        if (x.id != 'INC-101') expect(x.estado, antes[x.id], reason: x.id);
      }
    });

    test('una incidencia nueva sigue existiendo tras reiniciar', () async {
      final g = await abrirApp();
      await g.crear('Prueba de persistencia', 'Registro de prueba', 'Cliente ficticio', 'Software');
      final reabierta = await abrirApp();
      expect(reabierta.incidencias.length, 11);
      expect(reabierta.incidencias.any((x) => x.titulo == 'Prueba de persistencia'), isTrue);
    });
  });

  group('BUG-002 busqueda omite registros', () {
    test('"wifi" encuentra INC-102 (sin importar mayusculas)', () async {
      final g = await abrirApp();
      expect(g.buscar('wifi').map((x) => x.id), contains('INC-102'));
    });

    test('"WiFi" encuentra INC-102', () async {
      final g = await abrirApp();
      expect(g.buscar('WiFi').map((x) => x.id), contains('INC-102'));
    });

    test('"túnel" (solo en la descripcion) encuentra INC-106', () async {
      final g = await abrirApp();
      expect(g.buscar('túnel').map((x) => x.id), contains('INC-106'));
    });

    test('ignora espacios al inicio y al final', () async {
      final g = await abrirApp();
      expect(g.buscar('  WiFi  ').map((x) => x.id), contains('INC-102'));
    });

    test('sin texto muestra todos los registros', () async {
      final g = await abrirApp();
      expect(g.buscar('').length, 10);
    });
  });

  group('BUG-003 totales incorrectos', () {
    int pendientesEnLista(GestorIncidencias g) =>
        g.incidencias.where((x) => x.estado == 'Pendiente').length;

    test('Pendientes coincide con la lista al pasar Pendiente -> Resuelta', () async {
      final g = await abrirApp();
      expect(g.contar('Pendiente'), 5);
      await g.cambiarEstado('INC-103', 'Resuelta');
      expect(g.contar('Pendiente'), pendientesEnLista(g));
    });

    test('Pendientes coincide con la lista al pasar Resuelta -> Pendiente', () async {
      final g = await abrirApp();
      await g.cambiarEstado('INC-104', 'Pendiente');
      expect(g.contar('Pendiente'), pendientesEnLista(g));
    });
  });
}
