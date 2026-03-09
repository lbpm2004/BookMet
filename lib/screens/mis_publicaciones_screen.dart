import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'publicar_screen.dart'; // Asegúrate de que el nombre del archivo sea exacto

class MisPublicacionesScreen extends StatelessWidget {
  const MisPublicacionesScreen({super.key});

  // Cambia el estado entre PAUSADO y DISPONIBLE
  Future<void> _alternarPausa(String docId, String estadoActual) async {
    // Si está pendiente de aprobación por el admin, mejor no permitir pausar aún
    if (estadoActual == 'Pendiente') return;

    String nuevoEstado = (estadoActual == 'PAUSADO') ? 'DISPONIBLE' : 'PAUSADO';
    await FirebaseFirestore.instance.collection('publicaciones').doc(docId).update({
      'estado': nuevoEstado,
    });
  }

  // Confirmación antes de borrar definitivamente
  void _confirmarEliminacion(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar material?'),
        content: const Text('Esta acción es irreversible y quitará el libro del catálogo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('publicaciones').doc(docId).delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Publicación eliminada')));
            }, 
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Mis Publicaciones', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.orange[800],
        elevation: 1,
      ),
      body: userId == null
          ? const Center(child: Text('Inicia sesión para ver tus publicaciones'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('publicaciones')
                  .where('usuarioId', isEqualTo: userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.orange));
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.library_books, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('Aún no tienes publicaciones', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var libro = doc.data() as Map<String, dynamic>;
                    String docId = doc.id;
                    String estado = libro['estado'] ?? 'Pendiente';

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange[50], 
                            borderRadius: BorderRadius.circular(8)
                          ),
                          child: const Icon(Icons.menu_book, color: Colors.orange),
                        ),
                        title: Text(
                          libro['titulo'] ?? 'Sin título', 
                          style: const TextStyle(fontWeight: FontWeight.bold)
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(libro['materia'] ?? 'General'),
                            const SizedBox(height: 4),
                            _buildBadgeEstado(estado),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PublicarScreen(
                                    libroAEditar: libro, 
                                    docId: docId
                                  )
                                ),
                              );
                            } else if (value == 'pause') {
                              _alternarPausa(docId, estado);
                            } else if (value == 'delete') {
                              _confirmarEliminacion(context, docId);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit', 
                              child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Editar')])
                            ),
                            if (estado != 'Pendiente')
                              PopupMenuItem(
                                value: 'pause', 
                                child: Row(children: [
                                  Icon(estado == 'PAUSADO' ? Icons.play_arrow : Icons.pause, size: 18), 
                                  SizedBox(width: 8), 
                                  Text(estado == 'PAUSADO' ? 'Reanudar' : 'Pausar')
                                ])
                              ),
                            const PopupMenuItem(
                              value: 'delete', 
                              child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text('Eliminar', style: TextStyle(color: Colors.red))])
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildBadgeEstado(String estado) {
    Color color;
    switch (estado.toUpperCase()) {
      case 'DISPONIBLE': color = Colors.green; break;
      case 'PAUSADO': color = Colors.grey; break;
      case 'NO DISPONIBLE': color = Colors.redAccent; break;
      default: color = Colors.orange; // Para Pendiente
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12)
      ),
      child: Text(
        estado, 
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)
      ),
    );
  }
}