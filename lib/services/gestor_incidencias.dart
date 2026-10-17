import '../data/almacen_local.dart';
import '../model/incidencia.dart';

class GestorIncidencias {
  final AlmacenLocal datos = AlmacenLocal();
  List<Incidencia> incidencias = [];

  Future<void> iniciar() async {
    incidencias = await datos.leer();
  }

  // BUG-002: la consulta se limpia (trim) y se compara sin distinguir
  // mayusculas/minusculas contra el titulo y la descripcion.
  List<Incidencia> buscar(String texto) {
    final consulta = texto.trim().toLowerCase();
    if (consulta.isEmpty) return List.of(incidencias);
    return incidencias
        .where((x) =>
            x.titulo.toLowerCase().contains(consulta) ||
            x.descripcion.toLowerCase().contains(consulta))
        .toList();
  }

  Incidencia? porId(String id) {
    for (var x in incidencias) {
      if (x.id == id) return x;
    }
    return null;
  }

  // BUG-003: todos los totales se calculan al momento sobre la lista completa
  // (no sobre la busqueda); antes Pendientes era un valor guardado aparte que
  // no se actualizaba al cambiar un estado.
  int contar(String estado) {
    return incidencias.where((x) => x.estado == estado).length;
  }

  Future<void> cambiarEstado(String id, String estado) async {
    for (var i = 0; i < incidencias.length; i++) {
      if (incidencias[i].id == id) {
        incidencias[i].estado = estado;
        break;
      }
    }
    // BUG-001: el cambio solo se hacia en memoria; se guarda en el almacenamiento local
    await datos.guardar(incidencias);
  }

  // FEAT-001: cambia la prioridad de una incidencia y la guarda.
  // Solo se aceptan los valores aprobados (Baja, Media, Alta).
  Future<void> cambiarPrioridad(String id, String prioridad) async {
    if (!prioridadesValidas.contains(prioridad)) {
      throw ArgumentError('Prioridad no permitida: $prioridad');
    }
    final item = porId(id);
    if (item == null) return;
    item.prioridad = prioridad;
    await datos.guardar(incidencias);
  }

  Future<void> crear(String titulo, String descripcion, String cliente,
      String categoria, {String prioridad = prioridadPorDefecto}) async {
    if (!prioridadesValidas.contains(prioridad)) {
      throw ArgumentError('Prioridad no permitida: $prioridad');
    }
    final nuevo = Incidencia(
      id: 'INC-${DateTime.now().microsecondsSinceEpoch}',
      titulo: titulo,
      descripcion: descripcion,
      cliente: cliente,
      categoria: categoria,
      estado: 'Pendiente',
      fecha: DateTime.now().toIso8601String().split('T').first,
      prioridad: prioridad,
    );
    incidencias.insert(0, nuevo);
    await datos.guardar(incidencias);
  }

  Future<void> reiniciarDemo() async {
    await datos.restaurarDatosDeEjemplo();
    await iniciar();
  }
}
