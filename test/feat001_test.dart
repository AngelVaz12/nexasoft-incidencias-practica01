// FEAT-001: clasificacion por prioridad (Baja, Media, Alta).
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexasoft_incidencias/model/incidencia.dart';
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

  group('FEAT-001 prioridad', () {
    test('un registro antiguo sin prioridad se abre con Media', () {
      final r = Incidencia.desdeJson({
        'id': 'INC-OLD', 'titulo': 'Antiguo', 'descripcion': 'Sin prioridad',
        'cliente': 'Cliente ficticio', 'categoria': 'Redes', 'estado': 'Pendiente', 'fecha': '2026-01-01',
      });
      expect(r.prioridad, 'Media');
    });

    test('un valor no aprobado se reemplaza por Media', () {
      final r = Incidencia.desdeJson({'id': 'X', 'prioridad': 'Urgente'});
      expect(r.prioridad, 'Media');
    });

    test('los datos semilla (sin prioridad) cargan con Media sin fallar', () async {
      final g = await abrirApp();
      expect(g.incidencias.length, 10);
      expect(g.incidencias.every((x) => x.prioridad == 'Media'), isTrue);
    });

    test('registros antiguos ya guardados en el dispositivo se abren con Media', () async {
      final antiguos = [
        {'id': 'INC-900', 'titulo': 'Guardado antes', 'descripcion': 'd', 'cliente': 'c',
         'categoria': 'Software', 'estado': 'Resuelta', 'fecha': '2026-09-01'},
      ];
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.withData(
          {'nexasoft_incidencias_v1': jsonEncode(antiguos)});
      final g = await abrirApp();
      expect(g.porId('INC-900')!.prioridad, 'Media');
      expect(g.porId('INC-900')!.estado, 'Resuelta');
    });

    test('crear con prioridad Alta y conservarla tras reiniciar', () async {
      final g = await abrirApp();
      await g.crear('Servidor caido', 'Sin servicio', 'Cliente ficticio', 'Hardware', prioridad: 'Alta');
      final r = await abrirApp();
      final nuevo = r.incidencias.firstWhere((x) => x.titulo == 'Servidor caido');
      expect(nuevo.prioridad, 'Alta');
    });

    test('cambiar la prioridad desde el gestor y conservarla tras reiniciar', () async {
      final g = await abrirApp();
      await g.cambiarPrioridad('INC-103', 'Baja');
      final r = await abrirApp();
      expect(r.porId('INC-103')!.prioridad, 'Baja');
      expect(r.porId('INC-101')!.prioridad, 'Media');
    });

    test('rechaza valores distintos de los aprobados', () async {
      final g = await abrirApp();
      await expectLater(g.cambiarPrioridad('INC-101', 'Urgente'), throwsArgumentError);
      await expectLater(g.crear('t', 'd', 'c', 'Software', prioridad: 'Critica'), throwsArgumentError);
      expect(g.porId('INC-101')!.prioridad, 'Media');
      expect(g.incidencias.length, 10);
    });
  });
}
