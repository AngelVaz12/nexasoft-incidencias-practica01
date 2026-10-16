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

  testWidgets('Evidencias de la interfaz ($fase)', (tester) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
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

    // "Cerrar y volver a abrir": se destruye la app y se crea una nueva instancia.
    Future<void> abrirApp() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(NexaSoftApp(key: UniqueKey()));
      await esperar();
    }

    await abrirApp();
    await foto('01_lista_inicial');

    // BUG-001 / BUG-003: INC-101 de Pendiente a Resuelta
    await tester.tap(find.text('Impresora del almacén no responde'));
    await esperar();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Resuelta').last);
    await esperar();
    await foto('02_detalle_INC-101_resuelta');
    await tester.pageBack();
    await esperar();
    await foto('03_lista_tras_cambio');

    await abrirApp();
    await foto('04_tras_reiniciar');

    // BUG-002: busquedas
    await tester.enterText(find.byType(TextField), 'wifi');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await foto('05_busqueda_wifi');
    await tester.enterText(find.byType(TextField), 'WiFi');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await foto('06_busqueda_WiFi');
    await tester.enterText(find.byType(TextField), 'túnel');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await foto('07_busqueda_tunel');
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // BUG-003 (viceversa): INC-104 de Resuelta a Pendiente
    await tester.tap(find.text('No llegan correos de confirmación'));
    await esperar();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Pendiente').last);
    await esperar();
    await tester.pageBack();
    await esperar();
    await foto('07b_INC-104_a_pendiente');

    // Registro nuevo y segundo reinicio
    await tester.tap(find.text('Nueva incidencia'));
    await esperar();
    await tester.enterText(find.byType(TextFormField).at(0), 'Prueba de persistencia ($fase)');
    await tester.enterText(find.byType(TextFormField).at(1), 'Registro creado durante la verificación de BUG-001.');
    await tester.enterText(find.byType(TextFormField).at(2), 'Cliente ficticio');
    await tester.tap(find.text('Registrar'));
    await esperar();
    await tester.pump(const Duration(seconds: 5)); // deja que desaparezca el aviso
    await foto('08_nueva_registrada');

    await abrirApp();
    await foto('09_tras_segundo_reinicio');
  });
}
