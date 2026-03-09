import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DetalleLibroScreen extends StatelessWidget {
  final Map<String, dynamic> libro;
  final String docId;

  const DetalleLibroScreen({super.key, required this.libro, required this.docId});

  void _solicitarLibro(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Debes iniciar sesión.')));
      return;
    }

    final String? duenoId = libro['usuarioId'];

    if (duenoId == null || duenoId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: El libro no tiene un dueño asignado.'))
      );
      return;
    }

    try {
      // Indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.orange)),
      );

      // 1. Guardar la solicitud
     await FirebaseFirestore.instance.collection('solicitudes').add({
  'libroId': docId,
  'tituloLibro': libro['titulo'] ?? 'Sin título',
  'fotoLibro': libro['fotoUrl'] ?? '',
  'solicitanteID': user.uid,        // ID del que está logueado (TÚ)
  'dueñoId': libro['usuarioId'],    // ID del que subió el libro (EL OTRO)
  'estadoSolicitud': 'PENDIENTE',
  'fechaSolicitud': FieldValue.serverTimestamp(),
});

      // 2. Cambiar estado del libro
      await FirebaseFirestore.instance.collection('publicaciones').doc(docId).update({
        'estado': 'NO DISPONIBLE',
      });

      if (!context.mounted) return;
      Navigator.pop(context); // Quitar carga

      // Diálogo de éxito
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('¡Solicitud enviada!'),
          content: const Text('Podrás ver el seguimiento en la sección "Mis Solicitudes".'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('OK', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );

    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Validamos el estado y la propiedad
    bool disponible = (libro['estado']?.toString().toUpperCase() == 'DISPONIBLE');
    bool esMio = libro['usuarioId'] == FirebaseAuth.instance.currentUser?.uid;
    
    // CORRECCIÓN DEL ERROR DE IMAGEN:
    // Verificamos si la URL existe y no está vacía antes de intentar cargarla
    String? urlImagen = libro['fotoUrl'];
    bool tieneImagenValida = urlImagen != null && urlImagen.isNotEmpty && urlImagen.startsWith('http');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Libro'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.orange[800],
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contenedor de imagen con protección contra nulos
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.grey[200],
              child: tieneImagenValida
                  ? Image.network(
                      urlImagen,
                      fit: BoxFit.contain,
                      // Si la URL falla al cargar (error 404, etc)
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100, color: Colors.grey),
                    )
                  : const Icon(Icons.book, size: 100, color: Colors.grey), // Imagen por defecto si es nulo
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    libro['titulo'] ?? 'Sin título',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Autor: ${libro['autor'] ?? 'Desconocido'}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const Divider(height: 30),
                  _datoFila(Icons.school, 'Carrera', libro['carrera']),
                  _datoFila(Icons.bookmark, 'Materia', libro['materia']),
                  _datoFila(Icons.star, 'Estado físico', libro['estadoFisico']),
                  const SizedBox(height: 20),
                  const Text('DESCRIPCIÓN', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(libro['descripcion'] ?? 'No hay descripción disponible.'),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black12))
        ),
        child: esMio
            ? const Text('Esta publicación es tuya', textAlign: TextAlign.center, style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))
            : ElevatedButton(
                onPressed: disponible ? () => _solicitarLibro(context) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[800],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                child: Text(
                  disponible ? 'SOLICITAR INTERCAMBIO' : 'NO DISPONIBLE',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
      ),
    );
  }

  Widget _datoFila(IconData icono, String titulo, dynamic valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icono, size: 18, color: Colors.orange[800]),
          const SizedBox(width: 8),
          Text('$titulo: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(valor?.toString() ?? 'N/A'),
        ],
      ),
    );
  }
}