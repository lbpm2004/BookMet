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

      // 1. Guardar la solicitud con los nombres EXACTOS que busca "Mis Solicitudes"
      await FirebaseFirestore.instance.collection('solicitudes').add({
        'libroId': docId,
        'tituloLibro': libro['titulo'] ?? 'Libro sin título',
        'solicitanteId': user.uid,     // <-- Nombre corregido
        'duenoId': duenoId,            // <-- Nombre corregido
        'estadoSolicitud': 'PENDIENTE',// <-- Nombre corregido
        'fecha': FieldValue.serverTimestamp(),
      });

      // 2. Cambiar el estado del libro a RESERVADO (¡Ya no a NO_DISPONIBLE!)
      await FirebaseFirestore.instance.collection('publicaciones').doc(docId).update({
        'estado': 'RESERVADO',
      });

      if (!context.mounted) return;
      Navigator.pop(context); // Cierra el diálogo de carga
      Navigator.pop(context); // Te regresa a la pantalla anterior (Catálogo)

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Solicitud enviada con éxito!'), 
          backgroundColor: Colors.green
        )
      );

    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al solicitar: $e'), backgroundColor: Colors.red)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final bool esMio = libro['usuarioId'] == currentUserId;
    final bool disponible = libro['estado'] == 'DISPONIBLE';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Libro', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.orange[800],
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  libro['fotoUrl'] ?? 'https://via.placeholder.com/150',
                  height: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.book, size: 100, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              libro['titulo'] ?? 'Sin título',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _datoFila(Icons.person, 'Autor', libro['autor']),
            _datoFila(Icons.school, 'Carrera', libro['carrera']),
            _datoFila(Icons.menu_book, 'Materia', libro['materia']),
            _datoFila(Icons.info_outline, 'Estado Físico', libro['estadoFisico']?.toString().replaceAll('_', ' ').toUpperCase()),
            const SizedBox(height: 20),
            const Text('Descripción', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(libro['descripcion'] ?? 'No hay descripción disponible.', style: const TextStyle(fontSize: 16)),
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
                  backgroundColor: disponible ? Colors.orange[800] : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                child: Text(
                  disponible ? 'SOLICITAR INTERCAMBIO' : (libro['estado'] == 'RESERVADO' ? 'RESERVADO' : 'NO DISPONIBLE'),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 18, color: Colors.orange[800]),
          const SizedBox(width: 8),
          Text('$titulo: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(valor?.toString() ?? 'N/A')),
        ],
      ),
    );
  }
}