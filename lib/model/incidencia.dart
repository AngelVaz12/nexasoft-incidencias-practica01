/// Prioridades aprobadas por el cliente (FEAT-001).
const List<String> prioridadesValidas = ['Baja', 'Media', 'Alta'];
const String prioridadPorDefecto = 'Media';

/// Devuelve una prioridad aprobada. Registros antiguos sin prioridad o con un
/// valor no aprobado se abren con 'Media' en lugar de fallar.
String normalizarPrioridad(Object? valor) {
  final texto = valor?.toString();
  return prioridadesValidas.contains(texto) ? texto! : prioridadPorDefecto;
}

class Incidencia {
  String id;
  String titulo;
  String descripcion;
  String cliente;
  String categoria;
  String estado;
  String fecha;
  String prioridad;

  Incidencia({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.cliente,
    required this.categoria,
    required this.estado,
    required this.fecha,
    String prioridad = prioridadPorDefecto,
  }) : prioridad = normalizarPrioridad(prioridad);

  factory Incidencia.desdeJson(Map<String, dynamic> m) {
    return Incidencia(
      id: m['id']?.toString() ?? '',
      titulo: m['titulo']?.toString() ?? '',
      descripcion: m['descripcion']?.toString() ?? '',
      cliente: m['cliente']?.toString() ?? '',
      categoria: m['categoria']?.toString() ?? 'Software',
      estado: m['estado']?.toString() ?? 'Pendiente',
      fecha: m['fecha']?.toString() ?? '',
      prioridad: normalizarPrioridad(m['prioridad']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'cliente': cliente,
      'categoria': categoria,
      'estado': estado,
      'fecha': fecha,
      'prioridad': prioridad,
    };
  }
}
