class UsuarioModel {
  final String id;
  final String nombre;
  final String carnet;
  final String email;

  UsuarioModel({
    required this.id,
    required this.nombre,
    required this.carnet,
    required this.email,
  });

  // Esto sirve para convertir los datos y guardarlos en la base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'carnet': carnet,
      'email': email,
    };
  }
}