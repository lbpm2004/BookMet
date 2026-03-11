import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DetalleLibroScreen extends StatefulWidget {
  final Map<String, dynamic> libro;
  final String docId;

  const DetalleLibroScreen({super.key, required this.libro, required this.docId});

  @override
  State<DetalleLibroScreen> createState() => _DetalleLibroScreenState();
}

class _DetalleLibroScreenState extends State<DetalleLibroScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  void _checkIfFavorite() async {
    if (user == null) return;
    
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user!.uid)
          .get();

      if (userDoc.exists) {
        var data = userDoc.data();
        
        List<dynamic> favoritos = (data != null && data.containsKey('favoritos')) 
            ? data['favoritos'] 
            : [];
            
        if (mounted) {
          setState(() {
            isFavorite = favoritos.contains(widget.docId);
          });
        }
      }
    } catch (e) {
      debugPrint('Error silencioso al cargar favoritos: $e');
      if (mounted) {
        setState(() {
          isFavorite = false;
        });
      }
    }
  }

  void _toggleFavorite() async {
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('usuarios').doc(user!.uid);

    setState(() {
      isFavorite = !isFavorite;
    });

    try {
      if (isFavorite) {
        await userRef.set({
          'favoritos': FieldValue.arrayUnion([widget.docId])
        }, SetOptions(merge: true));
        
        // MENSAJE DE AÑADIDO
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❤️ Añadido a tu lista de deseos'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        await userRef.set({
          'favoritos': FieldValue.arrayRemove([widget.docId])
        }, SetOptions(merge: true));

        // MENSAJE DE ELIMINADO
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('💔 Eliminado de tu lista de deseos'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isFavorite = !isFavorite;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar favoritos: $e')),
      );
    }
  }

  void _solicitarLibro(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Debes iniciar sesión.')));
      return;
    }

    final String? duenoId = widget.libro['usuarioId'];

    if (duenoId == null || duenoId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: El libro no tiene un dueño asignado.'))
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.orange)),
      );

      await FirebaseFirestore.instance.collection('solicitudes').add({
        'libroId': widget.docId,
        'tituloLibro': widget.libro['titulo'] ?? 'Libro sin título',
        'solicitanteId': user.uid,     
        'duenoId': duenoId,            
        'estadoSolicitud': 'PENDIENTE',
        'fecha': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('publicaciones').doc(widget.docId).update({
        'estado': 'RESERVADO',
      });

      if (!context.mounted) return;
      Navigator.pop(context); 
      Navigator.pop(context); 

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
    final bool esMio = widget.libro['usuarioId'] == currentUserId;
    final bool disponible = widget.libro['estado'] == 'DISPONIBLE';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Libro', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.orange[800],
        elevation: 1,
        // CORAZÓN ELIMINADO DE AQUÍ (ACTIONS)
      ),

      // =========================================================
      // NUEVA POSICIÓN DEL CORAZÓN: BOTÓN FLOTANTE
      // =========================================================
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleFavorite,
        backgroundColor: Colors.white,
        elevation: 4,
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? Colors.red : Colors.grey,
          size: 30,
        ),
      ),
      // =========================================================

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.libro['fotoUrl'] ?? 'https://via.placeholder.com/150',
                  height: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.book, size: 100, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.libro['titulo'] ?? 'Sin título',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _datoFila(Icons.person, 'Autor', widget.libro['autor']),
            _datoFila(Icons.school, 'Carrera', widget.libro['carrera']),
            _datoFila(Icons.menu_book, 'Materia', widget.libro['materia']),
            _datoFila(Icons.info_outline, 'Estado Físico', widget.libro['estadoFisico']?.toString().replaceAll('_', ' ').toUpperCase()),
            const SizedBox(height: 20),
            const Text('Descripción', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(widget.libro['descripcion'] ?? 'No hay descripción disponible.', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 80), // Espacio extra para que el FAB no tape el texto
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
            : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: disponible ? () => _solicitarLibro(context) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: disponible ? Colors.orange[800] : Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                  ),
                  child: Text(
                    disponible ? 'SOLICITAR INTERCAMBIO' : (widget.libro['estado'] == 'RESERVADO' ? 'RESERVADO' : 'NO DISPONIBLE'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _datoFila(IconData icono, String titulo, dynamic valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 20, color: Colors.orange[800]),
          const SizedBox(width: 12),
          Text('$titulo: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Expanded(child: Text(valor?.toString() ?? 'N/A', style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}