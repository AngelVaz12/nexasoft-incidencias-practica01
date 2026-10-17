// Capturas de FEAT-001 y FEAT-002 (archivo aparte: cada archivo corre aislado).
// Genera capturas reales de la interfaz (PantallaPrincipal / Detalle / Nueva)
// recorriendo los escenarios de los tickets. Ejecutar con:
//   flutter test test/evidencias_test.dart --update-goldens --dart-define=FASE=antes
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexasoft_incidencias/main.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const fase = String.fromEnvironment('FASE', defaultValue: 'antes');
// Solo genera capturas cuando se indica --dart-define=FASE=...; en la
// regresion normal (flutter test) se omite para no comparar contra capturas viejas.
const generarCapturas = bool.hasEnvironment('FASE');

Future<void> cargarFuente(String familia, List<String> rutas) async {
  final loader = FontLoader(familia);
  var alguna = false;
  for (final r in rutas) {
    final f = File(r);
    if (f.existsSync()) {
      loader.addFont(Future.value(ByteData.view(f.readAsBytesSync().buffer)));
      alguna = true;
    }
  }
  if (alguna) await loader.load();
}

void main() {
  setUpAll(() async {
    var root = Platform.environment['FLUTTER_ROOT'] ?? '';
    if (root.isEmpty) root = '${Platform.environment['USERPROFILE']}/development/flutter';
    final mf = '$root/bin/cache/artifacts/material_fonts';
    await cargarFuente('Roboto', [
      '$mf/Roboto-Regular.ttf', '$mf/Roboto-Medium.ttf', '$mf/Roboto-Bold.ttf',
      'C:/Windows/Fonts/segoeui.ttf',
    ]);
    await cargarFuente('MaterialIcons', ['$mf/MaterialIcons-Regular.otf']);
  });

  testWidgets('Evidencias FEAT-001 y FEAT-002 ($fase)', (tester) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    // Evita reutilizar el JSON en cache de un escenario anterior (se quedaria cargando)
    rootBundle.clear();
    tester.view.physicalSize = const Size(900, 1100);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Future<void> esperar() async {
      for (var i = 0; i < 40; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byType(CircularProgressIndicator).evaluate().isEmpty &&
            find.byType(LinearProgressIndicator).evaluate().isEmpty) {
          break;
        }
      }
      await tester.pump(const Duration(seconds: 1));
    }

    Future<void> foto(String nombre) async {
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('evidencias/$fase/$nombre.png'));
    }

    Future<void> abrirApp() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(NexaSoftApp(key: UniqueKey()));
      await esperar();
    }

    Future<void> elegir(Finder campo, String opcion) async {
      await tester.tap(campo);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text(opcion).last);
      await esperar();
    }

    await abrirApp();

    // FEAT-001: registrar una incidencia con prioridad Alta
    await tester.tap(find.text('Nueva incidencia'));
    await esperar();
    await tester.enterText(find.byType(TextFormField).at(0), 'Servidor de facturación sin respuesta');
    await tester.enterText(find.byType(TextFormField).at(1), 'Los cajeros no pueden emitir facturas desde la mañana.');
    await tester.enterText(find.byType(TextFormField).at(2), 'Cliente ficticio');
    await elegir(find.byKey(const ValueKey('campo-prioridad')), 'Alta');
    await foto('F01_nueva_con_prioridad_alta');
    await tester.tap(find.text('Registrar'));
    await esperar();
    await tester.pump(const Duration(seconds: 5));
    await foto('F02_lista_con_prioridad');

    // FEAT-001: cambiar la prioridad de INC-103 desde el detalle
    await tester.tap(find.text('Pantalla azul al iniciar equipo'));
    await esperar();
    await elegir(find.byType(DropdownButtonFormField<String>).last, 'Alta');
    await foto('F03_detalle_prioridad_alta');
    await tester.pageBack();
    await esperar();

    // Persistencia tras cerrar y abrir
    await abrirApp();
    await foto('F04_tras_reiniciar_prioridades');

    // FEAT-002: texto + estado + prioridad
    await tester.enterText(find.byType(TextField), 'pantalla');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await elegir(find.byKey(const Key('filtro-estado')), 'Pendiente');
    await elegir(find.byKey(const Key('filtro-prioridad')), 'Alta');
    await foto('F05_filtros_combinados');

    // FEAT-002: combinacion sin resultados
    await elegir(find.byKey(const Key('filtro-estado')), 'Resuelta');
    await foto('F06_sin_resultados');

    // FEAT-002: restablecer consulta y filtros
    await tester.tap(find.text('Limpiar filtros'));
    await esperar();
    await foto('F07_tras_limpiar');
  }, skip: !generarCapturas);
}
