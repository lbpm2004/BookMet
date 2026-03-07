class UsuarioModel {
  final String id;
  final String nombre;
  final String cedula;
  final String email;
  final String fotoUrl;
  final String rol;

  UsuarioModel({
    required this.id,
    required this.nombre,
    required this.cedula,
    required this.email,
    required this.fotoUrl,
    required this.rol

  });

  // Esto sirve para convertir los datos y guardarlos en la base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'cedula': cedula,
      'email': email,
      'fotoUrl': fotoUrl,
      'rol': rol
    };
  }
}